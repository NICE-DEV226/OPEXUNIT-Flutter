import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Service de détection de la connectivité réseau.
/// Utilisé pour basculer en mode hors ligne (cache + file de sync).
class ConnectivityService {
  ConnectivityService._();

  static final Connectivity _connectivity = Connectivity();

  static bool _lastKnownOnline = true;

  /// True si on considère que l'appareil est en ligne (WiFi ou mobile).
  static bool get isOnline => _lastKnownOnline;

  /// Vérifie une fois la connectivité et met à jour [isOnline].
  /// En cas d'erreur du plugin (ex. MissingPluginException), on suppose en ligne pour ne pas bloquer l'app.
  static Future<bool> checkOnline() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _lastKnownOnline = _isResultConnected(result);
      if (kDebugMode) debugPrint('[Connectivity] check: $_lastKnownOnline ($result)');
      return _lastKnownOnline;
    } catch (e) {
      if (kDebugMode) debugPrint('[Connectivity] check error: $e');
      _lastKnownOnline = true;
      return true;
    }
  }

  static bool _isResultConnected(List<ConnectivityResult> result) {
    if (result.isEmpty) return false;
    return result.any((r) =>
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet);
  }

  /// Stream des changements de connectivité (pour sync auto quand on revient en ligne).
  /// En cas d'erreur du plugin, retourne un stream vide pour éviter les crashs.
  static Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map((list) {
      _lastKnownOnline = _isResultConnected(list);
      if (kDebugMode) debugPrint('[Connectivity] changed: $_lastKnownOnline');
      return _lastKnownOnline;
    }).handleError((e, st) {
      if (kDebugMode) debugPrint('[Connectivity] stream error: $e');
      _lastKnownOnline = true;
    });
  }
}
