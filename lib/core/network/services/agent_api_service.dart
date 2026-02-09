import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../api_client.dart';
import '../../../features/agent/data/models/agent_dashboard_model.dart';

/// Service API agent : dashboard (user + patrouille + interventions + site/zone + alertes).
/// Correspond à un "getUserById" / "me" qui remonte tout le contexte agent.
class AgentApiService {
  AgentApiService._();

  /// GET /api/agent/me — infos complètes de l'agent connecté (user, patrouille, interventions, site, zone, alertes).
  /// Si le backend expose plutôt GET /api/users/me, adapter le path.
  static const String _mePath = '/api/agent/me';

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

  /// Récupère le dashboard agent : user, patrouille en cours, interventions, site, zone, alertes.
  /// Retourne le modèle et la map brute (pour cache hors ligne).
  static Future<(AgentDashboardModel, Map<String, dynamic>)> getDashboard() async {
    if (kDebugMode) debugPrint('[API Agent] GET $_mePath');
    try {
      final res = await ApiClient.get(_mePath);
      final body = _jsonBody(res);
      if (kDebugMode) {
        debugPrint('[API Agent] Réponse: status=${res.statusCode} body_length=${res.body.length}');
        if (res.statusCode != 200) {
          debugPrint('[API Agent] Erreur body: $body');
        }
      }
      if (res.statusCode != 200) {
        throw Exception(
          body['message'] as String? ?? 'Erreur chargement des données agent',
        );
      }
      final data = _toMap(body['data'] ?? body);
      final model = AgentDashboardModel.fromJson(data);
      return (model, data);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[API Agent] ERREUR getDashboard: $e');
        debugPrint('[API Agent] Stack: $st');
      }
      rethrow;
    }
  }
}
