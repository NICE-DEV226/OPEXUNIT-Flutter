/// Configuration de l'API backend.
/// Pour la production : utiliser des variables d'environnement ou des flavors
/// (ex. --dart-define=BASE_URL=https://api.opexunit.com).
class ApiConfig {
  ApiConfig._();

  /// URL de base du backend (sans slash final).
  /// À remplacer par l'URL réelle ou par un lecture depuis env.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.opexunit.com',
  );

  /// Délai max pour une requête (secondes).
  static const Duration connectTimeout = Duration(seconds: 30);

  /// Préfixe des routes d'authentification (ex. /auth/login).
  static const String authPrefix = '/auth';
  /// Préfixe des routes agent (ex. /agent/...).
  static const String agentPrefix = '/agent';
  /// Préfixe des routes client (ex. /client/...).
  static const String clientPrefix = '/client';
}
