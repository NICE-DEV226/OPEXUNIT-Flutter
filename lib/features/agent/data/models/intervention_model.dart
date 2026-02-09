/// Statuts backend: OPEN, IN_PROGRESS, CLOSED
enum InterventionStatus {
  open,
  inProgress,
  closed,
}

extension InterventionStatusExt on InterventionStatus {
  static InterventionStatus fromString(String? v) {
    if (v == null) return InterventionStatus.open;
    switch (v.toUpperCase()) {
      case 'IN_PROGRESS':
        return InterventionStatus.inProgress;
      case 'CLOSED':
        return InterventionStatus.closed;
      default:
        return InterventionStatus.open;
    }
  }

  String get label {
    switch (this) {
      case InterventionStatus.open:
        return 'Ouverte';
      case InterventionStatus.inProgress:
        return 'En cours';
      case InterventionStatus.closed:
        return 'Clôturée';
    }
  }
}

/// Types backend: alerte, incident, escorte
enum InterventionType {
  alerte,
  incident,
  escorte,
}

extension InterventionTypeExt on InterventionType {
  static InterventionType fromString(String? v) {
    if (v == null) return InterventionType.incident;
    switch (v.toLowerCase()) {
      case 'alerte':
        return InterventionType.alerte;
      case 'escorte':
        return InterventionType.escorte;
      default:
        return InterventionType.incident;
    }
  }

  String get label {
    switch (this) {
      case InterventionType.alerte:
        return 'Alerte';
      case InterventionType.incident:
        return 'Incident';
      case InterventionType.escorte:
        return 'Escorte';
    }
  }
}

/// Origine backend: agent, client, system
enum InterventionOrigine {
  agent,
  client,
  system,
}

extension InterventionOrigineExt on InterventionOrigine {
  static InterventionOrigine fromString(String? v) {
    if (v == null) return InterventionOrigine.agent;
    switch (v.toLowerCase()) {
      case 'client':
        return InterventionOrigine.client;
      case 'system':
        return InterventionOrigine.system;
      default:
        return InterventionOrigine.agent;
    }
  }

  String get label {
    switch (this) {
      case InterventionOrigine.agent:
        return 'Agent';
      case InterventionOrigine.client:
        return 'Client';
      case InterventionOrigine.system:
        return 'Système';
    }
  }
}

/// Modèle intervention aligné sur le schéma backend (Intervention).
/// localisation = GeoJSON Point → coordinates [longitude, latitude].
class InterventionModel {
  final String id;
  final InterventionType type;
  final InterventionOrigine origine;
  final List<double> coordinates; // [lng, lat] GeoJSON
  final List<String> agentIds;
  final List<String> vehicleIds;
  final DateTime? heureDepart;
  final DateTime? heureArrivee;
  final String? relatedAlertId;
  final InterventionStatus statut;
  final String? rapportId;
  final String? siteId;
  final DateTime? createdAt;

  const InterventionModel({
    required this.id,
    this.type = InterventionType.incident,
    this.origine = InterventionOrigine.agent,
    this.coordinates = const [],
    this.agentIds = const [],
    this.vehicleIds = const [],
    this.heureDepart,
    this.heureArrivee,
    this.relatedAlertId,
    this.statut = InterventionStatus.open,
    this.rapportId,
    this.siteId,
    this.createdAt,
  });

  bool get hasLocation => coordinates.length >= 2;
  double? get latitude => coordinates.length >= 2 ? coordinates[1] : null;
  double? get longitude => coordinates.length >= 2 ? coordinates[0] : null;

  bool get isOpen => statut == InterventionStatus.open;
  bool get isInProgress => statut == InterventionStatus.inProgress;
  bool get isClosed => statut == InterventionStatus.closed;
  bool get canStart => statut == InterventionStatus.open;

  /// Pour affichage (titre court)
  String get displayTitle => '${type.label} • ${statut.label}';

  factory InterventionModel.fromJson(Map<String, dynamic> json) {
    final id = _oid(json['_id']) ?? _oid(json['id']) ?? '';

    List<double> coords = [];
    final loc = json['localisation'];
    if (loc is Map && loc['coordinates'] is List) {
      for (final e in loc['coordinates'] as List) {
        if (e is num) coords.add(e.toDouble());
      }
    }

    final agents = json['agents_envoyes'] ?? json['agentsEnvoyes'] ?? json['agents'];
    final agentIds = agents is List
        ? agents.map((e) => _oid(e) ?? e.toString()).where((s) => s.isNotEmpty).toList()
        : <String>[];

    final vehicles = json['vehicules'] ?? json['vehicles'];
    final vehicleIds = vehicles is List
        ? vehicles.map((e) => _oid(e) ?? e.toString()).where((s) => s.isNotEmpty).toList()
        : <String>[];

    return InterventionModel(
      id: id,
      type: InterventionTypeExt.fromString(json['type'] as String?),
      origine: InterventionOrigineExt.fromString(json['origine'] as String?),
      coordinates: coords,
      agentIds: agentIds,
      vehicleIds: vehicleIds,
      heureDepart: _date(json['heure_depart'] ?? json['heureDepart']),
      heureArrivee: _date(json['heure_arrivee'] ?? json['heureArrivee']),
      relatedAlertId: _oid(json['related_alert'] ?? json['relatedAlert']),
      statut: InterventionStatusExt.fromString(json['statut'] as String? ?? json['status'] as String?),
      rapportId: _oid(json['rapport_id'] ?? json['rapportId']),
      siteId: _oid(json['site'] ?? json['site_id'] ?? json['site_affecte']),
      createdAt: _date(json['created_at'] ?? json['createdAt']),
    );
  }

  static String? _oid(dynamic v) {
    if (v == null) return null;
    if (v is String) return v;
    if (v is Map) return (v['\$oid'] ?? v['_id'])?.toString();
    return v.toString();
  }

  static DateTime? _date(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }
}
