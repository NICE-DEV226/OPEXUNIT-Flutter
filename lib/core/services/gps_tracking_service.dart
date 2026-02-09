import 'dart:async';

import 'package:flutter/foundation.dart';

import '../auth/session_storage.dart';
import '../offline/offline_gps_service.dart';
import 'location_service.dart';

/// Envoi périodique de la position GPS au backend (POST /gps/push) après un check-in "prise de poste".
/// À démarrer après check-in START, arrêter après check-in END ou déconnexion.
class GpsTrackingService {
  GpsTrackingService._();

  static Timer? _timer;
  static const Duration _interval = Duration(seconds: 45);

  /// Démarre l'envoi périodique de la position (agent uniquement).
  /// À appeler après un check-in START réussi.
  static void start() {
    if (SessionStorage.getRole() != 'agent') return;
    stop();
    _timer = Timer.periodic(_interval, (_) => _push());
    _push(); // premier envoi immédiat
    if (kDebugMode) debugPrint('[GpsTracking] Started (every ${_interval.inSeconds}s)');
  }

  /// Arrête l'envoi périodique. À appeler après check-in END ou déconnexion.
  static void stop() {
    _timer?.cancel();
    _timer = null;
    if (kDebugMode) debugPrint('[GpsTracking] Stopped');
  }

  /// Reprend le suivi si l'agent était "en poste" (après redémarrage de l'app).
  /// À appeler au chargement de l'écran accueil agent.
  static void maybeResume() {
    if (SessionStorage.getRole() == 'agent' && SessionStorage.agentOnDuty) {
      start();
    }
  }

  static Future<void> _push() async {
    try {
      final position = await getCurrentPositionOptional();
      if (position == null) return;
      final speed = position.speed >= 0 ? position.speed : null;
      await OfflineGpsService.pushPosition(
        latitude: position.latitude,
        longitude: position.longitude,
        speed: speed,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[GpsTracking] push error: $e');
    }
  }
}
