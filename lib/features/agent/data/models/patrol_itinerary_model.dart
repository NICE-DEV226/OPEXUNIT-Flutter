import 'patrol_model.dart';

/// Un point GPS enregistré pendant la patrouille (réponse GET /api/patrols/:id/itinerary).
class GpsPointModel {
  const GpsPointModel({
    required this.latitude,
    required this.longitude,
    this.timestamp,
    this.speed,
  });
  final double latitude;
  final double longitude;
  final DateTime? timestamp;
  final double? speed;

  factory GpsPointModel.fromJson(Map<String, dynamic> json) {
    final lat = json['latitude'];
    final lng = json['longitude'];
    return GpsPointModel(
      latitude: (lat is num) ? lat.toDouble() : 0,
      longitude: (lng is num) ? lng.toDouble() : 0,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString())
          : null,
      speed: json['speed'] is num ? (json['speed'] as num).toDouble() : null,
    );
  }
}

/// Réponse GET /api/patrols/:id/itinerary (patrol + trace GPS + alertes).
class PatrolItineraryModel {
  const PatrolItineraryModel({
    this.patrol,
    this.gps = const [],
    this.alerts = const [],
  });
  final PatrolModel? patrol;
  final List<GpsPointModel> gps;
  final List<Map<String, dynamic>> alerts;

  factory PatrolItineraryModel.fromJson(Map<String, dynamic> json) {
    PatrolModel? patrol;
    if (json['patrol'] is Map<String, dynamic>) {
      patrol = PatrolModel.fromJson(json['patrol'] as Map<String, dynamic>);
    }
    final gpsList = json['gps'] as List<dynamic>? ?? [];
    final gps = gpsList
        .whereType<Map<String, dynamic>>()
        .map((e) => GpsPointModel.fromJson(e))
        .toList();
    final alertsList = json['alerts'] as List<dynamic>? ?? [];
    final alerts = alertsList
        .whereType<Map<String, dynamic>>()
        .toList();
    return PatrolItineraryModel(patrol: patrol, gps: gps, alerts: alerts);
  }
}
