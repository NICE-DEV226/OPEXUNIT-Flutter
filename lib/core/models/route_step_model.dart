/// Une étape d'itinéraire (instruction de navigation OSRM).
class RouteStepModel {
  /// Instruction en français (ex. "Tournez à gauche", "Dans 200 m, prenez le rond-point").
  final String instruction;
  /// Distance en mètres jusqu'à cette manœuvre.
  final double distanceMeters;
  /// Nom de la voie (ex. "Rue de la Paix").
  final String? streetName;
  /// Index de l'étape (0 = départ, dernier = arrivée).
  final int index;

  const RouteStepModel({
    required this.instruction,
    required this.distanceMeters,
    this.streetName,
    this.index = 0,
  });

  /// Texte court pour affichage : "Dans X m, instruction - Rue"
  String get displayText {
    final dist = distanceMeters >= 1000
        ? '${(distanceMeters / 1000).toStringAsFixed(1)} km'
        : '${distanceMeters.toInt()} m';
    final suffix = streetName != null && streetName!.isNotEmpty ? ' – $streetName' : '';
    if (index == 0) return '$instruction$suffix';
    return 'Dans $dist, $instruction$suffix';
  }
}
