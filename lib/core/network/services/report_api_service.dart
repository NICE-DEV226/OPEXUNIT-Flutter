import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../api_client.dart';

/// API rapports : POST /api/reports/patrol, POST /api/reports/intervention.
/// Schéma backend : kind, patrol_id | intervention_id, agent, observations, anomalies[], photos[], signature, resume, degats, temps_reaction, actions.
class ReportApiService {
  ReportApiService._();

  static const String _base = '/api/reports';

  static Map<String, dynamic> _jsonBody(dynamic res) {
    final body = res.body as String?;
    if (body == null || body.isEmpty) return <String, dynamic>{};
    try {
      return jsonDecode(body) as Map<String, dynamic>? ?? {};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  /// POST /api/reports/patrol — créer un rapport de patrouille (Agent).
  /// Body : patrol_id, agent?, observations?, anomalies?, photos?, resume?, degats?, temps_reaction?, actions?
  /// Réponse : { success, message, data: report } avec report._id.
  static Future<ReportCreatedResult> createPatrolReport({
    required String patrolId,
    String? agentId,
    String? observations,
    List<String>? anomalies,
    List<String>? photos,
    String? signature,
    String? resume,
    String? degats,
    int? tempsReaction,
    String? actions,
  }) async {
    final body = <String, dynamic>{
      'patrol_id': patrolId,
    };
    if (agentId != null && agentId.isNotEmpty) body['agent'] = agentId;
    if (observations != null && observations.isNotEmpty) body['observations'] = observations;
    if (anomalies != null && anomalies.isNotEmpty) body['anomalies'] = anomalies;
    if (photos != null && photos.isNotEmpty) body['photos'] = photos;
    if (signature != null && signature.isNotEmpty) body['signature'] = signature;
    if (resume != null && resume.isNotEmpty) body['resume'] = resume;
    if (degats != null && degats.isNotEmpty) body['degats'] = degats;
    if (tempsReaction != null) body['temps_reaction'] = tempsReaction;
    if (actions != null && actions.isNotEmpty) body['actions'] = actions;

    if (kDebugMode) debugPrint('[API Report] POST $_base/patrol patrolId=$patrolId');
    final res = await ApiClient.post('$_base/patrol', body: body);
    final data = _jsonBody(res);
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(data['message'] as String? ?? 'Erreur création rapport patrouille');
    }
    final reportData = data['data'] as Map<String, dynamic>? ?? data;
    final id = _oid(reportData['_id']) ?? _oid(reportData['id']) ?? '';
    return ReportCreatedResult(id: id, data: reportData);
  }

  /// POST /api/reports/intervention — créer un rapport d'intervention (Agent).
  /// Body : intervention_id, agent?, observations?, anomalies?, photos?, resume?, degats?, temps_reaction?, actions?
  static Future<ReportCreatedResult> createInterventionReport({
    required String interventionId,
    String? agentId,
    String? observations,
    List<String>? anomalies,
    List<String>? photos,
    String? signature,
    String? resume,
    String? degats,
    int? tempsReaction,
    String? actions,
  }) async {
    final body = <String, dynamic>{
      'intervention_id': interventionId,
    };
    if (agentId != null && agentId.isNotEmpty) body['agent'] = agentId;
    if (observations != null && observations.isNotEmpty) body['observations'] = observations;
    if (anomalies != null && anomalies.isNotEmpty) body['anomalies'] = anomalies;
    if (photos != null && photos.isNotEmpty) body['photos'] = photos;
    if (signature != null && signature.isNotEmpty) body['signature'] = signature;
    if (resume != null && resume.isNotEmpty) body['resume'] = resume;
    if (degats != null && degats.isNotEmpty) body['degats'] = degats;
    if (tempsReaction != null) body['temps_reaction'] = tempsReaction;
    if (actions != null && actions.isNotEmpty) body['actions'] = actions;

    if (kDebugMode) debugPrint('[API Report] POST $_base/intervention interventionId=$interventionId');
    final res = await ApiClient.post('$_base/intervention', body: body);
    final data = _jsonBody(res);
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(data['message'] as String? ?? 'Erreur création rapport intervention');
    }
    final reportData = data['data'] as Map<String, dynamic>? ?? data;
    final id = _oid(reportData['_id']) ?? _oid(reportData['id']) ?? '';
    return ReportCreatedResult(id: id, data: reportData);
  }

  static String? _oid(dynamic v) {
    if (v == null) return null;
    if (v is String) return v;
    if (v is Map) return (v['\$oid'] ?? v['id'] ?? v['_id'])?.toString();
    return v.toString();
  }

  /// GET /api/reports/patrol — liste des rapports de patrouille (filtres optionnels).
  /// Query: patrol_id, agent, startDate, endDate.
  static Future<List<ReportModel>> getPatrolReports({
    String? patrolId,
    String? agentId,
    String? startDate,
    String? endDate,
  }) async {
    final query = <String, String>{};
    if (patrolId != null && patrolId.isNotEmpty) query['patrol_id'] = patrolId;
    if (agentId != null && agentId.isNotEmpty) query['agent'] = agentId;
    if (startDate != null && startDate.isNotEmpty) query['startDate'] = startDate;
    if (endDate != null && endDate.isNotEmpty) query['endDate'] = endDate;
    final qs = query.isEmpty ? '' : '?${query.entries.map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}').join('&')}';
    if (kDebugMode) debugPrint('[API Report] GET $_base/patrol$qs');
    final res = await ApiClient.get('$_base/patrol$qs');
    final data = _jsonBody(res);
    if (res.statusCode != 200) {
      throw Exception(data['message'] as String? ?? 'Erreur chargement rapports patrouille');
    }
    final list = data['data'] as List<dynamic>? ?? data as List<dynamic>? ?? [];
    return list.map((e) => ReportModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// GET /api/reports/:id — récupérer un rapport par ID.
  static Future<ReportModel> getReportById(String id) async {
    if (kDebugMode) debugPrint('[API Report] GET $_base/$id');
    final res = await ApiClient.get('$_base/$id');
    final data = _jsonBody(res);
    if (res.statusCode != 200) {
      throw Exception(data['message'] as String? ?? 'Rapport introuvable');
    }
    final reportData = data['data'] as Map<String, dynamic>? ?? data;
    return ReportModel.fromJson(reportData);
  }
}

/// Modèle rapport (patrouille ou intervention).
class ReportModel {
  final String id;
  final String kind; // 'patrol' | 'intervention'
  final String? patrolId;
  final String? interventionId;
  final String? agentId;
  final String? observations;
  final List<String> anomalies;
  final List<String> photos;
  final String? signature;
  final String? resume;
  final String? degats;
  final int? tempsReaction;
  final String? actions;
  final DateTime? createdAt;

  ReportModel({
    required this.id,
    required this.kind,
    this.patrolId,
    this.interventionId,
    this.agentId,
    this.observations,
    this.anomalies = const [],
    this.photos = const [],
    this.signature,
    this.resume,
    this.degats,
    this.tempsReaction,
    this.actions,
    this.createdAt,
  });

  static String? _oid(dynamic v) {
    if (v == null) return null;
    if (v is String) return v;
    if (v is Map) return (v['\$oid'] ?? v['id'] ?? v['_id'])?.toString();
    return v.toString();
  }

  static DateTime? _date(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  static List<String> _stringList(dynamic v) {
    if (v == null) return [];
    if (v is List) return v.map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList();
    return [];
  }

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    final id = _oid(json['_id']) ?? _oid(json['id']) ?? '';
    return ReportModel(
      id: id,
      kind: json['kind'] as String? ?? 'patrol',
      patrolId: _oid(json['patrol_id']),
      interventionId: _oid(json['intervention_id']),
      agentId: _oid(json['agent']),
      observations: json['observations'] as String?,
      anomalies: _stringList(json['anomalies']),
      photos: _stringList(json['photos']),
      signature: json['signature'] as String?,
      resume: json['resume'] as String?,
      degats: json['degats'] as String?,
      tempsReaction: json['temps_reaction'] is int ? json['temps_reaction'] as int : (json['temps_reaction'] as num?)?.toInt(),
      actions: json['actions'] as String?,
      createdAt: _date(json['created_at']),
    );
  }
}

class ReportCreatedResult {
  final String id;
  final Map<String, dynamic> data;
  ReportCreatedResult({required this.id, required this.data});
}
