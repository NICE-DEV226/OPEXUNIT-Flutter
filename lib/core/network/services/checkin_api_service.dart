import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../api_client.dart';
import '../../../features/agent/data/models/checkin_model.dart';

/// Service API check-ins. Base backend: /api/checkins
class CheckinApiService {
  CheckinApiService._();

  static const String _base = '/api/checkins';

  static Map<String, dynamic> _jsonBody(dynamic res) {
    final body = res.body as String?;
    if (body == null || body.isEmpty) return <String, dynamic>{};
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  /// POST /api/checkins — créer un check-in (auth requise).
  /// Body: type, latitude?, longitude?, photoKey?, patrolId?, notes?
  static Future<CheckinModel> create({
    required String type,
    double? latitude,
    double? longitude,
    String? photoKey,
    String? patrolId,
    String? notes,
  }) async {
    if (kDebugMode) debugPrint('[API Checkin] POST $_base type=$type');
    final body = <String, dynamic>{'type': type};
    if (latitude != null) body['latitude'] = latitude;
    if (longitude != null) body['longitude'] = longitude;
    if (photoKey != null && photoKey.isNotEmpty) body['photoKey'] = photoKey;
    if (patrolId != null && patrolId.isNotEmpty) body['patrolId'] = patrolId;
    if (notes != null && notes.isNotEmpty) body['notes'] = notes;

    final res = await ApiClient.post(_base, body: body);
    final data = _jsonBody(res);
    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception(data['message'] as String? ?? 'Erreur enregistrement check-in');
    }
    final result = data['data'];
    if (result is! Map<String, dynamic>) {
      throw Exception('Réponse serveur invalide');
    }
    return CheckinModel.fromJson(result);
  }

  /// GET /api/checkins/history — historique des check-ins de l'utilisateur connecté.
  static Future<List<CheckinModel>> getHistory() async {
    if (kDebugMode) debugPrint('[API Checkin] GET $_base/history');
    final res = await ApiClient.get('$_base/history');
    final data = _jsonBody(res);
    if (res.statusCode != 200) {
      throw Exception(data['message'] as String? ?? 'Erreur chargement historique');
    }
    final list = data['data'];
    if (list is! List) return [];
    return list
        .whereType<Map<String, dynamic>>()
        .map((e) => CheckinModel.fromJson(e))
        .toList();
  }
}
