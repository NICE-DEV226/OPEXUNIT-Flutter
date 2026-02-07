import 'package:shared_preferences/shared_preferences.dart';

/// Stockage de la session utilisateur (token, rôle).
/// Utilisé après login et au démarrage (splash) pour restaurer la session.
/// À brancher : après succès API login, appeler [saveSession].
const String _kToken = 'session_token';
const String _kRole = 'session_role'; // 'agent' | 'client'

class SessionStorage {
  static String _token = '';
  static String _role = '';

  static String getToken() => _token;
  static String getRole() => _role;
  static bool get isLoggedIn => _token.isNotEmpty;

  /// Charge token et rôle depuis SharedPreferences (à appeler au démarrage).
  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(_kToken) ?? '';
      _role = prefs.getString(_kRole) ?? '';
    } catch (_) {
      _token = '';
      _role = '';
    }
  }

  /// Enregistre la session après un login réussi (à appeler par l'écran login après réponse API).
  static Future<void> saveSession({required String token, required String role}) async {
    _token = token;
    _role = role;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kToken, token);
      await prefs.setString(_kRole, role);
    } catch (_) {}
  }

  /// Vide la session (déconnexion).
  static Future<void> clear() async {
    _token = '';
    _role = '';
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kToken);
      await prefs.remove(_kRole);
    } catch (_) {}
  }
}
