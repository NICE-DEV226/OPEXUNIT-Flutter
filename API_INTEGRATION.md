# Intégration API / Backend – OPEXUNIT Mobile

Ce document recense les points à brancher sur l’API et le backend une fois qu’ils sont disponibles.

---

## 1. Configuration réseau

- **`lib/core/network/api_config.dart`**
  - `baseUrl` : URL de base du backend (par défaut `https://api.opexunit.com`, modifiable via `--dart-define=API_BASE_URL=...`).
  - Préfixes prévus : `auth`, `agent`, `client`.

- **`lib/core/network/api_client.dart`**
  - Client HTTP central : `ApiClient.get()`, `ApiClient.post()`, `ApiClient.put()`, `ApiClient.delete()`.
  - Ajout automatique de l’en-tête `Authorization: Bearer <token>` si un token est présent dans `SessionStorage`.
  - Timeout : 30 s.

---

## 2. Authentification et session

- **`lib/core/auth/session_storage.dart`**
  - `load()` : appelé au démarrage dans `main.dart` (après `loadSavedLocale()`).
  - `saveSession(token, role)` : à appeler après un login API réussi (`role` = `'agent'` ou `'client'`).
  - `clear()` : appelé à chaque déconnexion (profil agent, drawer agent, profil client).
  - `getToken()` / `getRole()` : utilisés par `ApiClient` et éventuellement par le splash pour rediriger selon le rôle.

- **`lib/features/auth/presentation/screens/login_screen.dart`**
  - **À brancher** : remplacer le bloc actuel (navigation directe sans appel API) par :
    1. Appel à l’API login (ex. `POST /auth/login` avec identifiant + mot de passe + type agent/client).
    2. En cas de succès : `SessionStorage.saveSession(token: response.token, role: 'agent' | 'client')`.
    3. Navigation vers `AgentHomeScreen` ou `ClientHomeScreen` selon le rôle.

- **`lib/features/auth/presentation/screens/splash_screen.dart`**
  - **Optionnel** : après `SessionStorage.load()`, si `SessionStorage.isLoggedIn` est vrai, rediriger directement vers Agent ou Client home au lieu de l’écran de login.

---

## 3. Points d’intégration par fonctionnalité

| Fonctionnalité | Fichier | Action à brancher |
|----------------|---------|--------------------|
| **Login** | `login_screen.dart` | Appel `POST /auth/login`, puis `SessionStorage.saveSession()` et navigation. |
| **Mot de passe oublié** | `login_screen.dart` (`_showForgotPasswordDialog`) | Envoi de la demande à l’admin (email/téléphone saisi) vers l’API. |
| **SOS (alerte simple)** | `client_home_screen.dart` | Envoi API (GPS, timestamp) – TODO présent dans le code. |
| **Signaler un incident** | `client_detailed_alert_screen.dart` | Envoi API avec type, description, photo – TODO présent. |
| **Contacter la sécurité (message)** | `client_contact_security_screen.dart` | Envoi du message vers le centre – TODO présent. |
| **Numéro d’urgence** | `client_contact_security_screen.dart` | Remplacer `kEmergencyCenterPhoneNumber` par une valeur venant de la config ou de l’API (par site). |
| **Liste des sites client** | `client_status_screen.dart` | Remplacer les données mock `_sites` par un appel API (ex. `GET /client/sites`). |
| **Détail d’un site** | `client_site_detail_screen.dart` | Données du site (nom, adresse, statut, etc.) depuis l’API. |
| **Notifications client** | `client_notifications_screen.dart` | Liste des notifications (ex. `GET /client/notifications`). |
| **Journal client** | `client_journal_screen.dart` | Historique des événements depuis l’API. |
| **Conversations / messages agent** | `agent_conversation_screen.dart` | Messages et envoi branchés sur l’API. |
| **Paramètres / données utilisateur** | Divers écrans | Profil (nom, société, avatar), paramètres : chargement et mise à jour via API. |

---

## 4. Bonnes pratiques pour le branchement

1. **Ne pas modifier la structure des écrans** : garder les mêmes widgets et la même navigation ; remplacer uniquement les données mock ou les TODOs par des appels à `ApiClient` (ou à des services/repositories qui utilisent `ApiClient`).
2. **Gestion d’erreurs** : pour chaque appel API, gérer les erreurs (timeout, 401, 4xx/5xx) et afficher un message à l’utilisateur (SnackBar ou dialogue).
3. **Token expiré** : en cas de réponse 401, appeler `SessionStorage.clear()` et rediriger vers `LoginScreen`.
4. **URL de base** : en développement, utiliser `--dart-define=API_BASE_URL=https://dev-api.opexunit.com` (ou l’URL de votre backend) pour ne pas modifier le code.

---

## 5. État actuel

- **Prêt** : couche réseau (`ApiConfig`, `ApiClient`), session (`SessionStorage`), chargement de la session au démarrage, nettoyage à la déconnexion.
- **À brancher** : login, mot de passe oublié, SOS, incident, contact sécurité, sites, notifications, journal, messages agent, données utilisateur (profil/paramètres).

Une fois le backend disponible, il suffit d’implémenter les appels dans les fichiers indiqués et, si besoin, d’ajouter des modèles (DTO) pour parser les réponses JSON.
