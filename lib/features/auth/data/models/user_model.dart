/// Modèle utilisateur aligné sur le schéma backend (User Mongoose).
/// Rôles: ADMIN, SUPERVISEUR, AGENT, CLIENT.

String? _objectIdToString(dynamic v) {
  if (v == null) return null;
  if (v is String) return v;
  if (v is Map) return (v['\$oid'] ?? v['id'] ?? v['_id'])?.toString();
  return v.toString();
}

bool _toBool(dynamic v) {
  if (v == null) return false;
  if (v is bool) return v;
  if (v is String) return v.toLowerCase() == 'true' || v == '1';
  if (v is int) return v != 0;
  return false;
}

class UserModel {
  final String id;
  final String nom;
  final String prenom;
  final String telephone;
  final String email;
  final String role; // ADMIN | SUPERVISEUR | AGENT | CLIENT
  final String statut; // ACTIF | SUSPENDU
  final String? matricule;
  final String? siteAffecte;
  final String? zoneAffectee;
  final String? photoProfil;
  final String? fcmToken;
  final String? ville;
  final bool profileComplete;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.telephone,
    required this.email,
    required this.role,
    this.statut = 'ACTIF',
    this.matricule,
    this.siteAffecte,
    this.zoneAffectee,
    this.photoProfil,
    this.fcmToken,
    this.ville,
    this.profileComplete = false,
    this.createdAt,
  });

  String get fullName => '$prenom $nom';

  /// True si l'utilisateur doit être redirigé vers l'espace client.
  bool get isClient => role == 'CLIENT';

  /// True si l'utilisateur doit être redirigé vers l'espace agent (ADMIN, SUPERVISEUR, AGENT).
  bool get isAgent => role == 'ADMIN' || role == 'SUPERVISEUR' || role == 'AGENT';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: _objectIdToString(json['_id']) ?? _objectIdToString(json['id']) ?? '',
      nom: json['nom'] as String? ?? '',
      prenom: json['prenom'] as String? ?? '',
      telephone: json['telephone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: (json['role'] as String? ?? 'AGENT').toUpperCase(),
      statut: (json['statut'] as String? ?? 'ACTIF').toUpperCase(),
      matricule: json['matricule'] as String?,
      siteAffecte: _objectIdToString(json['site_affecte']),
      zoneAffectee: _objectIdToString(json['zone_affectee']),
      photoProfil: json['photoProfil'] as String?,
      fcmToken: json['fcmToken'] as String?,
      ville: json['ville'] as String?,
      profileComplete: _toBool(json['profileComplete']),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      '_id': id,
      'nom': nom,
      'prenom': prenom,
      'telephone': telephone,
      'email': email,
      'role': role,
      'statut': statut,
      'matricule': matricule,
      'site_affecte': siteAffecte,
      'zone_affectee': zoneAffectee,
      'photoProfil': photoProfil,
      'fcmToken': fcmToken,
      'ville': ville,
      'profileComplete': profileComplete,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
