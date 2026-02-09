import 'dart:convert';

import '../api_client.dart';
import '../../auth/session_storage.dart';
import '../../../features/auth/data/models/user_model.dart';
import '../../../features/auth/data/models/auth_response.dart';

/// Service API pour l'authentification (backend /api/auth).
/// Les paths sont relatifs à [ApiConfig.baseUrl] ; ApiClient ajoute la base.
class AuthApiService {
  AuthApiService._();

  /// Path relatif : /api/auth (sans baseUrl).
  static const String _base = '/api/auth';

  /// POST /api/auth/login — matricule + password.
  /// Retourne [AuthLoginResponse] ou lance en cas d'erreur.
  static Future<AuthLoginResponse> login({
    required String matricule,
    required String password,
  }) async {
    final res = await ApiClient.post(
      '$_base/login',
      body: {'matricule': matricule, 'password': password},
    );
    final body = _jsonBody(res);
    if (res.statusCode != 200) {
      final msg = body['message'] as String? ?? _statusMessage(res.statusCode);
      throw ApiException(msg, statusCode: res.statusCode, body: body);
    }
    try {
      return AuthLoginResponse.fromJson(body);
    } catch (e) {
      // Backend a répondu 200 mais le parsing a échoué (format différent)
      throw ApiException(
        'Réponse serveur invalide: ${e.toString().replaceFirst(RegExp(r'^Exception:?\s*'), '')}',
        body: body,
      );
    }
  }

  /// POST /api/auth/refresh-token — refreshToken dans le body.
  static Future<Map<String, dynamic>> refreshToken() async {
    final refreshToken = SessionStorage.getRefreshToken();
    if (refreshToken.isEmpty) {
      throw Exception('Aucun refresh token');
    }
    final res = await ApiClient.post(
      '$_base/refresh-token',
      body: {'refreshToken': refreshToken},
    );
    final body = _jsonBody(res);
    if (res.statusCode != 200) {
      throw Exception(body['message'] as String? ?? 'Session expirée');
    }
    return body['data'] as Map<String, dynamic>? ?? body;
  }

  /// POST /api/auth/complete-profile — auth requise.
  /// [photoProfil] (base64 ou URL), [ville] optionnels. Site et zone sont fixés par l'admin à la création.
  static Future<UserModel> completeProfile({
    String? photoProfil,
    String? ville,
  }) async {
    final body = <String, dynamic>{};
    if (photoProfil != null && photoProfil.isNotEmpty) body['photoProfil'] = photoProfil;
    if (ville != null && ville.isNotEmpty) body['ville'] = ville;

    final res = await ApiClient.post('$_base/complete-profile', body: body);
    final data = _jsonBody(res);
    if (res.statusCode != 200) {
      throw Exception(data['message'] as String? ?? 'Erreur lors de la mise à jour du profil');
    }
    final userData = data['data'] as Map<String, dynamic>? ?? data;
    return UserModel.fromJson(userData);
  }

  /// POST /api/auth/change-password — auth requise.
  static Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final res = await ApiClient.post(
      '$_base/change-password',
      body: {'oldPassword': oldPassword, 'newPassword': newPassword},
    );
    final data = _jsonBody(res);
    if (res.statusCode != 200) {
      throw Exception(data['message'] as String? ?? 'Erreur changement de mot de passe');
    }
  }

  /// POST /api/auth/fcm-token — auth requise.
  static Future<void> setFcmToken(String fcmToken) async {
    final res = await ApiClient.post('$_base/fcm-token', body: {'fcmToken': fcmToken});
    final data = _jsonBody(res);
    if (res.statusCode != 200) {
      throw Exception(data['message'] as String? ?? 'Erreur enregistrement FCM');
    }
  }

  /// POST /api/auth/forgot-password — email.
  static Future<void> forgotPassword(String email) async {
    final res = await ApiClient.post('$_base/forgot-password', body: {'email': email});
    final data = _jsonBody(res);
    if (res.statusCode != 200) {
      throw Exception(data['message'] as String? ?? 'Erreur demande de réinitialisation');
    }
  }

  /// POST /api/auth/reset-password/:token — newPassword.
  static Future<void> resetPassword({required String token, required String newPassword}) async {
    final res = await ApiClient.post(
      '$_base/reset-password/$token',
      body: {'newPassword': newPassword},
    );
    final data = _jsonBody(res);
    if (res.statusCode != 200) {
      throw Exception(data['message'] as String? ?? 'Erreur réinitialisation');
    }
  }

  /// POST /api/auth/logout — auth requise.
  static Future<void> logout() async {
    try {
      await ApiClient.post('$_base/logout');
    } catch (_) {
      // Ignorer erreur réseau ; on vide la session de toute façon
    }
  }

  static Map<String, dynamic> _jsonBody(dynamic res) {
    final body = res.body as String?;
    if (body == null || body.isEmpty) return <String, dynamic>{};
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  static String _statusMessage(int code) {
    if (code == 401) return 'Identifiants incorrects';
    if (code >= 500) return 'Erreur serveur, réessayez plus tard';
    if (code >= 400) return 'Requête invalide';
    return 'Connexion refusée';
  }
}

/// Exception API avec code HTTP et body pour debug.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.body});
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? body;
  @override
  String toString() => message;
}
