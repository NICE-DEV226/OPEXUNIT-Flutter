import 'package:flutter/foundation.dart';

import '../network/services/alert_api_service.dart';
import '../network/services/gps_api_service.dart';
import '../network/services/intervention_api_service.dart';
import '../network/services/patrol_api_service.dart';
import '../network/services/report_api_service.dart';
import 'offline_storage.dart';

/// Résultat d'une synchronisation.
class SyncResult {
  const SyncResult({
    this.syncedCount = 0,
    this.failedCount = 0,
    this.lastError,
  });
  final int syncedCount;
  final int failedCount;
  final String? lastError;
}

/// Service de synchronisation : envoie les actions en file vers le backend.
class SyncService {
  SyncService._();

  /// Nombre d'actions en attente de synchronisation.
  static Future<int> getPendingCount() => OfflineStorage.getPendingCount();

  /// Lance la synchronisation des actions en file (à appeler en ligne).
  /// Retourne le nombre d'actions synchronisées et les erreurs éventuelles.
  static Future<SyncResult> syncPending() async {
    final list = await OfflineStorage.getPendingActions();
    if (list.isEmpty) {
      if (kDebugMode) debugPrint('[Sync] Rien à synchroniser');
      return const SyncResult();
    }
    if (kDebugMode) debugPrint('[Sync] ${list.length} action(s) en attente');
    int synced = 0;
    int failed = 0;
    String? lastError;
    for (final action in list) {
      final id = action['id'] as int?;
      if (id == null) continue;
      final type = action['action_type'] as String? ?? '';
      final payload = action['payload'] as Map<String, dynamic>? ?? {};
      try {
        await _processAction(type, payload);
        await OfflineStorage.markActionSynced(id);
        synced++;
      } catch (e) {
        failed++;
        lastError = e is Exception ? e.toString().replaceFirst('Exception: ', '') : '$e';
        await OfflineStorage.markActionError(id, lastError);
        if (kDebugMode) debugPrint('[Sync] ERREUR $type: $e');
        // On continue pour tenter les suivantes
      }
    }
    if (synced > 0) {
      await OfflineStorage.deleteSyncedActions();
    }
    if (kDebugMode) debugPrint('[Sync] Terminé: synced=$synced failed=$failed');
    return SyncResult(syncedCount: synced, failedCount: failed, lastError: lastError);
  }

  static Future<void> _processAction(String type, Map<String, dynamic> payload) async {
    switch (type) {
      case kActionPatrolStart:
        await PatrolApiService.startPatrol(
          payload['patrolId'] as String? ?? '',
          latitude: (payload['latitude'] as num?)?.toDouble(),
          longitude: (payload['longitude'] as num?)?.toDouble(),
        );
        break;
      case kActionPatrolCheckpoint:
        await PatrolApiService.recordCheckpoint(
          patrolId: payload['patrolId'] as String? ?? '',
          latitude: (payload['latitude'] as num?)?.toDouble() ?? 0,
          longitude: (payload['longitude'] as num?)?.toDouble() ?? 0,
          label: payload['label'] as String?,
        );
        break;
      case kActionPatrolGps:
        await GpsApiService.pushPosition(
          latitude: (payload['latitude'] as num?)?.toDouble() ?? 0,
          longitude: (payload['longitude'] as num?)?.toDouble() ?? 0,
          speed: (payload['speed'] as num?)?.toDouble(),
        );
        break;
      case kActionPatrolEnd: {
        final patrolId = payload['patrolId'] as String? ?? '';
        final observations = payload['observations'] as String?;
        final anomalies = payload['anomalies'] as List<dynamic>?;
        final photos = payload['photos'] as List<dynamic>?;
        final resume = payload['resume'] as String?;
        final degats = payload['degats'] as String?;
        final tempsReaction = payload['temps_reaction'] is int
            ? payload['temps_reaction'] as int
            : (payload['temps_reaction'] as num?)?.toInt();
        final actions = payload['actions'] as String?;
        final hasReport = observations != null ||
            (anomalies != null && anomalies.isNotEmpty) ||
            (photos != null && photos.isNotEmpty) ||
            (resume != null && resume.isNotEmpty) ||
            (degats != null && degats.isNotEmpty) ||
            tempsReaction != null ||
            (actions != null && actions.isNotEmpty);
        if (hasReport) {
          await ReportApiService.createPatrolReport(
            patrolId: patrolId,
            observations: observations,
            anomalies: anomalies?.map((e) => e.toString()).toList(),
            photos: photos?.map((e) => e.toString()).toList(),
            resume: resume,
            degats: degats,
            tempsReaction: tempsReaction,
            actions: actions,
          );
        }
        await PatrolApiService.endPatrol(patrolId);
        break;
      }
      case kActionInterventionClose: {
        final interventionId = payload['interventionId'] as String? ?? '';
        final agentId = payload['agentId'] as String?;
        final observations = payload['observations'] as String?;
        final anomalies = payload['anomalies'] as List<dynamic>?;
        final resume = payload['resume'] as String?;
        final degats = payload['degats'] as String?;
        final tempsReaction = payload['temps_reaction'] is int
            ? payload['temps_reaction'] as int
            : (payload['temps_reaction'] as num?)?.toInt();
        final actions = payload['actions'] as String?;
        final result = await ReportApiService.createInterventionReport(
          interventionId: interventionId,
          agentId: agentId,
          observations: observations,
          anomalies: anomalies?.map((e) => e.toString()).toList(),
          resume: resume,
          degats: degats,
          tempsReaction: tempsReaction,
          actions: actions,
        );
        await InterventionApiService.close(interventionId, reportId: result.id);
        break;
      }
      case kActionAlertTrigger:
        await AlertApiService.triggerAlert(
          type: payload['type'] as String? ?? 'panique',
          source: payload['source'] as String?,
          priorite: payload['priorite'] as String?,
          latitude: (payload['latitude'] as num?)?.toDouble(),
          longitude: (payload['longitude'] as num?)?.toDouble(),
          relatedPatrolId: payload['relatedPatrolId'] as String?,
          relatedInterventionId: payload['relatedInterventionId'] as String?,
        );
        break;
      default:
        if (kDebugMode) debugPrint('[Sync] Type inconnu: $type');
    }
  }
}
