import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kLocaleKey = 'app_locale';

/// Langue de l'application. Utilisé par [MaterialApp] et les écrans Profil / Paramètres.
final ValueNotifier<Locale> appLocaleNotifier = ValueNotifier<Locale>(const Locale('fr'));

/// Charge la langue enregistrée et l'applique.
Future<void> loadSavedLocale() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_kLocaleKey);
    if (code == 'en' || code == 'fr') {
      appLocaleNotifier.value = Locale(code!);
    }
  } catch (_) {}
}

/// Change la langue et la persiste (FR/EN).
Future<void> setAppLocale(String languageCode) async {
  if (languageCode != 'fr' && languageCode != 'en') return;
  appLocaleNotifier.value = Locale(languageCode);
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocaleKey, languageCode);
  } catch (_) {}
}

/// Retourne les libellés selon la locale.
String profileString(String fr, String en) {
  return appLocaleNotifier.value.languageCode == 'en' ? en : fr;
}
