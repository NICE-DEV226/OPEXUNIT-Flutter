import 'package:flutter/foundation.dart';

import '../../../../core/auth/session_storage.dart';
import '../../data/models/patrol_model.dart';
import '../../../../core/offline/offline_patrol_service.dart';

/// Contrôleur patrouilles : ma patrouille actuelle, démarrage, etc.
/// Instance partagée pour rafraîchir l'accueil après fin de patrouille.
class PatrolController extends ChangeNotifier {
  static final PatrolController instance = PatrolController();

  PatrolModel? _currentPatrol;
  bool _isLoading = false;
  String? _errorMessage;

  PatrolModel? get currentPatrol => _currentPatrol;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Charge la patrouille en cours ou planifiée pour l'agent connecté.
  Future<void> loadMyPatrol() async {
    final user = SessionStorage.getUser();
    if (user == null) {
      _currentPatrol = null;
      notifyListeners();
      return;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _currentPatrol = await OfflinePatrolService.getMyCurrentPatrol(user.id);
    } catch (e) {
      _errorMessage = e is Exception ? e.toString().replaceFirst('Exception: ', '') : 'Erreur';
      _currentPatrol = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Démarre une patrouille (POST /patrols/start).
  Future<PatrolModel?> startPatrol(String patrolId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final patrol = await OfflinePatrolService.startPatrol(patrolId);
      _currentPatrol = patrol;
      _isLoading = false;
      notifyListeners();
      return patrol;
    } catch (e) {
      _errorMessage = e is Exception ? e.toString().replaceFirst('Exception: ', '') : 'Erreur';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
