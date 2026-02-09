import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../api_client.dart';
import '../../../features/agent/data/models/site_model.dart';
import '../../../features/auth/data/models/user_model.dart';

/// Service API sites : GET /api/sites, GET /api/sites/:id.
/// Permet de récupérer les coordonnées du site (location) pour centrer la carte patrouille.
class SiteApiService {
  SiteApiService._();

  static const String _base = '/api/sites';

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

  /// GET /api/sites/:id — détails d'un site (avec location.coordinates).
  static Future<SiteModel?> getById(String siteId) async {
    if (siteId.isEmpty) return null;
    if (kDebugMode) debugPrint('[API Site] GET $_base/$siteId');
    try {
      final res = await ApiClient.get('$_base/$siteId');
      final body = _jsonBody(res);
      if (kDebugMode) debugPrint('[API Site] getById status=${res.statusCode}');
      if (res.statusCode == 404) return null;
      if (res.statusCode != 200) {
        throw Exception(body['message'] as String? ?? 'Erreur chargement site');
      }
      final data = body['data'] ?? body;
      final site = SiteModel.fromJson(_toMap(data));
      if (kDebugMode && site.hasLocation) {
        debugPrint('[API Site] getById OK: id=${site.id} name=${site.name} coords=[${site.longitude}, ${site.latitude}]');
      }
      return site;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[API Site] ERREUR getById: $e');
        debugPrint('[API Site] Stack: $st');
      }
      rethrow;
    }
  }

  /// GET /api/sites — liste des sites (filtres optionnels).
  static Future<List<SiteModel>> getAll({
    String? niveauRisque,
    String? clientId,
  }) async {
    final query = <String, String>{};
    if (niveauRisque != null && niveauRisque.isNotEmpty) query['niveau_risque'] = niveauRisque;
    if (clientId != null && clientId.isNotEmpty) query['client_id'] = clientId;

    if (kDebugMode) debugPrint('[API Site] GET $_base');
    final res = await ApiClient.get(_base, queryParams: query.isNotEmpty ? query : null);
    final body = _jsonBody(res);
    if (res.statusCode != 200) {
      throw Exception(body['message'] as String? ?? 'Erreur chargement sites');
    }
    final data = body['data'];
    if (data is! List) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map((e) => SiteModel.fromJson(e))
        .toList();
  }

  /// GET /api/sites/:id/agents — agents affectés au site (si le backend expose cette route).
  /// Sinon retourne une liste vide.
  static Future<List<UserModel>> getSiteAgents(String siteId) async {
    if (siteId.isEmpty) return [];
    if (kDebugMode) debugPrint('[API Site] GET $_base/$siteId/agents');
    try {
      final res = await ApiClient.get('$_base/$siteId/agents');
      final body = _jsonBody(res);
      if (res.statusCode == 404 || res.statusCode != 200) return [];
      final data = body['data'];
      if (data is! List) return [];
      return data
          .whereType<Map<String, dynamic>>()
          .map((e) => UserModel.fromJson(e))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
