import 'package:flutter/foundation.dart';

import '../network/services/gps_api_service.dart';
import 'connectivity_service.dart';
import 'offline_storage.dart';

/// Service GPS avec support hors ligne : en file si pas de réseau.
class OfflineGpsService {
  OfflineGpsService._();

  static Future<bool> get _isOffline async {
    final online = await ConnectivityService.checkOnline();
    return !online;
  }

  /// Envoyer la position : API si en ligne, sinon en file (pas d'alerte retournée hors ligne).
  static Future<GpsPushResult> pushPosition({
    required double latitude,
    required double longitude,
    double? speed,
  }) async {
    if (await _isOffline) {
      await OfflineStorage.enqueueAction(kActionPatrolGps, {
        'latitude': latitude,
        'longitude': longitude,
        if (speed != null && speed >= 0) 'speed': speed,
      });
      if (kDebugMode) debugPrint('[OfflineGps] pushPosition en file');
      return const GpsPushResult(alert: null);
    }
    return GpsApiService.pushPosition(
      latitude: latitude,
      longitude: longitude,
      speed: speed,
    );
  }
}
