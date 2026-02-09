import 'dart:convert';
import 'dart:io';

import '../api_client.dart';
import '../../../features/auth/data/models/user_model.dart';

/// API utilisateur : PUT /api/users/me, POST /api/upload/file.
class UserApiService {
  UserApiService._();

  static const String _usersBase = '/api/users';
  static const String _uploadPath = '/api/upload/file';

  /// PUT /api/users/me — met à jour le profil (champs partiels).
  /// Corps : uniquement les champs modifiés (nom, prenom, photoProfil, ville, email, telephone).
  /// Réponse : { success, message, data: user }.
  static Future<UserModel> updateMe(Map<String, dynamic> body) async {
    final res = await ApiClient.put('$_usersBase/me', body: body);
    final data = _jsonBody(res);
    if (_isHtmlResponse(res.body as String?)) {
      throw Exception(
        'Le serveur a renvoyé une page d\'erreur (${res.statusCode}). '
        'Vérifiez que la route PUT /api/users/me existe sur le backend.',
      );
    }
    if (res.statusCode != 200) {
      throw Exception(data['message'] as String? ?? 'Erreur lors de la mise à jour du profil (${res.statusCode})');
    }
    final userData = data['data'] as Map<String, dynamic>? ?? data;
    return UserModel.fromJson(userData);
  }

  /// POST /api/upload/file — envoie un fichier avec [target]=profile.
  /// Réponse profile : data.photoUrl (relatif), data.photoUrlFull (URL complète).
  /// Retourne le chemin relatif (photoUrl) à envoyer dans PUT /api/users/me.
  static Future<String> uploadFile(File file, {String target = 'profile'}) async {
    final streamed = await ApiClient.postMultipart(
      _uploadPath,
      file: file,
      fileField: 'file',
      fields: {'target': target},
    );
    final body = await streamed.stream.bytesToString();
    if (_isHtmlResponse(body)) {
      throw Exception(
        'Le serveur a renvoyé une page d\'erreur (${streamed.statusCode}). '
        'Vérifiez que la route POST /api/upload/file existe sur le backend.',
      );
    }
    if (streamed.statusCode != 200 && streamed.statusCode != 201) {
      final decoded = _safeDecode(body);
      throw Exception(decoded?['message'] as String? ?? 'Erreur upload (${streamed.statusCode})');
    }
    final decoded = _safeDecode(body) ?? {};
    final data = decoded['data'] as Map<String, dynamic>? ?? decoded;
    // Profile upload: photoUrl (relatif pour la BDD), photoUrlFull (affichage front)
    final path = (data['photoUrl'] ?? data['path'] ?? data['url'] ?? data['file'] ?? decoded['photoUrl'] ?? decoded['path'] ?? decoded['url']) as String?;
    if (path == null || path.isEmpty) {
      throw Exception('Réponse upload sans chemin (photoUrl/path/url)');
    }
    return path;
  }

  static bool _isHtmlResponse(String? body) {
    if (body == null || body.isEmpty) return false;
    final t = body.trim().toLowerCase();
    return t.startsWith('<!doctype') || t.startsWith('<html');
  }

  static Map<String, dynamic>? _safeDecode(String body) {
    if (body.isEmpty) return null;
    try {
      return jsonDecode(body) as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic> _jsonBody(dynamic res) {
    final body = res.body as String?;
    if (body == null || body.isEmpty) return <String, dynamic>{};
    if (_isHtmlResponse(body)) return <String, dynamic>{};
    try {
      return jsonDecode(body) as Map<String, dynamic>? ?? {};
    } catch (_) {
      return <String, dynamic>{};
    }
  }
}
