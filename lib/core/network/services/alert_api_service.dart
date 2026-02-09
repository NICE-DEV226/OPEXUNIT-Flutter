import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../api_client.dart';
import '../../../features/agent/data/models/alert_model.dart';

/// Service API alertes. Base backend: /api/alerts
class AlertApiService {
  AlertApiService._();

  static const String _base = '/api/alerts';

  static Map<String, dynamic> _jsonBody(dynamic res) {
    final body = res.body as String?;
    if (body == null || body.isEmpty) return <String, dynamic>{};
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  static Map<String, dynamic> _toMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return <String, dynamic>{};
  }

  /// POST /api/alerts/trigger — déclencher une alerte (Agent/Client).
  /// Body : type (panique|chute|client|zone|system), source?, priorite?, localisation?, related_patrol?, related_intervention?
  static Future<AlertModel> triggerAlert({
    required String type,
    String? source,
    String? priorite,
    double? latitude,
    double? longitude,
    String? relatedPatrolId,
    String? relatedInterventionId,
  }) async {
    if (kDebugMode) debugPrint('[API Alert] POST $_base/trigger type=$type');
    final body = <String, dynamic>{'type': type};
    if (source != null && source.isNotEmpty) body['source'] = source;
    if (priorite != null && priorite.isNotEmpty) body['priorite'] = priorite;
    if (latitude != null && longitude != null) {
      body['localisation'] = {
        'type': 'Point',
        'coordinates': [longitude, latitude],
      };
    }
    if (relatedPatrolId != null && relatedPatrolId.isNotEmpty) {
      body['related_patrol'] = relatedPatrolId;
    }
    if (relatedInterventionId != null && relatedInterventionId.isNotEmpty) {
      body['related_intervention'] = relatedInterventionId;
    }
    final res = await ApiClient.post('$_base/trigger', body: body);
    final data = _jsonBody(res);
    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception(data['message'] as String? ?? 'Erreur déclenchement alerte');
    }
    final alertData = data['data'] ?? data;
    return AlertModel.fromJson(_toMap(alertData));
  }

  /// GET /api/alerts/live — alertes ouvertes
  static Future<List<AlertModel>> getLive() async {
    if (kDebugMode) debugPrint('[API Alert] GET $_base/live');
    final res = await ApiClient.get('$_base/live');
    final body = _jsonBody(res);
    if (res.statusCode != 200) {
      throw Exception(body['message'] as String? ?? 'Erreur chargement alertes');
    }
    final list = body['data'];
    if (list is! List) return [];
    return list
        .whereType<Map<String, dynamic>>()
        .map((e) => AlertModel.fromJson(e))
        .toList();
  }

  /// GET /api/alerts/history — filtre type, statut, priorite, startDate, endDate
  static Future<List<AlertModel>> getHistory({
    String? type,
    String? statut,
    String? priorite,
    String? startDate,
    String? endDate,
  }) async {
    final query = <String, String>{};
    if (type != null && type.isNotEmpty) query['type'] = type;
    if (statut != null && statut.isNotEmpty) query['statut'] = statut;
    if (priorite != null && priorite.isNotEmpty) query['priorite'] = priorite;
    if (startDate != null && startDate.isNotEmpty) query['startDate'] = startDate;
    if (endDate != null && endDate.isNotEmpty) query['endDate'] = endDate;
    if (kDebugMode) debugPrint('[API Alert] GET $_base/history');
    final res = await ApiClient.get(
      '$_base/history',
      queryParams: query.isNotEmpty ? query : null,
    );
    final body = _jsonBody(res);
    if (res.statusCode != 200) {
      throw Exception(body['message'] as String? ?? 'Erreur historique alertes');
    }
    final list = body['data'];
    if (list is! List) return [];
    return list
        .whereType<Map<String, dynamic>>()
        .map((e) => AlertModel.fromJson(e))
        .toList();
  }

  /// GET /api/alerts/:id
  static Future<AlertModel?> getById(String id) async {
    if (kDebugMode) debugPrint('[API Alert] GET $_base/$id');
    final res = await ApiClient.get('$_base/$id');
    final body = _jsonBody(res);
    if (res.statusCode == 404) return null;
    if (res.statusCode != 200) {
      throw Exception(body['message'] as String? ?? 'Erreur chargement alerte');
    }
    final data = body['data'] ?? body;
    return AlertModel.fromJson(_toMap(data));
  }
}
