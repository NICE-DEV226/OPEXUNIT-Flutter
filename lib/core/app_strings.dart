import 'app_locale.dart';

/// Retourne la chaîne selon la langue courante.
String _s(String fr, String en) {
  return appLocaleNotifier.value.languageCode == 'en' ? en : fr;
}

/// Chaînes de l'application (FR/EN). Utiliser ces getters pour que le changement de langue s'applique partout.
class AppStrings {
  AppStrings._();

  // Navigation & accueil
  static String get home => _s('Accueil', 'Home');
  static String get homeTitle => _s('Acceuil', 'Home');
  static String get map => _s('Map', 'Map');
  static String get history => _s('Historique', 'History');
  static String get profile => _s('Profil', 'Profile');

  // Dashboard
  static String get roundTime => _s('Heure de ronde', 'Round time');
  static String get checkin => _s('Check-in', 'Check-in');
  static String get patrol => _s('Patrouille', 'Patrol');
  static String get scanQrNfc => _s('Scan QR/NFC', 'Scan QR/NFC');
  static String get recentActivities => _s('Activités Récentes', 'Recent activities');
  static String get synchro => _s('Synchro', 'Sync');
  static String get serviceActive => _s('Service activé', 'Service active');
  static String get alert => _s('Alerte', 'Alert');
  static String get message => _s('Message', 'Message');

  // Activités récentes
  static String get checkinValidated => _s('Check-in validé', 'Check-in validated');
  static String get siteAPoint => _s('Site A · Point de contrôle', 'Site A · Checkpoint');
  static String get patrolStart => _s('Début patrouille', 'Patrol start');
  static String get patrolInProgress => _s('Site A · Ronde en cours', 'Site A · Round in progress');
  static String get patrolCompleted => _s('Patrouille terminée', 'Patrol completed');
  static String get reportRecorded => _s('Rapport enregistré', 'Report recorded');
  static String get alertSent => _s('Alerte envoyée', 'Alert sent');
  static String get typeVehiclePending => _s('Type Véhicule · En attente', 'Type Vehicle · Pending');
  static String get messageReceived => _s('Message reçu', 'Message received');
  static String get controlCenter => _s('Centre de contrôle', 'Control center');

  // Messages
  static String get messages => _s('Messages', 'Messages');
  static String get newMessage => _s('Nouveau message', 'New message');
  static String get newMessageSubtitle => _s('Envoyer un message au centre ou à l\'équipe', 'Send a message to center or team');
  static String get recentConversations => _s('Conversations récentes', 'Recent conversations');
  static String get writeMessage => _s('Écrire un message...', 'Write a message...');

  // Alerte
  static String get emergencyAlert => _s('Alerte d\'urgence', 'Emergency alert');
  static String get incidentType => _s('Type d\'incident', 'Incident type');
  static String get observation => _s('Observation', 'Observation');
  static String get description => _s('Description', 'Description');
  static String get servicePhoto => _s('Photo de service', 'Service photo');
  static String get photoRequired => _s('Photo réquis', 'Photo required');
  static String get geolocation => _s('Géolocalisation', 'Geolocation');
  static String get gpsRequired => _s('Gps réquis', 'GPS required');
  static String get voiceNote => _s('Note vocale', 'Voice note');
  static String get voiceNoteOptional => _s('Enregistrement optionnel', 'Optional recording');
  static String get sendAlert => _s('Envoyer l\'alerte', 'Send alert');
  static String get alertSentSuccess => _s('Alerte envoyée', 'Alert sent');
  static String get alertSentConfirmationMessage => _s('Votre alerte a été transmise au centre de secours.', 'Your alert has been sent to the emergency center.');
  static String get incidentReportSuccessTitle => _s('Succès', 'Success');
  static String get incidentReportSuccessMessage => _s('Votre signalement d\'incident a bien été enregistré et transmis au centre de secours.', 'Your incident report has been recorded and sent to the emergency center.');

  // Historique
  static String get detail => _s('Détail', 'Detail');
  static String get location => _s('Lieu', 'Location');
  static String get start => _s('Début', 'Start');
  static String get end => _s('Fin', 'End');
  static String get dateTime => _s('Date et heure', 'Date and time');

  // Synchro
  static String get sync => _s('Synchro', 'Sync');
  static String get itemsPending => _s('éléments en attente', 'items pending');
  static String get lastSync => _s('Dernière synchro', 'Last sync');
  static String get categories => _s('CATÉGORIES', 'CATEGORIES');
  static String get selectAll => _s('Tout sélectionner', 'Select all');
  static String get deselectAll => _s('Tout désélectionner', 'Deselect all');
  static String get syncAll => _s('Tout synchroniser', 'Sync all');
  static String get syncSelection => _s('Synchroniser la sélection', 'Sync selection');
  static String get anomalyReports => _s('Rapports d\'anomalies', 'Anomaly reports');
  static String get criticalData => _s('Données critiques', 'Critical data');
  static String get checkins => _s('Check-ins', 'Check-ins');
  static String get validatedLocations => _s('Locations validées', 'Validated locations');
  static String get patrols => _s('Patrouilles', 'Patrols');
  static String get movementLogs => _s('Logs de mouvement', 'Movement logs');
  static String get syncDisclaimer => _s('Les éléments non cochés resteront stockés localement sur votre appareil jusqu\'à la prochaine synchronisation.', 'Unchecked items will remain stored locally until next sync.');
  static String get lastSyncToday => _s('Dernière synchro : Aujourd\'hui à 08:45', 'Last sync: Today at 08:45');
  static String get selectAllLabel => _s('Tout sélectionner', 'Select all');
  static String get deselectAllLabel => _s('Tout désélectionner', 'Deselect all');
  static String get syncAllLabel => _s('Tout synchroniser', 'Sync all');
  static String get syncSelectionLabel => _s('Synchroniser la sélection', 'Sync selection');
  static String get syncCompleteTitle => _s('Synchronisation terminée', 'Sync complete');
  static String get syncPartialTitle => _s('Synchro partielle', 'Partial sync');
  static String syncCompleteMessage(int n) => _s('Tous les $n éléments ont été synchronisés.', 'All $n items have been synced.');
  static String syncPartialMessage(int selected, int total) => _s('$selected élément(s) synchronisé(s) sur $total.', '$selected item(s) synced out of $total.');

  // Check-in
  static String get serviceStart => _s('Prise de service', 'Service start');
  static String get checkinStart => _s('Démarrage check-in', 'Check-in start');
  static String get checkinInstructions => _s('Veuillez compléter les informations ci-dessous et confirmer', 'Please complete the information below and confirm');
  static String get form => _s('Formulaire', 'Form');
  static String get photoDeService => _s('Photo de service', 'Service photo');
  static String get positionPhotoRecorded => _s('Votre position et votre photo sont enregistrées dans le rapport de service OPEXUNIT', 'Your position and photo are recorded in the OPEXUNIT service report');
  static String get validate => _s('Valider', 'Validate');
  static String get checkinRecorded => _s('Check-in enregistré', 'Check-in recorded');
  static String get photoRequiredStub => _s('Photo de service : prise de photo à brancher (caméra)', 'Service photo: camera to be connected');
  static String get geolocationStub => _s('Géolocalisation : position à brancher (GPS)', 'Geolocation: GPS to be connected');

  // Patrouille
  static String get finishPatrol => _s('Terminer la patrouille', 'Finish patrol');
  static String get finishPatrolSubtitle => _s('Pour terminer la patrouille faites un rapport', 'To finish the patrol submit a report');
  static String get reportSaved => _s('Rapport enregistré', 'Report saved');
  static String get startPatrol => _s('Début de patrouille', 'Start patrol');
  static String get patrolMap => _s('Carte patrouille', 'Patrol map');
  static String get startAction => _s('Débuter', 'Start');
  static String get report => _s('Signaler', 'Report');
  static String get makeReport => _s('Faire un signalement', 'Make a report');
  static String get missionDetails => _s('Détails de la mission', 'Mission details');
  static String get endPatrol => _s('Terminer', 'End');
  static String get inProgress => _s('En cours', 'In progress');
  static String get continue_ => _s('Continuer', 'Continue');
  static String get patrolAssigned => _s('Patrouille assignée', 'Patrol assigned');
  static String get onePatrolAtATime => _s('Vous disposez d\'une seule patrouille à la fois', 'You have one patrol at a time');
  static String get patrolStartTitle => _s('Démarrage de patrouille', 'Patrol start');
  static String get mapPatrolInProgress => _s('Carte patrouille en cours (mock)', 'Patrol map in progress (mock)');
  static String get mapPatrolMock => _s('Carte patrouille (mock)', 'Patrol map (mock)');
  static String get missionInProgress => _s('Mission en cours', 'Mission in progress');
  static String get surveillanceSite4 => _s('Surveillance Site 4', 'Site 4 surveillance');
  static String get distance => _s('Distance', 'Distance');
  static String get time => _s('Temps', 'Time');
  static String get alertGivenPleaseCheck => _s('Une alerte a été donnée. Veuillez constater les faits', 'An alert was raised. Please check the facts');
  static String get confirmTerminatePatrol => _s('Voulez-vous vraiment terminer la patrouille ?', 'Do you really want to end the patrol?');
  static String get no => _s('Non', 'No');
  static String get yes => _s('Oui', 'Yes');
  static String get vehicle => _s('Véhicule', 'Vehicle');
  static String get fire => _s('Incendie', 'Fire');
  static String get intrusion => _s('Intrusion', 'Intrusion');
  static String get accident => _s('Accident', 'Accident');
  static String get other => _s('Autre', 'Other');
  static String get voiceRecordStub => _s('Enregistrement vocal à brancher (micro).', 'Voice recording to be connected (microphone).');
  static String get locationLabel => _s('Lieu', 'Location');
  static String get patrolCompletedTitle => _s('Patrouille complétée', 'Patrol completed');
  static String get intervention => _s('Intervention', 'Intervention');
  static String get checkinStartTitle => _s('Check-in début', 'Check-in start');
  static String get siteA => _s('Site A', 'Site A');
  static String get routinePatrolNoIncident => _s('Ronde habituelle, aucun incident.', 'Routine patrol, no incident.');
  static String get controlPointNorth => _s('Point de contrôle zone Nord.', 'North zone control point.');
  static String get alarmCheckFalseAlert => _s('Vérification alarme incendie – fausse alerte.', 'Fire alarm check – false alarm.');
  static String get statusOk => _s('OK', 'OK');
  static String get thursday12Jan2022 => _s('Jeudi 12 janvier 2022', 'Thursday 12 January 2022');
  static String get signalRecorded => _s('Signalement enregistré', 'Report recorded');
  static String get reportSavedTitle => _s('Rapport enregistré', 'Report saved');

  // Éléments associés (détail historique)
  static String get associatedItems => _s('Éléments associés', 'Associated items');
  static String get onePhotoTaken => _s('1 image prise lors du contrôle', '1 image taken during check');
  static String get gpsPositionRecorded => _s('Position GPS enregistrée', 'GPS position recorded');

  // Messages / conversation
  static String get supervision => _s('Supervision', 'Supervision');
  static String get securityTeam => _s('Équipe sécurité', 'Security team');
  static String get reminderNextRound => _s('Rappel : prochaine ronde à 14h.', 'Reminder: next round at 2pm.');
  static String get thanksForReport => _s('Merci pour le signalement.', 'Thanks for the report.');
  static String get patrolValidatedSiteA => _s('Ronde validée pour le Site A.', 'Round validated for Site A.');
  static String get thanksRoundOnTime => _s('Merci, ronde terminée à l\'heure.', 'Thanks, round completed on time.');
  static String get perfectSeeYou => _s('Parfait, à la prochaine.', 'Perfect, see you next time.');
  static String get notedIllBeThere => _s('Noté, je serai là.', 'Noted, I\'ll be there.');
  static String get reportDoneZoneB => _s('Signalement effectué zone B.', 'Report filed zone B.');
  static String get sendMessageStub => _s('Envoi du message à brancher (API).', 'Message send to be connected (API).');
  static String get voiceCallStub => _s('Appel vocal à brancher (VoIP / téléphonie).', 'Voice call to be connected (VoIP).');
  static String get videoCallStub => _s('Appel vidéo à brancher (WebRTC / visio).', 'Video call to be connected (WebRTC).');
  static String get sendPhotoStub => _s('Envoi de photo à brancher (galerie / caméra).', 'Photo send to be connected (gallery/camera).');
  static String get sendFileStub => _s('Envoi de fichier à brancher (sélecteur de fichiers).', 'File send to be connected (file picker).');
  static String get yesterday => _s('Hier', 'Yesterday');
  static String get mondayShort => _s('Lun.', 'Mon.');
  static String get photoGallery => _s('Photo / Galerie', 'Photo / Gallery');
  static String get file => _s('Fichier', 'File');

  // Carte à venir / placeholder
  static String get mapComingSoon => _s('Carte à venir', 'Map coming soon');
  static String get noMessageInConversation => _s('Aucun message dans cette conversation.', 'No message in this conversation.');

  // Auth / Login
  static String get agentLogin => _s('Connexion Agent', 'Agent login');
  static String get clientSpace => _s('Espace clients', 'Client space');
  static String get welcomeAgent => _s('Bienvenue\n\nVeuillez vous identifier pour accéder au portail opérationnel.', 'Welcome\n\nPlease identify yourself to access the operational portal.');
  static String get welcomeClient => _s('Connectez-vous pour accéder à votre tableau de bord.', 'Log in to access your dashboard.');
  static String get idAgent => _s('ID Agent', 'Agent ID');
  static String get idClient => _s('ID Client', 'Client ID');
  static String get agentLabel => _s('Agent', 'Agent');
  static String get clientLabel => _s('Client', 'Client');
  static String get welcome => _s('Bienvenue', 'Welcome');
  static String get password => _s('Mot de passe', 'Password');
  static String get passwordHint => _s('Mot de passe / code pin', 'Password / PIN');
  static String get forgotPassword => _s('Mot de passe oublié ?', 'Forgot password?');
  static String get connection => _s('Connexion', 'Log in');
  static String get clientSpaceComingSoon => _s('Espace client à venir.', 'Client space coming soon.');
  static String get onlineOffline => _s('En Ligne / Hors Ligne', 'Online / Offline');
  static String get systemOperational => _s('Système Opérationnel', 'System operational');
  static String get enterEmailOrPhone => _s('Veuillez entrer votre e-mail ou numéro de téléphone', 'Please enter your email or phone number');
  static String get reportToAdmin => _s('Signaler à l\'admin', 'Report to admin');
  static String get credentialsFromWebAdmin => _s('Vos identifiants vous sont fournis par l\'administration (portail web).', 'Your login credentials are provided by the web admin.');
  static String get credentialsFromAdminOnCreation => _s('Vos identifiants de connexion sont fournis par l\'administrateur lors de la création de votre compte sur le portail web admin.', 'Your login credentials are provided by the administrator when your account is created on the web admin portal.');

  // ——— Client (dashboard, statut, profil) ——— FR + EN
  static String helloClient(String name) => _s('Bonjour, $name', 'Hello, $name');
  static String get clientHome => _s('Accueil', 'Home');
  static String get clientStatus => _s('Statut', 'Status');
  static String get clientProfile => _s('Profil', 'Profile');
  static String get clientProfileTitle => _s('Profil Client', 'Client Profile');
  static String get personalInfo => _s('Informations personnelles', 'Personal information');
  static String get manageContactDetails => _s('Gérer vos coordonnées', 'Manage your contact details');
  static String get securitySettings => _s('Paramètres de sécurité', 'Security settings');
  static String get passwordAndAuth => _s('Mot de passe et authentification', 'Password and authentication');
  static String get contactOpexunit => _s('Contacter OPEXUNIT', 'Contact OPEXUNIT');
  static String get support24_7 => _s('Support client 24/7', '24/7 customer support');
  static String get clientOpexunitLabel => _s('Client OPEXUNIT', 'OPEXUNIT Client');
  static String get defaultClientName => _s('Jean Dupont', 'Jean Dupont');
  static String get defaultCompanyName => _s('Logistique Nord S.A.', 'Logistique Nord S.A.');
  static String get siteStatus => _s('État du site', 'Site status');
  static String get currentStatus => _s('Statut actuel', 'Current status');
  static String get secure => _s('SÉCURISÉ', 'SECURE');
  static String get agentsOnDuty => _s('Agents en service', 'Agents on duty');
  static String get lastIncident => _s('Dernier incident', 'Last incident');
  static String agoHours(int n) => n == 1
      ? _s('Il y a 1h', '1 hour ago')
      : _s('Il y a ${n}h', '$n hours ago');
  static String get sosAlert => _s('SOS ALERTE', 'SOS ALERT');
  static String get hold3sForEmergency => _s('Maintenir 3s pour urgence', 'Hold 3s for emergency');
  static String get hold1sImmediate => _s('Maintien 1s = envoi immédiat', 'Hold 1s = send immediately');
  static String get sosShakeHint => _s('Vous pouvez aussi déclencher l\'alerte en secouant 2 ou 3 fois votre téléphone depuis l\'accueil.', 'You can also trigger the alert by shaking your phone 2 or 3 times from the home screen.');
  static String get triggerAlertQuestion => _s('Déclencher une alerte ?', 'Trigger an alert?');
  static String get sendNow => _s('Envoyer maintenant', 'Send now');
  static String get sendWithMessage => _s('Envoyer avec un message', 'Send with message');
  static String get addFollowUpMessage => _s('Ajouter un message', 'Add a message');
  static String get emergencyMessageHint => _s('Décrivez la situation (optionnel)...', 'Describe the situation (optional)...');
  static String get send => _s('Envoyer', 'Send');
  static String get callAgent => _s('Agent', 'Agent');
  static String get call => _s('Appeler', 'Call');
  static String get contactSecurity => _s('Contacter la sécurité', 'Contact security');
  static String get refresh => _s('Actualiser', 'Refresh');
  static String get refreshed => _s('Informations actualisées', 'Information updated');
  static String get contactSecuritySubtitle => _s('Appelez le centre de secours ou envoyez un message.', 'Call the emergency center or send a message.');
  static String get callEmergencyCenter => _s('Appeler le centre de secours', 'Call emergency center');
  static String get sendMessageToCenter => _s('Envoyer un message', 'Send a message');
  static String get commandCenter => _s('Centre de Commandement', 'Command Center');
  static String get online => _s('En ligne', 'Online');
  static String get today => _s('Aujourd\'hui', 'Today');
  static String get adminLabel => _s('Admin', 'Admin');
  static String get cannotPlaceCall => _s('Impossible d\'ouvrir l\'application téléphone.', 'Cannot open phone app.');
  static String get journal => _s('Journal', 'Journal');
  static String get clientHistory => _s('Historique', 'History');
  static String get noIncidentToReport => _s('Aucun événement suspect à signaler sur l\'ensemble de la zone.', 'No suspicious events to report across the entire area.');
  static String perimeterPatrolAt(String time) => _s('Ronde de périmètre effectuée à $time.', 'Perimeter patrol carried out at $time.');
  static String yesterdayAt(String time) => _s('Hier $time', 'Yesterday $time');
  static String get siteSecureSummary => _s('Ronde de soirée effectuée. Site sécurisé.', 'Evening round completed. Site secure.');
  static String get mySites => _s('Mes Sites', 'My Sites');
  static String get searchSitePlaceholder => _s('Rechercher un site...', 'Search a site...');
  static String get securedLabel => _s('Sécurisés', 'Secured');
  static String get alertsLabel => _s('Alertes', 'Alerts');
  static String get incidentInProgress => _s('Incident en cours', 'Incident in progress');
  static String get reinforcementRequired => _s('Renfort requis', 'Reinforcement required');
  static String agentsCount(int n) => n == 1 ? _s('1 Agent', '1 Agent') : _s('$n Agents', '$n Agents');
  static String agentReinforcement(int n) => n == 1
      ? _s('1 Agent (Renfort requis)', '1 Agent (Reinforcement required)')
      : _s('$n Agents (Renfort requis)', '$n Agents (Reinforcement required)');
  static String get entrepotNord => _s('Entrepôt Nord', 'North Warehouse');
  static String get entrepotSud => _s('Entrepôt Sud', 'South Warehouse');
  static String get laboRD => _s('Laboratoire R&D', 'R&D Laboratory');
  static String get zoneIndustrielleA => _s('Zone Industrielle A', 'Industrial Zone A');
  static String get zoneLogistiqueSud => _s('Zone Logistique Sud', 'South Logistics Zone');
  static String get campusTech => _s('Campus Tech', 'Tech Campus');
  static String get agentsOnSite => _s('Agents sur site', 'Agents on site');
  static String activeCount(int n) => _s('$n Actifs', '$n Active');
  static String get teamLeader => _s('Chef d\'équipe', 'Team leader');
  static String get canineAgent => _s('Agent Cynophile', 'Canine agent');
  static String get reportingInProgress => _s('Signalement en cours...', 'Reporting in progress...');
  static String get recentActivity => _s('Activité récente', 'Recent activity');
  static String get intrusionAlertZoneB => _s('Alerte Intrusion - Zone B', 'Intrusion alert - Zone B');
  static String get rearDoorSensorTriggered => _s('Déclenchement capteur porte arrière.', 'Rear door sensor triggered.');
  static String get controlRoundCompleted => _s('Ronde de contrôle effectuée', 'Control round completed');
  static String get northSectorVerified => _s('R.A.S. Secteur Nord vérifié.', 'Nothing to report. North sector verified.');
  static String get serviceStartDayTeam => _s('Prise de service - Équipe jour', 'Service start - Day team');
  static String get reportIncident => _s('Signaler un incident', 'Report an incident');
  static String get concernedSite => _s('Site concerné', 'Concerned site');
  static String get selectType => _s('Sélectionner le type', 'Select the type');
  static String get degradation => _s('Dégradation', 'Degradation');
  static String get quickDescription => _s('Description rapide', 'Quick description');
  static String get keyDetailsPlaceholder => _s('Détails clés (lieu précis, nombre de personnes, nature du danger...)', 'Key details (precise location, number of people, nature of the danger...)');
  static String get sendAlertButton => _s('ENVOYER L\'ALERTE', 'SEND ALERT');
  static String get defaultSiteName => _s('Tour Pacific - La Défense', 'Tour Pacific - La Défense');
  static String get minutesAgo => _s('Il y a 2 min', '2 min ago');

  // Client — Mode Urgence
  static String get emergencyMode => _s('Mode Urgence', 'Emergency Mode');
  static String get gpsActive => _s('GPS: ACTIF', 'GPS: ACTIVE');
  static String get longPressToTrigger => _s('Appui long pour déclencher', 'Long press to trigger');
  static String get security => _s('Sécurité', 'Security');
  static String get cancelAlert => _s('Annuler alerte', 'Cancel alert');

  // Client — Alerte détaillée
  static String get detailedAlert => _s('Alerte Détaillée', 'Detailed Alert');
  static String get gpsOk => _s('GPS OK', 'GPS OK');
  static String get additionalInfo => _s('Informations complémentaires', 'Additional information');
  static String get detailedAlertMessageHint => _s('Précisez la situation, nombre d\'individus, localisation précise...', 'Specify the situation, number of people, precise location...');
  static String get addPhoto => _s('Ajouter une photo', 'Add a photo');
  static String get confirmAlert => _s('CONFIRMER L\'ALERTE', 'CONFIRM ALERT');
  static String get secureEncryptedTransmission => _s('Transmission sécurisée & chiffrée', 'Secure & encrypted transmission');
  static String get confirmSendSosTitle => _s('Confirmer l\'envoi', 'Confirm send');
  static String get confirmSendSosMessage => _s('Voulez-vous envoyer cette alerte au centre de secours ?', 'Do you want to send this alert to the emergency center?');
  static String get confirm => _s('Confirmer', 'Confirm');
  static String get fireLabel => _s('FEU', 'FIRE');
  static String get intrusionLabel => _s('INTRUSION', 'INTRUSION');
  static String get injured => _s('BLESSÉ', 'INJURED');
  static String get aggression => _s('AGRESSION', 'AGRESSION');

  // Profil
  static String get systemStatus => _s('ETAT DU SYSTEME', 'SYSTEM STATUS');
  static String get operational => _s('OPÉRATIONNEL', 'OPERATIONAL');
  static String get preference => _s('PREFÉRENCE', 'PREFERENCE');
  static String get offlineMode => _s('Mode hors ligne', 'Offline mode');
  static String get offlineModeDesc => _s('Les données seront synchronisées localement et envoyées une fois la connexion rétablie.', 'Data will be synced locally and sent once connection is restored.');
  static String get language => _s('Langue', 'Language');
  static String get logout => _s('Déconnexion', 'Logout');
  static String get save => _s('Enregistrer', 'Save');
  static String get cancel => _s('Annuler', 'Cancel');
  static String get editName => _s('Modifier le nom', 'Edit name');
  static String get name => _s('Nom', 'Name');
  static String get takePhoto => _s('Prendre une photo', 'Take photo');
  static String get chooseFromGallery => _s('Choisir depuis la galerie', 'Choose from gallery');
  static String get french => _s('Français', 'French');
  static String get english => _s('English', 'English');
  static String get securityAgentGrade2 => _s('Agent de sécurité – Grade 2', 'Security agent – Grade 2');
  static String get settingsComingSoon => _s('Paramètres à venir', 'Settings coming soon');
  static String get thisSectionComingSoon => _s('Cette section sera disponible prochainement.', 'This section will be available soon.');
  static String get personalInfoAdminRequest => _s(
    'Les informations personnelles ne peuvent pas être modifiées directement. Pour toute modification (nom, coordonnées, société), adressez une demande à l\'administrateur via le portail ou votre contact OPEXUNIT.',
    'Personal information cannot be modified directly. For any change (name, contact details, company), send a request to the administrator via the portal or your OPEXUNIT contact.',
  );
  static String get personalInfoSubtitle => _s('Modification sur demande à l\'administrateur', 'Changes requested from administrator');
  static String get settings => _s('Paramètres', 'Settings');
  static String get languageAndPreferences => _s('Langue et préférences', 'Language and preferences');
  static String get notifications => _s('Notifications', 'Notifications');
  static String get noNotifications => _s('Aucune notification', 'No notifications');
  static String get seeAll => _s('Voir tout', 'See all');
  static String get recentNotifications => _s('Dernières notifications', 'Recent notifications');
  static String get cameraToConnect => _s('Ouverture caméra à brancher', 'Camera to be connected');
  static String get galleryToConnect => _s('Sélection galerie à brancher', 'Gallery picker to be connected');
  static String get gpsUpdate => _s('Mise à jour <1', 'Update <1');
  static String get authorized => _s('Autorisée', 'Authorized');
  static String get strongSignal4g => _s('Signal fort (4G)', 'Strong signal (4G)');
  static String get active => _s('Active', 'Active');

  // Commun
  static String get back => _s('Retour', 'Back');
  static String get ok => _s('OK', 'OK');
}
