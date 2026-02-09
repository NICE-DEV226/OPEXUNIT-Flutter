# Connexion téléphone → backend (délai dépassé)

Si l’app affiche **« Délai dépassé (http://192.168.1.70:5000) »**, le téléphone n’arrive pas à joindre le serveur. Vérifier les points suivants.

---

## 0. Android et HTTP (cleartext)

Si l’API est en **http** (pas https), Android bloque les requêtes par défaut.

Dans ce projet c’est déjà configuré dans `android/app/src/main/AndroidManifest.xml` :

```xml
<application
    ...
    android:usesCleartextTraffic="true">
```

Sans ça, les requêtes HTTP sont refusées (souvent sans message clair).

---

## 1. Backend doit écouter sur **0.0.0.0**

Le serveur doit accepter les connexions depuis le réseau (téléphone), pas seulement depuis `localhost`.

**Node.js / Express :**
```js
// À la place de : app.listen(5000, ...)
app.listen(5000, '0.0.0.0', () => {
  console.log('Backend écoute sur http://0.0.0.0:5000');
});
```

**Avec variable d’environnement (recommandé) :**
```js
const host = process.env.HOST || '0.0.0.0';
const port = process.env.PORT || 5000;
app.listen(port, host, () => {
  console.log(`Backend écoute sur http://${host}:${port}`);
});
```

Sans `'0.0.0.0'`, le serveur n’écoute souvent que sur `127.0.0.1` et le téléphone ne peut pas s’y connecter.

---

## 2. Pare-feu Windows : autoriser le port 5000

Le pare-feu peut bloquer les connexions entrantes sur le port 5000.

1. **Panneau de configuration** → **Pare-feu Windows** → **Paramètres avancés**
2. **Règles de trafic entrant** → **Nouvelle règle**
3. **Type** : Port → **TCP**, port **5000**
4. Autoriser la connexion, cocher **Réseau privé** (et Domaine si besoin)
5. Nom : par ex. « Node backend 5000 »

**En PowerShell (admin) :**
```powershell
New-NetFirewallRule -DisplayName "Node backend 5000" -Direction Inbound -LocalPort 5000 -Protocol TCP -Action Allow
```

---

## 3. Même réseau Wi‑Fi

- Le **PC** (où tourne le backend) et le **téléphone** doivent être sur le **même Wi‑Fi**.
- Vérifier l’IP du PC : `ipconfig` (carte Wi‑Fi, « Adresse IPv4 »).
- Dans l’app, l’URL doit être cette IP : `http://CETTE_IP:5000` (dans `api_config.dart` ou `--dart-define=API_BASE_URL=...`).

---

## Test rapide depuis le PC

Sur le PC, dans un navigateur ou avec PowerShell :
```powershell
Invoke-WebRequest -Uri "http://192.168.1.70:5000/api/auth/login" -Method POST -ContentType "application/json" -Body '{"matricule":"TEST","password":"test"}' -UseBasicParsing
```
Si ça répond, le backend écoute bien. Si le téléphone a encore « Délai dépassé », c’est en général le pare-feu ou un autre réseau Wi‑Fi.

---

## 4. POST /patrols/start : "Cannot read properties of undefined (reading 'id')"

Cette erreur vient du **backend** : dans `startPatrol`, le code fait `const agentId = req.user.id`. Si `req.user` est `undefined`, c’est que la route **n’est pas protégée par le middleware JWT** qui attache l’utilisateur à la requête.

**À faire côté backend :**

1. Vérifier que les routes patrouilles passent par le middleware d’authentification **avant** le contrôleur. Par exemple dans le fichier qui monte les routes (souvent `app.js` ou `routes/index.js`) :

```js
const authMiddleware = require('./middleware/auth'); // ou le nom de ton middleware JWT
const patrolRoutes = require('./routes/patrol.routes');

// Option A : protéger tout le router
app.use('/api/patrols', authMiddleware, patrolRoutes);

// Option B : si tu fais app.use('/api/patrols', patrolRoutes) sans auth,
// alors ajoute auth sur chaque route sensible, ou sur le router.
```

2. S’assurer que le middleware JWT, après vérification du token, fait bien :
   - `req.user = decodedPayload;` (ou l’objet user chargé depuis la BDD avec au moins `_id` / `id`).

L’app Flutter envoie déjà le token dans l’en-tête `Authorization: Bearer <token>` (via `ApiClient`). Dès que le backend attache `req.user` sur les routes protégées, `req.user.id` sera défini et l’erreur disparaîtra.

---

## 5. FCM token après login

Après un login réussi, l’app envoie le token FCM au backend via **POST /api/auth/fcm-token** (auth requise), body : `{ "fcmToken": "..." }`. Le backend doit enregistrer ce token pour l’utilisateur (ex. champ `fcmToken` sur le modèle User) afin d’envoyer des notifications push plus tard. Si Firebase n’est pas configuré côté app, l’envoi est ignoré sans bloquer le login.

---

## 6. GPS au démarrage patrouille / intervention

- **POST /api/patrols/start** : l’app envoie optionnellement `latitude` et `longitude` (position GPS au moment du démarrage). Le backend peut les ignorer ou les enregistrer (ex. pour traçabilité).
- **POST /api/interventions/:id/start** : idem, body peut contenir `latitude` et `longitude` en plus des champs existants.
