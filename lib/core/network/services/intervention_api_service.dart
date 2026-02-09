import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../api_client.dart';
import '../../../features/agent/data/models/intervention_model.dart';

/// Service API interventions. Base backend: /api/interventions
class InterventionApiService {
  InterventionApiService._();

  static const String _base = '/api/interventions';

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

  /// GET /api/interventions/live — interventions ouvertes (peut être réservé Superviseur)
  static Future<List<InterventionModel>> getLive() async {
    if (kDebugMode) debugPrint('[API Intervention] GET $_base/live');
    try {
      final res = await ApiClient.get('$_base/live');
      final body = _jsonBody(res);
      if (res.statusCode != 200) {
        if (kDebugMode) debugPrint('[API Intervention] live status=${res.statusCode}');
        throw Exception(body['message'] as String? ?? 'Erreur chargement interventions');
      }
      final data = body['data'];
      if (data is! List) return [];
      return data
          .whereType<Map<String, dynamic>>()
          .map((e) => InterventionModel.fromJson(e))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('[API Intervention] getLive: $e');
      rethrow;
    }
  }

  /// GET /api/interventions/history — filtre optionnel type, statut, site_id, startDate, endDate
  static Future<List<InterventionModel>> getHistory({
    String? type,
    String? statut,
    String? siteId,
    String? startDate,
    String? endDate,
  }) async {
    final query = <String, String>{};
    if (type != null && type.isNotEmpty) query['type'] = type;
    if (statut != null && statut.isNotEmpty) query['statut'] = statut;
    if (siteId != null && siteId.isNotEmpty) query['site_id'] = siteId;
    if (startDate != null && startDate.isNotEmpty) query['startDate'] = startDate;
    if (endDate != null && endDate.isNotEmpty) query['endDate'] = endDate;

    if (kDebugMode) debugPrint('[API Intervention] GET $_base/history');
    final res = await ApiClient.get(
      '$_base/history',
      queryParams: query.isNotEmpty ? query : null,
    );
    final body = _jsonBody(res);
    if (res.statusCode != 200) {
      if (kDebugMode) debugPrint('[API Intervention] history status=${res.statusCode}');
      throw Exception(body['message'] as String? ?? 'Erreur chargement historique');
    }
    final data = body['data'];
    if (data is! List) return [];
    final list = data
        .whereType<Map<String, dynamic>>()
        .map((e) => InterventionModel.fromJson(e))
        .toList();
    if (kDebugMode) debugPrint('[API Intervention] history: ${list.length} intervention(s)');
    return list;
  }

  /// GET /api/interventions/:id — détail d'une intervention
  static Future<InterventionModel?> getById(String id) async {
    if (kDebugMode) debugPrint('[API Intervention] GET $_base/$id');
    try {
      final res = await ApiClient.get('$_base/$id');
      final body = _jsonBody(res);
      if (res.statusCode == 404) return null;
      if (res.statusCode != 200) {
        throw Exception(body['message'] as String? ?? 'Erreur chargement intervention');
      }
      final data = body['data'] ?? body;
      return InterventionModel.fromJson(_toMap(data));
    } catch (e) {
      if (kDebugMode) debugPrint('[API Intervention] getById: $e');
      rethrow;
    }
  }

  /// POST /api/interventions/:id/start — démarrer une intervention (Agent).
  /// Optionnel : latitude, longitude (position GPS au démarrage).
  static Future<InterventionModel> start(
    String interventionId, {
    double? latitude,
    double? longitude,
  }) async {
    if (kDebugMode) debugPrint('[API Intervention] POST $_base/$interventionId/start');
    try {
      final payload = <String, dynamic>{};
      if (latitude != null && longitude != null) {
        payload['latitude'] = latitude;
        payload['longitude'] = longitude;
      }
      final res = await ApiClient.post('$_base/$interventionId/start', body: payload);
      final body = _jsonBody(res);
      if (res.statusCode != 200) {
        throw Exception(body['message'] as String? ?? 'Erreur démarrage intervention');
      }
      final data = body['data'] ?? body;
      return InterventionModel.fromJson(_toMap(data));
    } catch (e) {
      if (kDebugMode) debugPrint('[API Intervention] start: $e');
      rethrow;
    }
  }

  /// POST /api/interventions/:id/close — clôturer (Superviseur), body: { reportId?: string }
  static Future<InterventionModel> close(String interventionId, {String? reportId}) async {
    if (kDebugMode) debugPrint('[API Intervention] POST $_base/$interventionId/close');
    try {
      final body = reportId != null && reportId.isNotEmpty ? {'reportId': reportId} : <String, dynamic>{};
      final res = await ApiClient.post('$_base/$interventionId/close', body: body);
      final json = _jsonBody(res);
      if (res.statusCode != 200) {
        throw Exception(json['message'] as String? ?? 'Erreur clôture intervention');
      }
      final data = json['data'] ?? json;
      return InterventionModel.fromJson(_toMap(data));
    } catch (e) {
      if (kDebugMode) debugPrint('[API Intervention] close: $e');
      rethrow;
    }
  }
}
