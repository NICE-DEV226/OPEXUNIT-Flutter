import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Récupère la position GPS actuelle (pour démarrage patrouille/intervention).
/// Retourne null si permission refusée, GPS désactivé ou timeout.
Future<Position?> getCurrentPositionOptional() async {
  try {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      if (kDebugMode) debugPrint('[Location] Service désactivé');
      return null;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (kDebugMode) debugPrint('[Location] Permission refusée');
      return null;
    }
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
    ).timeout(
      const Duration(seconds: 8),
      onTimeout: () => throw TimeoutException('GPS', const Duration(seconds: 8)),
    );
    if (kDebugMode) {
      debugPrint('[Location] Position: ${position.latitude}, ${position.longitude}');
    }
    return position;
  } on TimeoutException {
    if (kDebugMode) debugPrint('[Location] Timeout');
    return null;
  } catch (e) {
    if (kDebugMode) debugPrint('[Location] Erreur: $e');
    return null;
  }
}
