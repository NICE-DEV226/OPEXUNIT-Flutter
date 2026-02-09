import 'package:flutter/foundation.dart';

import '../../features/agent/data/models/site_model.dart';
import '../network/services/site_api_service.dart';
import 'connectivity_service.dart';
import 'offline_storage.dart';

/// Service sites client avec support hors ligne : cache la liste des sites du client.
class OfflineClientService {
  OfflineClientService._();

  /// Récupère les sites d'un client.
  /// - En ligne : appelle l'API puis met en cache.
  /// - Hors ligne : retourne le cache si disponible, sinon liste vide.
  static Future<List<SiteModel>> getClientSites(String clientId) async {
    if (clientId.isEmpty) return [];
    final online = await ConnectivityService.checkOnline();

    if (!online) {
      final cached = await OfflineStorage.getCachedClientSites(clientId);
      if (cached != null && cached.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('[OfflineClient] getClientSites from cache: ${cached.length}');
        }
        return cached.map((e) => SiteModel.fromJson(e)).toList();
      }
      // Hors ligne sans cache : on retourne simplement une liste vide.
      return [];
    }

    try {
      final sites = await SiteApiService.getAll(clientId: clientId);
      if (sites.isNotEmpty) {
        final listJson = sites.map(_siteToJson).toList();
        await OfflineStorage.cacheClientSites(clientId, listJson);
      }
      return sites;
    } catch (e) {
      // En cas d'erreur API, fallback éventuel sur le cache.
      final cached = await OfflineStorage.getCachedClientSites(clientId);
      if (cached != null && cached.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('[OfflineClient] fallback cache after error: ${cached.length}');
        }
        return cached.map((e) => SiteModel.fromJson(e)).toList();
      }
      rethrow;
    }
  }

  static Map<String, dynamic> _siteToJson(SiteModel s) {
    return {
      'id': s.id,
      'name': s.name,
      'description': s.description,
      'location': {
        'coordinates': s.coordinates,
      },
      'niveau_risque': s.niveauRisque,
      'created_at': s.createdAt?.toIso8601String(),
    };
  }
}

