import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../api_client.dart';

/// Réponse du push GPS : le backend peut retourner une alerte si sortie de zone.
class GpsPushResult {
  const GpsPushResult({this.alert});
  final Map<String, dynamic>? alert;
}

/// Service d'envoi de la position GPS (patrouille ou après check-in prise de poste).
/// Backend : POST /gps/push avec lat, lng, speed. Peut retourner une alerte (sortie de zone).
class GpsApiService {
  GpsApiService._();

  /// Backend BASE: /gps → POST /gps/push
  static const String _path = '/gps/push';

  static Map<String, dynamic> _jsonBody(dynamic res) {
    final body = res.body as String?;
    if (body == null || body.isEmpty) return <String, dynamic>{};
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  /// Envoie la position actuelle au backend (pendant une patrouille en cours).
  /// Retourne [GpsPushResult] avec alert si le backend a créé une alerte (ex. sortie de zone).
  static Future<GpsPushResult> pushPosition({
    required double latitude,
    required double longitude,
    double? speed,
  }) async {
    final body = <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
    };
    if (speed != null && speed >= 0) body['speed'] = speed;
    try {
      final res = await ApiClient.post(_path, body: body);
      final data = _jsonBody(res);
      if (kDebugMode && res.statusCode != 200) {
        debugPrint('[GPS] push status=${res.statusCode}');
      }
      final alert = data['alert'] as Map<String, dynamic>?;
      return GpsPushResult(alert: alert);
    } catch (e) {
      if (kDebugMode) debugPrint('[GPS] push error: $e');
      rethrow;
    }
  }
}
