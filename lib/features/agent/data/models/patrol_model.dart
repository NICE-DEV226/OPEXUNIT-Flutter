/// Statuts possibles d'une patrouille (backend).
enum PatrolStatus {
  planned,
  ongoing,
  completed,
  cancelled,
}

extension PatrolStatusExt on PatrolStatus {
  static PatrolStatus fromString(String? v) {
    if (v == null) return PatrolStatus.planned;
    switch (v.toUpperCase()) {
      case 'ONGOING':
        return PatrolStatus.ongoing;
      case 'COMPLETED':
        return PatrolStatus.completed;
      case 'CANCELLED':
        return PatrolStatus.cancelled;
      default:
        return PatrolStatus.planned;
    }
  }

  String get label {
    switch (this) {
      case PatrolStatus.planned:
        return 'Planifiée';
      case PatrolStatus.ongoing:
        return 'En cours';
      case PatrolStatus.completed:
        return 'Terminée';
      case PatrolStatus.cancelled:
        return 'Annulée';
    }
  }
}

/// Point de contrôle (checkpoint).
/// Coordonnées backend : GeoJSON [longitude, latitude].
class CheckpointModel {
  final List<double> coordinates; // [lng, lat] GeoJSON
  final String? label;
  final DateTime? timestamp;
  final String status; // PENDING, REACHED, MISSED

  const CheckpointModel({
    this.coordinates = const [],
    this.label,
    this.timestamp,
    this.status = 'PENDING',
  });

  factory CheckpointModel.fromJson(Map<String, dynamic> json) {
    List<double> coords = [];
    // Backend: point.coordinates (GeoJSON) ou coordinates à la racine
    final point = json['point'];
    if (point is Map && point['coordinates'] is List) {
      for (final e in point['coordinates'] as List) {
        if (e is num) coords.add(e.toDouble());
      }
    }
    if (coords.length < 2 && json['coordinates'] is List) {
      for (final e in json['coordinates'] as List) {
        if (e is num) coords.add(e.toDouble());
      }
    }
    return CheckpointModel(
      coordinates: coords,
      label: json['label'] as String? ?? json['name'] as String?,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString())
          : null,
      status: (json['status'] as String?)?.toUpperCase() ?? 'PENDING',
    );
  }
}

/// Modèle patrouille aligné sur le schéma backend (Patrol).
class PatrolModel {
  final String id;
  final String type; // mobile, round
  final List<String> agentIds;
  final String? siteId;
  final DateTime? heureDebut;
  final DateTime? heureFin;
  final List<CheckpointModel> pointsControle;
  final List<String> anomalies;
  final PatrolStatus statut;
  final DateTime? createdAt;

  const PatrolModel({
    required this.id,
    this.type = 'round',
    this.agentIds = const [],
    this.siteId,
    this.heureDebut,
    this.heureFin,
    this.pointsControle = const [],
    this.anomalies = const [],
    this.statut = PatrolStatus.planned,
    this.createdAt,
  });

  bool get isPlanned => statut == PatrolStatus.planned;
  bool get isOngoing => statut == PatrolStatus.ongoing;
  bool get canStart => statut == PatrolStatus.planned;

  factory PatrolModel.fromJson(Map<String, dynamic> json) {
    String? id;
    if (json['_id'] != null) id = json['_id'].toString();
    if (id == null && json['id'] != null) id = json['id'].toString();
    if (id == null) id = '';

    final agents = json['agents'];
    final agentIds = agents is List
        ? agents.map((e) => e.toString()).toList()
        : <String>[];

    final points = json['points_controle'] as List? ?? json['pointsControle'] as List? ?? [];
    final pointsControle = points
        .whereType<Map<String, dynamic>>()
        .map((e) => CheckpointModel.fromJson(e))
        .toList();

    final anomaliesList = json['anomalies'] as List? ?? [];
    final anomaliesStr = anomaliesList.map((e) => e.toString()).toList();

    return PatrolModel(
      id: id,
      type: json['type'] as String? ?? 'round',
      agentIds: agentIds,
      siteId: _oid(json['site']),
      heureDebut: _date(json['heure_debut']),
      heureFin: _date(json['heure_fin']),
      pointsControle: pointsControle,
      anomalies: anomaliesStr,
      statut: PatrolStatusExt.fromString(json['statut'] as String?),
      createdAt: _date(json['created_at']),
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
