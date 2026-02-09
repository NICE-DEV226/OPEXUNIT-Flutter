import 'package:flutter/foundation.dart';

import '../../../../core/auth/session_storage.dart';
import '../../../../core/network/services/agent_api_service.dart';
import '../../../../core/offline/connectivity_service.dart';
import '../../../../core/offline/offline_patrol_service.dart';
import '../../../../core/offline/offline_storage.dart';
import '../../../../core/services/location_service.dart';
import '../../data/models/agent_dashboard_model.dart';
import '../../data/models/patrol_model.dart';

/// Contrôleur dashboard agent : user, patrouille en cours, interventions, site, zone.
/// Une seule source de vérité pour "a-t-il une patrouille / une intervention ?"
class AgentDashboardController extends ChangeNotifier {
  static final AgentDashboardController instance = AgentDashboardController();

  AgentDashboardModel? _dashboard;
  bool _isLoading = false;
  String? _errorMessage;

  AgentDashboardModel? get dashboard => _dashboard;
  PatrolModel? get currentPatrol => _dashboard?.currentPatrol;
  bool get hasPatrol =>
      _dashboard != null &&
      _dashboard!.currentPatrol != null &&
      (_dashboard!.currentPatrol!.isPlanned || _dashboard!.currentPatrol!.isOngoing);
  bool get hasIntervention => _dashboard?.hasIntervention ?? false;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Charge les données agent (user, patrouille, interventions, site, zone, alertes).
  /// Si GET /api/agent/me n'existe pas encore, fallback : user en session + patrouille via GET /patrols/history.
  Future<void> loadDashboard() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    if (kDebugMode) {
      debugPrint('[Dashboard] Chargement...');
    }
    try {
      final (model, rawData) = await AgentApiService.getDashboard();
      _dashboard = model;
      if (model.user.id.isNotEmpty) {
        await OfflineStorage.cacheDashboard(model.user.id, rawData);
      }
      if (kDebugMode) {
        final p = _dashboard?.currentPatrol;
        final n = _dashboard?.interventions.length ?? 0;
        debugPrint('[Dashboard] OK (GET /api/agent/me)');
        debugPrint('  → Patrouille: ${p != null ? "id=${p.id} statut=${p.statut.label} site=${p.siteId}" : "aucune"}');
        debugPrint('  → Interventions: $n');
        debugPrint('  → Site: ${_dashboard?.siteName ?? _dashboard?.siteId ?? "-"}');
        debugPrint('  → Zone: ${_dashboard?.zoneName ?? _dashboard?.zoneId ?? "-"}');
        debugPrint('  → Alertes: ${_dashboard?.alertsLaunched ?? 0}');
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[Dashboard] ERREUR GET /api/agent/me: $e');
        debugPrint('[Dashboard] Stack: $st');
      }
      final user = SessionStorage.getUser();
      if (user != null) {
        final online = await ConnectivityService.checkOnline();
        if (!online) {
          final cached = await OfflineStorage.getCachedDashboard(user.id);
          if (cached != null) {
            _dashboard = AgentDashboardModel.fromJson(cached);
            _errorMessage = null;
            if (kDebugMode) {
              debugPrint('[Dashboard] Hors ligne: chargement depuis cache (patrouilles + interventions)');
            }
          } else {
            try {
              if (kDebugMode) debugPrint('[Dashboard] Pas de cache: fallback patrouille seul agent=${user.id}');
              final patrol = await OfflinePatrolService.getMyCurrentPatrol(user.id);
              _dashboard = AgentDashboardModel(
                user: user,
                currentPatrol: patrol,
                interventions: [],
              );
              _errorMessage = null;
            } catch (e2) {
              if (kDebugMode) debugPrint('[Dashboard] ERREUR Fallback: $e2');
              _dashboard = AgentDashboardModel(user: user, interventions: []);
              _errorMessage =
                  e2 is Exception ? e2.toString().replaceFirst('Exception: ', '') : null;
            }
          }
        } else {
          try {
            if (kDebugMode) debugPrint('[Dashboard] Fallback: chargement patrouille (cache/API) agent=${user.id}');
            final patrol = await OfflinePatrolService.getMyCurrentPatrol(user.id);
            _dashboard = AgentDashboardModel(
              user: user,
              currentPatrol: patrol,
              interventions: [],
            );
            _errorMessage = null;
          } catch (e2) {
            if (kDebugMode) debugPrint('[Dashboard] ERREUR Fallback: $e2');
            _dashboard = AgentDashboardModel(user: user, interventions: []);
            _errorMessage =
                e2 is Exception ? e2.toString().replaceFirst('Exception: ', '') : null;
          }
        }
      } else {
        _dashboard = null;
        _errorMessage = null;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Démarre une patrouille puis rafraîchit le dashboard.
  /// Récupère la position GPS si possible et l'envoie au backend.
  Future<PatrolModel?> startPatrol(String patrolId) async {
    if (kDebugMode) debugPrint('[Dashboard] startPatrol(patrolId=$patrolId)');
    try {
      final position = await getCurrentPositionOptional();
      final patrol = await OfflinePatrolService.startPatrol(
        patrolId,
        latitude: position?.latitude,
        longitude: position?.longitude,
      );
      if (kDebugMode) debugPrint('[Dashboard] startPatrol OK: id=${patrol.id} statut=${patrol.statut.label}');
      await loadDashboard();
      return patrol;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[Dashboard] ERREUR startPatrol: $e');
        debugPrint('[Dashboard] Stack: $st');
      }
      _errorMessage =
          e is Exception ? e.toString().replaceFirst('Exception: ', '') : 'Erreur';
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
