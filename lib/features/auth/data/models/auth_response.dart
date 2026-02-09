import 'user_model.dart';

/// Réponse du endpoint POST /api/auth/login.
class AuthLoginResponse {
  final String accessToken;
  final String refreshToken;
  final UserModel user;
  final bool profileComplete;

  const AuthLoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
    required this.profileComplete,
  });

  factory AuthLoginResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : json;
    final accessToken = data['accessToken'] as String? ?? data['access_token'] as String? ?? '';
    final refreshToken = data['refreshToken'] as String? ?? data['refresh_token'] as String? ?? '';
    final userMap = data['user'];
    final user = userMap is Map<String, dynamic>
        ? UserModel.fromJson(userMap)
        : UserModel.fromJson(<String, dynamic>{});
    // profileComplete vient du user renvoyé par l'API (compte créé par l'admin = false)
    return AuthLoginResponse(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: user,
      profileComplete: user.profileComplete,
    );
  }
}
