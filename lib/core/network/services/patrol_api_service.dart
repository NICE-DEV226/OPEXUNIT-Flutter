import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../api_client.dart';
import '../../../features/agent/data/models/patrol_itinerary_model.dart';
import '../../../features/agent/data/models/patrol_model.dart';

/// Service API patrouilles. Base backend: /api/patrols
class PatrolApiService {
  PatrolApiService._();

  static const String _base = '/api/patrols';

  static Map<String, dynamic> _jsonBody(dynamic res) {
    final body = res.body as String?;
    if (body == null || body.isEmpty) return <String, dynamic>{};
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  /// GET /api/patrols/history — filtre optionnel agent, statut, site, startDate, endDate
  static Future<List<PatrolModel>> getHistory({
    String? agentId,
    String? statut,
    String? siteId,
    String? startDate,
    String? endDate,
  }) async {
    final query = <String, String>{};
    if (agentId != null && agentId.isNotEmpty) query['agent'] = agentId;
    if (statut != null && statut.isNotEmpty) query['statut'] = statut;
    if (siteId != null && siteId.isNotEmpty) query['site'] = siteId;
    if (startDate != null && startDate.isNotEmpty) query['startDate'] = startDate;
    if (endDate != null && endDate.isNotEmpty) query['endDate'] = endDate;

    if (kDebugMode) debugPrint('[API Patrol] GET $_base/history agent=$agentId');
    final res = await ApiClient.get('$_base/history', queryParams: query.isNotEmpty ? query : null);
    final body = _jsonBody(res);
    if (kDebugMode) debugPrint('[API Patrol] history status=${res.statusCode}');
    if (res.statusCode != 200) {
      if (kDebugMode) debugPrint('[API Patrol] ERREUR history: ${body['message']}');
      throw Exception(body['message'] as String? ?? 'Erreur chargement historique');
    }
    final data = body['data'];
    if (data is! List) {
      if (kDebugMode) debugPrint('[API Patrol] history: data pas une liste');
      return [];
    }
    final list = data
        .whereType<Map<String, dynamic>>()
        .map((e) => PatrolModel.fromJson(e))
        .toList();
    if (kDebugMode) debugPrint('[API Patrol] history: ${list.length} patrouille(s)');
    return list;
  }

  static Map<String, dynamic> _toMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return <String, dynamic>{};
  }

  /// Récupère la patrouille en cours ou planifiée pour l'agent connecté.
  static Future<PatrolModel?> getMyCurrentPatrol(String agentId) async {
    final list = await getHistory(agentId: agentId);
    for (final p in list) {
      if (p.isPlanned || p.isOngoing) {
        if (kDebugMode) debugPrint('[API Patrol] getMyCurrentPatrol: trouvé id=${p.id} statut=${p.statut.label}');
        return p;
      }
    }
    if (kDebugMode) debugPrint('[API Patrol] getMyCurrentPatrol: aucune patrouille en cours/planifiée');
    return null;
  }

  /// GET /api/patrols/:id — détails d'une patrouille
  static Future<PatrolModel?> getDetails(String patrolId) async {
    if (kDebugMode) debugPrint('[API Patrol] GET $_base/$patrolId (détails)');
    try {
      final res = await ApiClient.get('$_base/$patrolId');
      final body = _jsonBody(res);
      if (kDebugMode) debugPrint('[API Patrol] getDetails status=${res.statusCode}');
      if (res.statusCode == 404) {
        if (kDebugMode) debugPrint('[API Patrol] getDetails: 404 non trouvé');
        return null;
      }
      if (res.statusCode != 200) {
        if (kDebugMode) debugPrint('[API Patrol] ERREUR getDetails: ${body['message']}');
        throw Exception(body['message'] as String? ?? 'Erreur chargement patrouille');
      }
      final data = body['data'] ?? body;
      final dataMap = _toMap(data);
      if (kDebugMode) {
        final rawPoints = dataMap['points_controle'] ?? dataMap['pointsControle'];
        debugPrint('[API Patrol] getDetails réponses brutes: points_controle=${rawPoints is List ? rawPoints.length : 0} éléments');
        if (rawPoints is List && rawPoints.isNotEmpty) {
          for (var i = 0; i < rawPoints.length; i++) {
            final p = rawPoints[i];
            if (p is Map) {
              final coords = (p['point'] is Map ? (p['point'] as Map)['coordinates'] : null) ?? p['coordinates'];
              debugPrint('[API Patrol]   point $i: coordinates=$coords label=${p['label'] ?? p['name']}');
            }
          }
        }
      }
      final patrol = PatrolModel.fromJson(dataMap);
      if (kDebugMode) {
        debugPrint('[API Patrol] getDetails OK: id=${patrol.id} statut=${patrol.statut.label} site=${patrol.siteId} points=${patrol.pointsControle.length}');
        for (var i = 0; i < patrol.pointsControle.length; i++) {
          final cp = patrol.pointsControle[i];
          debugPrint('[API Patrol]   checkpoint $i parsé: coords=${cp.coordinates} (lat,lng pour carte: ${cp.coordinates.length >= 2 ? "${cp.coordinates[1]}, ${cp.coordinates[0]}" : "invalide"}) label=${cp.label}');
        }
        if (patrol.pointsControle.isEmpty) {
          debugPrint('[API Patrol] → Aucun point de contrôle avec coordonnées valides: l\'itinéraire ne peut pas être tracé. Vérifiez que le backend envoie points_controle avec point.coordinates [lng, lat].');
        }
      }
      return patrol;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[API Patrol] ERREUR getDetails: $e');
        debugPrint('[API Patrol] Stack: $st');
      }
      rethrow;
    }
  }

  /// POST /api/patrols/start — démarrer une patrouille (agent).
  /// Backend attend body.patrolId et req.user.id (JWT middleware requis).
  /// Optionnel : latitude, longitude (position GPS au démarrage).
  static Future<PatrolModel> startPatrol(
    String patrolId, {
    double? latitude,
    double? longitude,
  }) async {
    if (kDebugMode) debugPrint('[API Patrol] POST $_base/start patrolId=$patrolId');
    try {
      final payload = <String, dynamic>{'patrolId': patrolId};
      if (latitude != null && longitude != null) {
        payload['latitude'] = latitude;
        payload['longitude'] = longitude;
      }
      final res = await ApiClient.post('$_base/start', body: payload);
      final body = _jsonBody(res);
      if (kDebugMode) debugPrint('[API Patrol] start status=${res.statusCode}');
      if (res.statusCode != 200) {
        if (kDebugMode) debugPrint('[API Patrol] ERREUR start: ${body['message']}');
        throw Exception(body['message'] as String? ?? 'Erreur démarrage patrouille');
      }
      final data = body['data'] ?? body;
      final patrol = PatrolModel.fromJson(_toMap(data));
      if (kDebugMode) debugPrint('[API Patrol] start OK: id=${patrol.id} statut=${patrol.statut.label}');
      return patrol;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[API Patrol] ERREUR startPatrol: $e');
        debugPrint('[API Patrol] Stack: $st');
      }
      rethrow;
    }
  }

  /// POST /api/patrols/checkpoint — enregistrer un checkpoint
  static Future<PatrolModel> recordCheckpoint({
    required String patrolId,
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    final body = <String, dynamic>{
      'patrolId': patrolId,
      'latitude': latitude,
      'longitude': longitude,
    };
    if (label != null) body['label'] = label;
    final res = await ApiClient.post('$_base/checkpoint', body: body);
    final data = _jsonBody(res);
    if (res.statusCode != 200) {
      throw Exception(data['message'] as String? ?? 'Erreur enregistrement checkpoint');
    }
    final patrolData = data['data'] ?? data;
    return PatrolModel.fromJson(_toMap(patrolData));
  }

  /// POST /api/patrols/anomaly — signaler une anomalie
  static Future<PatrolModel> reportAnomaly({
    required String patrolId,
    required String anomaly,
  }) async {
    if (kDebugMode) debugPrint('[API Patrol] POST $_base/anomaly patrolId=$patrolId');
    final res = await ApiClient.post('$_base/anomaly', body: {'patrolId': patrolId, 'anomaly': anomaly});
    final data = _jsonBody(res);
    if (res.statusCode != 200) {
      if (kDebugMode) debugPrint('[API Patrol] ERREUR anomaly: ${data['message']}');
      throw Exception(data['message'] as String? ?? 'Erreur signalement anomalie');
    }
    final patrolData = data['data'] ?? data;
    return PatrolModel.fromJson(_toMap(patrolData));
  }

  /// GET /api/patrols/:id/itinerary — itinéraire (patrol + trace GPS + alertes).
  /// À implémenter côté backend ; l'app est prête à consommer.
  static Future<PatrolItineraryModel> getItinerary(String patrolId) async {
    if (kDebugMode) debugPrint('[API Patrol] GET $_base/$patrolId/itinerary');
    final res = await ApiClient.get('$_base/$patrolId/itinerary');
    final body = _jsonBody(res);
    if (res.statusCode == 404) {
      throw Exception('Patrouille ou itinéraire introuvable');
    }
    if (res.statusCode != 200) {
      throw Exception(body['message'] as String? ?? 'Erreur chargement itinéraire');
    }
    final data = body['data'] ?? body;
    return PatrolItineraryModel.fromJson(_toMap(data));
  }

  /// POST /api/patrols/end — terminer une patrouille
  static Future<PatrolModel> endPatrol(String patrolId) async {
    if (kDebugMode) debugPrint('[API Patrol] POST $_base/end patrolId=$patrolId');
    try {
      final res = await ApiClient.post('$_base/end', body: {'patrolId': patrolId});
      final data = _jsonBody(res);
      if (kDebugMode) debugPrint('[API Patrol] end status=${res.statusCode}');
      if (res.statusCode != 200) {
        if (kDebugMode) debugPrint('[API Patrol] ERREUR end: ${data['message']}');
        throw Exception(data['message'] as String? ?? 'Erreur fin patrouille');
      }
      final patrolData = data['data'] ?? data;
      return PatrolModel.fromJson(_toMap(patrolData));
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[API Patrol] ERREUR endPatrol: $e');
        debugPrint('[API Patrol] Stack: $st');
      }
      rethrow;
    }
  }
}
