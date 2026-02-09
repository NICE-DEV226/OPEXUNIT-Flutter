import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/data/models/user_model.dart';

/// Durée de validité de la session après connexion (7 jours pour missions/patrouilles longues).
const Duration kSessionDuration = Duration(days: 7);

/// Stockage local de la session : tokens, utilisateur, profil complété, expiration.
/// Utilisé après login et au démarrage (splash) pour restaurer la session.
/// Une session expirée n'est pas effacée : l'utilisateur peut "reprendre hors ligne" depuis l'écran de login.
const String _kToken = 'session_token';
const String _kRefreshToken = 'session_refresh_token';
const String _kRole = 'session_role'; // 'agent' | 'client' (dérivé du rôle user)
const String _kUser = 'session_user';
const String _kProfileComplete = 'session_profile_complete';
const String _kSessionExpiresAt = 'session_expires_at'; // timestamp ms
const String _kAgentOnDuty = 'session_agent_on_duty'; // true après check-in START (prise de poste)

class SessionStorage {
  static String _token = '';
  static String _refreshToken = '';
  static String _role = '';
  static String _userJson = '';
  static bool _profileComplete = false;
  static int? _expiresAtMs;

  static String getToken() => _token;
  static String getRefreshToken() => _refreshToken;
  static String getRole() => _role;
  /// True après check-in "prise de poste" (START), false après "fin de service" (END) ou déconnexion.
  static bool get agentOnDuty => _agentOnDuty;
  static bool _agentOnDuty = false;
  /// True si un token existe et que la session n'a pas dépassé la durée configurée.
  static bool get isLoggedIn => _token.isNotEmpty && _isSessionNotExpired();
  /// True si une session (token + user) est enregistrée, même expirée (permet reprise hors ligne).
  static bool get hasStoredSession => _token.isNotEmpty && _userJson.isNotEmpty;
  static bool get isProfileComplete => _profileComplete;

  static bool _isSessionNotExpired() {
    if (_expiresAtMs == null) return true;
    return DateTime.now().millisecondsSinceEpoch < _expiresAtMs!;
  }

  /// Utilisateur courant (null si non chargé ou déconnecté).
  static UserModel? getUser() {
    if (_userJson.isEmpty) return null;
    try {
      final map = jsonDecode(_userJson) as Map<String, dynamic>;
      return UserModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  /// Charge la session depuis SharedPreferences (à appeler au démarrage).
  /// Une session expirée est conservée pour permettre "Reprendre la session (hors ligne)" à l'écran de login.
  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(_kToken) ?? '';
      _refreshToken = prefs.getString(_kRefreshToken) ?? '';
      _role = prefs.getString(_kRole) ?? '';
      _userJson = prefs.getString(_kUser) ?? '';
      _profileComplete = prefs.getBool(_kProfileComplete) ?? false;
      _expiresAtMs = prefs.getInt(_kSessionExpiresAt);
      _agentOnDuty = prefs.getBool(_kAgentOnDuty) ?? false;
      // On ne vide plus la session quand elle expire : l'utilisateur peut reprendre hors ligne
    } catch (_) {
      _token = '';
      _refreshToken = '';
      _role = '';
      _userJson = '';
      _profileComplete = false;
      _expiresAtMs = null;
      _agentOnDuty = false;
    }
  }

  static Future<void> _clearAll(SharedPreferences prefs) async {
    _token = '';
    _refreshToken = '';
    _role = '';
    _userJson = '';
    _profileComplete = false;
    _expiresAtMs = null;
    _agentOnDuty = false;
    await prefs.remove(_kToken);
    await prefs.remove(_kRefreshToken);
    await prefs.remove(_kRole);
    await prefs.remove(_kUser);
    await prefs.remove(_kProfileComplete);
    await prefs.remove(_kSessionExpiresAt);
    await prefs.remove(_kAgentOnDuty);
  }

  /// À appeler après check-in START (prise de poste) pour activer le suivi GPS continu.
  static Future<void> setAgentOnDuty(bool value) async {
    _agentOnDuty = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kAgentOnDuty, value);
    } catch (_) {}
  }

  /// Enregistre la session après un login réussi. La session expire après [kSessionDuration] (7 jours).
  static Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required UserModel user,
    required bool profileComplete,
  }) async {
    _token = accessToken;
    _refreshToken = refreshToken;
    _role = user.isClient ? 'client' : 'agent';
    _userJson = jsonEncode(user.toJson());
    _profileComplete = profileComplete;
    _expiresAtMs = DateTime.now().add(kSessionDuration).millisecondsSinceEpoch;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kToken, accessToken);
      await prefs.setString(_kRefreshToken, refreshToken);
      await prefs.setString(_kRole, _role);
      await prefs.setString(_kUser, _userJson);
      await prefs.setBool(_kProfileComplete, profileComplete);
      await prefs.setInt(_kSessionExpiresAt, _expiresAtMs!);
    } catch (_) {}
  }

  /// Met à jour le flag profil complété (après appel complete-profile).
  static Future<void> setProfileComplete(bool value) async {
    _profileComplete = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kProfileComplete, value);
    } catch (_) {}
  }

  /// Met à jour l'utilisateur en local (après complete-profile ou mise à jour profil).
  /// Synchronise aussi profileComplete avec user.profileComplete (source de vérité API).
  static Future<void> updateUser(UserModel user) async {
    _userJson = jsonEncode(user.toJson());
    _profileComplete = user.profileComplete;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kUser, _userJson);
      await prefs.setBool(_kProfileComplete, _profileComplete);
    } catch (_) {}
  }

  /// Vide la session (déconnexion ou expiration).
  static Future<void> clear() async {
    _token = '';
    _refreshToken = '';
    _role = '';
    _userJson = '';
    _profileComplete = false;
    _expiresAtMs = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await _clearAll(prefs);
    } catch (_) {}
  }
}
