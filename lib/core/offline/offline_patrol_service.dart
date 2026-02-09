import 'package:flutter/foundation.dart';

import '../../features/agent/data/models/patrol_model.dart';
import '../auth/session_storage.dart';
import '../network/services/patrol_api_service.dart';
import 'connectivity_service.dart';
import 'offline_storage.dart';

/// Clé pour la patrouille démarrée hors ligne (id de la patrouille).
const String kOfflineCurrentPatrolId = 'offline_current_patrol_id';

/// Service patrouille avec support hors ligne : en file si pas de réseau, cache en lecture.
class OfflinePatrolService {
  OfflinePatrolService._();

  static Future<bool> get _isOffline async {
    final online = await ConnectivityService.checkOnline();
    return !online;
  }

  /// GET history : API si en ligne, sinon cache.
  static Future<List<PatrolModel>> getHistory({
    String? agentId,
    String? statut,
    String? siteId,
    String? startDate,
    String? endDate,
  }) async {
    if (await _isOffline && agentId != null) {
      final cached = await OfflineStorage.getCachedPatrolList(agentId);
      if (cached != null && cached.isNotEmpty) {
        if (kDebugMode) debugPrint('[OfflinePatrol] getHistory from cache: ${cached.length}');
        return cached.map((e) => PatrolModel.fromJson(e)).toList();
      }
    }
    final list = await PatrolApiService.getHistory(
      agentId: agentId,
      statut: statut,
      siteId: siteId,
      startDate: startDate,
      endDate: endDate,
    );
    if (agentId != null && list.isNotEmpty) {
      final listJson = list.map((e) => _patrolToJson(e)).toList();
      await OfflineStorage.cachePatrolList(agentId, listJson);
    }
    return list;
  }

  static Map<String, dynamic> _patrolToJson(PatrolModel p) {
    return {
      'id': p.id,
      'type': p.type,
      'agents': p.agentIds,
      'site': p.siteId,
      'heure_debut': p.heureDebut?.toIso8601String(),
      'heure_fin': p.heureFin?.toIso8601String(),
      'points_controle': p.pointsControle.map((c) => {
        'coordinates': c.coordinates,
        'label': c.label,
        'status': c.status,
      }).toList(),
      'anomalies': p.anomalies,
      'statut': p.statut == PatrolStatus.planned ? 'PLANNED' : p.statut == PatrolStatus.ongoing ? 'ONGOING' : p.statut == PatrolStatus.completed ? 'COMPLETED' : 'CANCELLED',
      'created_at': p.createdAt?.toIso8601String(),
    };
  }

  static Map<String, dynamic> _minimalPatrolJson(String patrolId, Map<String, dynamic>? base) {
    final m = base != null ? Map<String, dynamic>.from(base) : <String, dynamic>{};
    m['id'] = patrolId;
    m['type'] = m['type'] ?? 'round';
    m['agents'] = m['agents'] ?? [];
    m['site'] ??= null;
    m['points_controle'] ??= [];
    m['anomalies'] ??= [];
    m['statut'] = 'ONGOING';
    m['heure_debut'] = DateTime.now().toIso8601String();
    return m;
  }

  /// Récupère la patrouille en cours ou planifiée (comme PatrolApiService.getMyCurrentPatrol).
  /// En priorité : patrouille démarrée hors ligne (offline id), puis liste cache/API.
  static Future<PatrolModel?> getMyCurrentPatrol(String agentId) async {
    final offlineId = await getOfflineCurrentPatrolId();
    if (offlineId != null) {
      final detail = await getDetails(offlineId);
      if (detail != null && (detail.isPlanned || detail.isOngoing)) return detail;
    }
    final list = await getHistory(agentId: agentId);
    for (final p in list) {
      if (p.isPlanned || p.isOngoing) return p;
    }
    return null;
  }

  /// GET details : API si en ligne, sinon cache.
  static Future<PatrolModel?> getDetails(String patrolId) async {
    if (await _isOffline) {
      final cached = await OfflineStorage.getCachedPatrolDetail(patrolId);
      if (cached != null) {
        if (kDebugMode) debugPrint('[OfflinePatrol] getDetails from cache: $patrolId');
        return PatrolModel.fromJson(cached);
      }
    }
    final p = await PatrolApiService.getDetails(patrolId);
    if (p != null) {
      await OfflineStorage.cachePatrolDetail(patrolId, _patrolToJson(p));
    }
    return p;
  }

  /// POST start : si hors ligne, en file et retourne un modèle "en cours" local.
  /// Met en cache le détail pour que getDetails / getMyCurrentPatrol retrouvent la patrouille.
  static Future<PatrolModel> startPatrol(
    String patrolId, {
    double? latitude,
    double? longitude,
  }) async {
    if (await _isOffline) {
      await OfflineStorage.enqueueAction(kActionPatrolStart, {
        'patrolId': patrolId,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      });
      await OfflineStorage.setOfflinePatrolState(kOfflineCurrentPatrolId, patrolId);
      if (kDebugMode) debugPrint('[OfflinePatrol] startPatrol en file: $patrolId');
      final detail = await OfflineStorage.getCachedPatrolDetail(patrolId);
      final minimal = _minimalPatrolJson(patrolId, detail);
      await OfflineStorage.cachePatrolDetail(patrolId, minimal);
      return PatrolModel.fromJson(minimal);
    }
    final patrol = await PatrolApiService.startPatrol(patrolId, latitude: latitude, longitude: longitude);
    if (patrol.siteId != null) {
      await OfflineStorage.cachePatrolDetail(patrolId, _patrolToJson(patrol));
    }
    return patrol;
  }

  /// POST checkpoint : si hors ligne, en file.
  static Future<PatrolModel> recordCheckpoint({
    required String patrolId,
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    if (await _isOffline) {
      await OfflineStorage.enqueueAction(kActionPatrolCheckpoint, {
        'patrolId': patrolId,
        'latitude': latitude,
        'longitude': longitude,
        if (label != null) 'label': label,
      });
      if (kDebugMode) debugPrint('[OfflinePatrol] recordCheckpoint en file');
      final cached = await OfflineStorage.getCachedPatrolDetail(patrolId);
      if (cached != null) return PatrolModel.fromJson(cached);
      return PatrolModel(id: patrolId, type: 'round', statut: PatrolStatus.ongoing);
    }
    return PatrolApiService.recordCheckpoint(
      patrolId: patrolId,
      latitude: latitude,
      longitude: longitude,
      label: label,
    );
  }

  /// POST end : si hors ligne, en file et retire l'état local "en cours".
  /// Met à jour le cache (détail + liste) pour que la patrouille terminée apparaisse dans l'historique.
  /// Tous les champs rapport sont en file et créés à la synchro.
  static Future<PatrolModel> endPatrol(
    String patrolId, {
    String? reportObservations,
    List<String>? reportAnomalies,
    List<String>? reportPhotos,
    String? reportResume,
    String? reportDegats,
    int? reportTempsReaction,
    String? reportActions,
  }) async {
    if (await _isOffline) {
      final payload = <String, dynamic>{'patrolId': patrolId};
      if (reportObservations != null && reportObservations.isNotEmpty) payload['observations'] = reportObservations;
      if (reportAnomalies != null && reportAnomalies.isNotEmpty) payload['anomalies'] = reportAnomalies;
      if (reportPhotos != null && reportPhotos.isNotEmpty) payload['photos'] = reportPhotos;
      if (reportResume != null && reportResume.isNotEmpty) payload['resume'] = reportResume;
      if (reportDegats != null && reportDegats.isNotEmpty) payload['degats'] = reportDegats;
      if (reportTempsReaction != null) payload['temps_reaction'] = reportTempsReaction;
      if (reportActions != null && reportActions.isNotEmpty) payload['actions'] = reportActions;
      await OfflineStorage.enqueueAction(kActionPatrolEnd, payload);
      await OfflineStorage.removeOfflinePatrolState(kOfflineCurrentPatrolId);
      if (kDebugMode) debugPrint('[OfflinePatrol] endPatrol en file: $patrolId');
      final cached = await OfflineStorage.getCachedPatrolDetail(patrolId);
      PatrolModel result;
      if (cached != null) {
        final m = Map<String, dynamic>.from(cached);
        m['statut'] = 'COMPLETED';
        m['heure_fin'] = DateTime.now().toIso8601String();
        result = PatrolModel.fromJson(m);
      } else {
        result = PatrolModel(id: patrolId, type: 'round', statut: PatrolStatus.completed);
      }
      await OfflineStorage.cachePatrolDetail(patrolId, _patrolToJson(result));
      final agentId = SessionStorage.getUser()?.id;
      if (agentId != null) {
        final list = await OfflineStorage.getCachedPatrolList(agentId) ?? [];
        final listJson = list.map((e) => Map<String, dynamic>.from(e)).toList();
        final idx = listJson.indexWhere((e) => (e['id'] as String? ?? '') == patrolId);
        final patrolJson = _patrolToJson(result);
        if (idx >= 0) {
          listJson[idx] = patrolJson;
        } else {
          listJson.add(patrolJson);
        }
        await OfflineStorage.cachePatrolList(agentId, listJson);
      }
      return result;
    }
    return PatrolApiService.endPatrol(patrolId);
  }

  /// Patrouille en cours démarrée hors ligne (id ou null).
  static Future<String?> getOfflineCurrentPatrolId() =>
      OfflineStorage.getOfflinePatrolState(kOfflineCurrentPatrolId);
}
