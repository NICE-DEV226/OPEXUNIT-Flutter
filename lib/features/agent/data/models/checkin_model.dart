/// Type de check-in (backend: START, END, PAUSE, RESUME, OFF, OTHER).
enum CheckinType {
  start,
  end,
  pause,
  resume,
  off,
  other,
}

extension CheckinTypeExt on CheckinType {
  static CheckinType fromString(String? v) {
    if (v == null) return CheckinType.start;
    switch (v.toUpperCase()) {
      case 'END':
        return CheckinType.end;
      case 'PAUSE':
        return CheckinType.pause;
      case 'RESUME':
        return CheckinType.resume;
      case 'OFF':
        return CheckinType.off;
      case 'OTHER':
        return CheckinType.other;
      default:
        return CheckinType.start;
    }
  }

  String get value {
    switch (this) {
      case CheckinType.start:
        return 'START';
      case CheckinType.end:
        return 'END';
      case CheckinType.pause:
        return 'PAUSE';
      case CheckinType.resume:
        return 'RESUME';
      case CheckinType.off:
        return 'OFF';
      case CheckinType.other:
        return 'OTHER';
    }
  }

  String get label {
    switch (this) {
      case CheckinType.start:
        return 'Prise de service';
      case CheckinType.end:
        return 'Fin de service';
      case CheckinType.pause:
        return 'Pause';
      case CheckinType.resume:
        return 'Reprise';
      case CheckinType.off:
        return 'Hors service';
      case CheckinType.other:
        return 'Autre';
    }
  }
}

/// Modèle check-in aligné sur le schéma backend (Checkin).
class CheckinModel {
  final String id;
  final String userId;
  final CheckinType type;
  final DateTime timestamp;
  final List<double> coordinates; // [lng, lat] GeoJSON
  final String? photo;
  final String? patrolId;
  final String? notes;

  const CheckinModel({
    required this.id,
    required this.userId,
    this.type = CheckinType.start,
    required this.timestamp,
    this.coordinates = const [],
    this.photo,
    this.patrolId,
    this.notes,
  });

  bool get hasLocation => coordinates.length >= 2;
  double? get latitude => coordinates.length >= 2 ? coordinates[1] : null;
  double? get longitude => coordinates.length >= 2 ? coordinates[0] : null;

  factory CheckinModel.fromJson(Map<String, dynamic> json) {
    final id = _oid(json['_id']) ?? _oid(json['id']) ?? '';
    final user = json['user'];
    final String userId = (user is Map ? _oid(user['_id'] ?? user['id']) : _oid(user)) ?? '';

    List<double> coords = [];
    final loc = json['location'];
    if (loc is Map && loc['coordinates'] is List) {
      for (final e in loc['coordinates'] as List) {
        if (e is num) coords.add(e.toDouble());
      }
    }

    return CheckinModel(
      id: id,
      userId: userId,
      type: CheckinTypeExt.fromString(json['type'] as String?),
      timestamp: _date(json['timestamp']) ?? DateTime.now(),
      coordinates: coords,
      photo: json['photo'] as String?,
      patrolId: _oid(json['patrol']),
      notes: json['notes'] as String?,
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
