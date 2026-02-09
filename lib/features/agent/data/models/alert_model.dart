/// Types d'alerte backend : panique, chute, client, zone, system
enum AlertType {
  panique,
  chute,
  client,
  zone,
  system,
}

extension AlertTypeExt on AlertType {
  static AlertType fromString(String? v) {
    if (v == null) return AlertType.panique;
    switch (v.toLowerCase()) {
      case 'chute':
        return AlertType.chute;
      case 'client':
        return AlertType.client;
      case 'zone':
        return AlertType.zone;
      case 'system':
        return AlertType.system;
      default:
        return AlertType.panique;
    }
  }

  String get value {
    switch (this) {
      case AlertType.panique:
        return 'panique';
      case AlertType.chute:
        return 'chute';
      case AlertType.client:
        return 'client';
      case AlertType.zone:
        return 'zone';
      case AlertType.system:
        return 'system';
    }
  }
}

/// Priorité backend : LOW, MEDIUM, HIGH
enum AlertPriorite {
  low,
  medium,
  high,
}

extension AlertPrioriteExt on AlertPriorite {
  static AlertPriorite fromString(String? v) {
    if (v == null) return AlertPriorite.medium;
    switch (v.toUpperCase()) {
      case 'LOW':
        return AlertPriorite.low;
      case 'HIGH':
        return AlertPriorite.high;
      default:
        return AlertPriorite.medium;
    }
  }

  String get value {
    switch (this) {
      case AlertPriorite.low:
        return 'LOW';
      case AlertPriorite.medium:
        return 'MEDIUM';
      case AlertPriorite.high:
        return 'HIGH';
    }
  }
}

/// Statut backend : OPEN, ACKED, RESOLVED
enum AlertStatut {
  open,
  acked,
  resolved,
}

extension AlertStatutExt on AlertStatut {
  static AlertStatut fromString(String? v) {
    if (v == null) return AlertStatut.open;
    switch (v.toUpperCase()) {
      case 'ACKED':
        return AlertStatut.acked;
      case 'RESOLVED':
        return AlertStatut.resolved;
      default:
        return AlertStatut.open;
    }
  }

  String get label {
    switch (this) {
      case AlertStatut.open:
        return 'Ouverte';
      case AlertStatut.acked:
        return 'Acquittée';
      case AlertStatut.resolved:
        return 'Résolue';
    }
  }
}

/// Modèle alerte aligné sur le schéma backend (Alert).
class AlertModel {
  final String id;
  final AlertType type;
  final String? source;
  final AlertPriorite priorite;
  final List<double> coordinates; // [lng, lat] GeoJSON
  final String? createdById;
  final AlertStatut statut;
  final String? relatedInterventionId;
  final String? relatedPatrolId;
  final DateTime? createdAt;

  const AlertModel({
    required this.id,
    this.type = AlertType.panique,
    this.source,
    this.priorite = AlertPriorite.medium,
    this.coordinates = const [],
    this.createdById,
    this.statut = AlertStatut.open,
    this.relatedInterventionId,
    this.relatedPatrolId,
    this.createdAt,
  });

  bool get hasLocation => coordinates.length >= 2;
  double? get latitude => coordinates.length >= 2 ? coordinates[1] : null;
  double? get longitude => coordinates.length >= 2 ? coordinates[0] : null;

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    final id = _oid(json['_id']) ?? _oid(json['id']) ?? '';
    List<double> coords = [];
    final loc = json['localisation'];
    if (loc is Map && loc['coordinates'] is List) {
      for (final e in loc['coordinates'] as List) {
        if (e is num) coords.add(e.toDouble());
      }
    }
    return AlertModel(
      id: id,
      type: AlertTypeExt.fromString(json['type'] as String?),
      source: json['source'] as String?,
      priorite: AlertPrioriteExt.fromString(json['priorite'] as String?),
      coordinates: coords,
      createdById: _oid(json['created_by'] ?? json['createdBy']),
      statut: AlertStatutExt.fromString(json['statut'] as String? ?? json['status'] as String?),
      relatedInterventionId: _oid(json['related_intervention'] ?? json['relatedIntervention']),
      relatedPatrolId: _oid(json['related_patrol'] ?? json['relatedPatrol']),
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
