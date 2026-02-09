/// Modèle Site aligné sur le schéma backend (Site).
/// location.coordinates = [longitude, latitude] (GeoJSON).
class SiteModel {
  final String id;
  final String name;
  final String? description;
  final List<double> coordinates; // [lng, lat]
  final String niveauRisque; // LOW, MEDIUM, HIGH
  final DateTime? createdAt;

  const SiteModel({
    required this.id,
    required this.name,
    this.description,
    this.coordinates = const [],
    this.niveauRisque = 'LOW',
    this.createdAt,
  });

  /// True si le site a des coordonnées valides (pour la carte).
  bool get hasLocation => coordinates.length >= 2;

  /// Latitude (pour LatLng).
  double? get latitude => coordinates.length >= 2 ? coordinates[1] : null;

  /// Longitude (pour LatLng).
  double? get longitude => coordinates.length >= 2 ? coordinates[0] : null;

  factory SiteModel.fromJson(Map<String, dynamic> json) {
    String? id;
    if (json['_id'] != null) id = json['_id'].toString();
    if (id == null && json['id'] != null) id = json['id'].toString();
    if (id == null) id = '';

    List<double> coords = [];
    final loc = json['location'];
    if (loc is Map && loc['coordinates'] is List) {
      for (final e in loc['coordinates'] as List) {
        if (e is num) coords.add(e.toDouble());
      }
    }

    final risque = (json['niveau_risque'] as String?)?.toUpperCase() ?? 'LOW';

    return SiteModel(
      id: id,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      coordinates: coords,
      niveauRisque: risque,
      createdAt: _date(json['created_at']),
    );
  }

  static DateTime? _date(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }
}
