import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Service d'assistance vocale pour la navigation vers le site.
/// Utilise le TTS pour annoncer la distance et des instructions.
class NavigationVoiceService {
  NavigationVoiceService._();

  static final FlutterTts _tts = FlutterTts();

  static bool _initialized = false;

  static Future<void> _ensureInit() async {
    if (_initialized) return;
    try {
      await _tts.setLanguage('fr-FR');
      await _tts.setSpeechRate(0.45);
      await _tts.setVolume(1.0);
      _initialized = true;
    } catch (e) {
      if (kDebugMode) debugPrint('[NavigationVoice] init error: $e');
    }
  }

  /// Annonce le début de la navigation vers le site [siteName] et la distance en mètres.
  static Future<void> speakStartNavigation(String siteName, double distanceMeters) async {
    await _ensureInit();
    final km = (distanceMeters / 1000).toStringAsFixed(1);
    final text = distanceMeters >= 1000
        ? 'Rendez-vous sur le site $siteName. Distance : $km kilomètres. Suivez l\'itinéraire sur la carte.'
        : 'Rendez-vous sur le site $siteName. Distance : ${distanceMeters.toInt()} mètres. Suivez l\'itinéraire sur la carte.';
    try {
      await _tts.speak(text);
    } catch (e) {
      if (kDebugMode) debugPrint('[NavigationVoice] speak error: $e');
    }
  }

  /// Annonce une instruction de navigation (ex. "Dans 100 mètres, tournez à gauche").
  static Future<void> speakInstruction(String text) async {
    await _ensureInit();
    if (text.isEmpty) return;
    try {
      await _tts.speak(text);
    } catch (_) {}
  }

  /// Annonce une mise à jour de distance (ex. toutes les 100 m).
  static Future<void> speakDistanceUpdate(double distanceMeters) async {
    await _ensureInit();
    final text = distanceMeters >= 1000
        ? 'Encore ${(distanceMeters / 1000).toStringAsFixed(1)} kilomètres.'
        : 'Encore ${distanceMeters.toInt()} mètres.';
    try {
      await _tts.speak(text);
    } catch (_) {}
  }

  /// Arrête la lecture en cours.
  static Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
