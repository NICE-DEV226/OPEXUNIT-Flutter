import 'package:flutter/foundation.dart';

import '../../features/agent/data/models/alert_model.dart';
import '../network/services/alert_api_service.dart';
import 'connectivity_service.dart';
import 'offline_storage.dart';

/// Service alertes avec support hors ligne : en file si pas de réseau.
class OfflineAlertService {
  OfflineAlertService._();

  static Future<bool> get _isOffline async {
    final online = await ConnectivityService.checkOnline();
    return !online;
  }

  /// Déclencher une alerte : API si en ligne, sinon en file et retourne une alerte locale.
  static Future<AlertModel> triggerAlert({
    required String type,
    String? source,
    String? priorite,
    double? latitude,
    double? longitude,
    String? relatedPatrolId,
    String? relatedInterventionId,
  }) async {
    if (await _isOffline) {
      await OfflineStorage.enqueueAction(kActionAlertTrigger, {
        'type': type,
        if (source != null) 'source': source,
        if (priorite != null) 'priorite': priorite,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (relatedPatrolId != null) 'relatedPatrolId': relatedPatrolId,
        if (relatedInterventionId != null) 'relatedInterventionId': relatedInterventionId,
      });
      if (kDebugMode) debugPrint('[OfflineAlert] triggerAlert en file: $type');
      final coords = (latitude != null && longitude != null) ? [longitude, latitude] : <double>[];
      return AlertModel(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        type: AlertTypeExt.fromString(type),
        source: source,
        priorite: priorite != null ? AlertPrioriteExt.fromString(priorite) : AlertPriorite.medium,
        coordinates: coords,
        statut: AlertStatut.open,
        relatedPatrolId: relatedPatrolId,
        relatedInterventionId: relatedInterventionId,
        createdAt: DateTime.now(),
      );
    }
    return AlertApiService.triggerAlert(
      type: type,
      source: source,
      priorite: priorite,
      latitude: latitude,
      longitude: longitude,
      relatedPatrolId: relatedPatrolId,
      relatedInterventionId: relatedInterventionId,
    );
  }
}
