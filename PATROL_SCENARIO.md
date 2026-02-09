# Scénario patrouille – côté app Flutter

Ce qui est **spécifique à la patrouille** dans l’app (tout le reste = interventions, auth, profil, sync, etc.).

---

## Ce qui est “patrouille” dans l’app

| Élément | Rôle |
|--------|------|
| **PatrolApiService** | GET history, getDetails, startPatrol (avec lat/lng), recordCheckpoint, reportAnomaly, endPatrol (+ getItinerary quand le backend l’expose). |
| **PatrolModel, CheckpointModel** | Modèles de données patrouille / points de contrôle. |
| **PatrolController, AgentDashboardController** | État “patrouille en cours”, startPatrol (GPS au démarrage). |
| **AgentPatrolMapScreen** | Carte avant démarrage : site, checkpoints, itinéraire vers le site, instructions de navigation. |
| **AgentPatrolStartScreen** | Écran de démarrage (infos patrouille, bouton Démarrer). |
| **AgentPatrolInProgressScreen** | Patrouille en cours : carte, envoi périodique GPS (POST /gps/push), boutons rapport / terminer. |
| **AgentPatrolFinishScreen** | Fin de patrouille (POST end). |
| **AgentPatrolReportScreen** | Signalement d’anomalie pendant la patrouille. |
| **PatrolMapWidget** | Carte commune : site, checkpoints, itinéraire, position utilisateur, instructions. |
| **GpsApiService** | POST /gps/push (position pendant la patrouille). |
| **AlertApiService** | POST /api/alerts/trigger (déclencher une alerte, avec optionnel related_patrol). |
| **AgentAlertScreen** | Écran déclenchement alerte (type panique, source = type d’incident, GPS, lien patrouille si [patrolId]). |

**Hors patrouille** (première partie ou autres flux) : login, FCM, interventions (liste/détail/carte), profil, sync, historique, alertes, messages, etc.

---

## Alignement avec le scénario backend

1. **Planification** : côté Superviseur/Admin (backend + éventuel portail web). L’app agent ne crée pas la patrouille.
2. **Démarrage** : `PatrolApiService.startPatrol(patrolId, latitude, longitude)` → POST `/api/patrols/start` (GPS au démarrage).
3. **Envoi périodique GPS** : pendant l’écran “patrouille en cours”, l’app envoie la position via `GpsApiService.pushPosition(lat, lng, speed)` → POST `/gps/push` (ou `/api/gps/push` selon le backend).
4. **Sortie de zone / alertes** : gérées côté backend (checkZoneBoundary, création Alert, notifications). L’app reçoit éventuellement une réponse `alert` dans la réponse du push GPS.
5. **Itinéraire** : `PatrolApiService.getItinerary(patrolId)` → GET `/api/patrols/:id/itinerary` quand le backend l’implémente (patrol + gps[] + alerts[]).
6. **Fin** : `PatrolApiService.endPatrol(patrolId)` → POST `/api/patrols/end`.

---

## Routes backend utilisées par l’app (patrouille)

- `POST /api/patrols/start` (body: patrolId, optionnel lat/lng)
- `GET /api/patrols/:id`
- `GET /api/patrols/history`
- `POST /api/patrols/checkpoint`
- `POST /api/patrols/anomaly`
- `POST /api/patrols/end`
- `POST /api/gps/push` — position pendant la patrouille (body: latitude, longitude, speed optionnel). Si le backend monte la route à la racine, modifier `GpsApiService._path` en `gps/push`.
- `GET /api/patrols/:id/itinerary` — à ajouter côté backend, app prête à l’appeler
- `POST /api/alerts/trigger` — déclencher une alerte (body: type, source?, priorite?, localisation?, related_patrol?). Depuis « Patrouille en cours », bouton Alerte ouvre l’écran alerte avec `patrolId` pour lier l’alerte à la patrouille.
