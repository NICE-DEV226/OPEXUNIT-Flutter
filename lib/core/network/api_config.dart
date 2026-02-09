/// Configuration de l'API backend.
/// - [baseUrl] : base sans slash final (ex. http://192.168.1.70:5000).
/// - Téléphone sur le même Wi‑Fi : utilisez l'IP du PC. Émulateur : http://10.0.2.2:5000
///
/// Si "Délai dépassé" :
/// 1. Backend doit écouter sur 0.0.0.0 (pas seulement 127.0.0.1) :
///    Node/Express : app.listen(5000, '0.0.0.0', () => console.log('Écoute sur 0.0.0.0:5000'));
/// 2. Pare-feu Windows : autoriser le port 5000 (entrant) pour l'app Node.
/// 3. Téléphone et PC sur le même réseau Wi‑Fi.
class ApiConfig {
  ApiConfig._();

  /// URL de base du backend (sans slash final).
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.1.65:5000',
  );

  /// Délai max pour une requête (secondes).
  static const Duration connectTimeout = Duration(seconds: 60);

  /// Préfixe des routes d'authentification (ex. /auth/login).
  static const String authPrefix = '/auth';

  /// Préfixe des routes agent (ex. /agent/...).
  static const String agentPrefix = '/agent';

  /// Préfixe des routes client (ex. /client/...).
  static const String clientPrefix = '/client';

  /// URL complète pour un fichier servi sous /uploads (images, vidéos).
  /// [path] : chemin renvoyé par l'API (ex. "/uploads/images/1739xxx_photo.jpg").
  /// Retourne baseUrl + path ; si [path] est déjà une URL absolue, la retourne telle quelle.
  /// Si [path] ressemble à des données base64 (ancien flux complete-profile), retourne '' pour éviter NetworkImage invalide.
  static String uploadsUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    // Ne pas construire d'URL pour du base64 (ex. /9j/4Q... JPEG, iVBOR... PNG, ou data:image)
    if (path.startsWith('/9j/') ||
        path.startsWith('9j/') ||
        path.startsWith('iVBOR') ||
        path.startsWith('data:') ||
        (path.length > 200 && !path.startsWith('/uploads') && !path.startsWith('http'))) {
      return '';
    }
    if (path.startsWith(RegExp(r'https?://'))) return path;
    final base = baseUrl.replaceAll(RegExp(r'/$'), '');
    return path.startsWith('/') ? '$base$path' : '$base/$path';
  }
}
