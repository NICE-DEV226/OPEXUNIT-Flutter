import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../network/services/auth_api_service.dart';

/// Récupère le token FCM et l'envoie au backend (POST /api/auth/fcm-token).
/// À appeler après un login réussi (session déjà enregistrée).
/// Si Firebase n'est pas initialisé ou si la récupération échoue, l'erreur est ignorée.
Future<void> sendFcmTokenToBackend() async {
  try {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null && token.isNotEmpty) {
      await AuthApiService.setFcmToken(token);
      if (kDebugMode) {
        debugPrint('[FCM] Token envoyé au backend (${token.length} caractères)');
      }
    } else {
      if (kDebugMode) debugPrint('[FCM] Token vide ou null');
    }
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('[FCM] Impossible d\'envoyer le token: $e');
      debugPrint('[FCM] Stack: $st');
    }
    // Ne pas propager : l'app doit fonctionner même sans Firebase / FCM
  }
}
