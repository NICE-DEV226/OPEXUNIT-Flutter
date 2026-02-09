import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/auth/session_storage.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/network/services/auth_api_service.dart';
import '../../../../core/services/fcm_registration_service.dart';
import '../../../../core/services/gps_tracking_service.dart';
import '../../data/models/auth_response.dart';

/// Contrôleur d'authentification : login, logout, état chargement/erreur.
class AuthController extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Message d'erreur lisible pour l'utilisateur (réseau, timeout, API).
  static String _messageFromError(Object e) {
    if (e is ApiException) return e.message;
    final s = e.toString();
    final url = ApiConfig.baseUrl;
    if (s.contains('SocketException') ||
        s.contains('Connection refused') ||
        s.contains('Failed host lookup')) {
      return 'Serveur injoignable ($url). Même Wi‑Fi que le PC ? Émulateur ? Lancez avec : --dart-define=API_BASE_URL=http://10.0.2.2:5000';
    }
    if (e is TimeoutException) {
      return 'Délai dépassé ($url). Vérifiez la connexion et que le backend écoute sur 0.0.0.0.';
    }
    if (e is Exception) return s.replaceFirst('Exception: ', '');
    return 'Erreur de connexion';
  }

  /// Connexion avec matricule + mot de passe.
  /// En cas de succès : session enregistrée en local, [AuthLoginResponse] retourné.
  Future<AuthLoginResponse?> login({
    required String matricule,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await AuthApiService.login(
        matricule: matricule.trim(),
        password: password,
      );
      await SessionStorage.saveSession(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
        user: result.user,
        profileComplete: result.profileComplete,
      );
      // Envoyer le token FCM au backend (fire-and-forget, ne bloque pas le login)
      unawaited(sendFcmTokenToBackend());
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _messageFromError(e);
      notifyListeners();
      return null;
    }
  }

  /// Déconnexion : appel API puis vidage de la session locale.
  Future<void> logout() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      GpsTrackingService.stop();
      await AuthApiService.logout();
    } finally {
      await SessionStorage.clear();
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
