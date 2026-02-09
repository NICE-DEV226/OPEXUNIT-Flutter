import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../data/models/patrol_model.dart';
import '../../data/models/site_model.dart';
import '../../../../core/theme/app_colors.dart';

/// Centre par défaut si pas de checkpoints ni site (France).
final LatLng _defaultCenter = LatLng(46.603354, 1.888334);
const double _defaultZoom = 14.0;

/// Convertit les points de contrôle en liste LatLng pour la carte.
/// Backend GeoJSON : [longitude, latitude] → LatLng(latitude, longitude).
List<LatLng> checkpointToLatLngList(List<CheckpointModel> points) {
  final list = <LatLng>[];
  for (final p in points) {
    if (p.coordinates.length >= 2) {
      list.add(LatLng(p.coordinates[1], p.coordinates[0]));
    }
  }
  return list;
}

/// Carte patrouille : site (coordonnées du lieu), itinéraire (polyline), checkpoints en marqueurs.
/// Optionnel : [userLocation] et [routeToSite] pour la navigation ; [interventionLocation] pour une intervention (point unique).
class PatrolMapWidget extends StatelessWidget {
  const PatrolMapWidget({
    super.key,
    this.patrol,
    this.site,
    this.userLocation,
    this.routeToSite,
    this.interventionLocation,
    this.interventionLabel,
  });

  final PatrolModel? patrol;
  /// Site associé à la patrouille (récupéré via GET /api/sites/:id) pour afficher le lieu.
  final SiteModel? site;
  /// Position actuelle de l'utilisateur (pour navigation vers le site).
  final LatLng? userLocation;
  /// Points de l'itinéraire depuis [userLocation] vers le site (ex. OSRM).
  final List<LatLng>? routeToSite;
  /// Lieu d'intervention (point unique, ex. localisation intervention).
  final LatLng? interventionLocation;
  /// Libellé du marqueur intervention.
  final String? interventionLabel;

  @override
  Widget build(BuildContext context) {
    final points = patrol != null ? checkpointToLatLngList(patrol!.pointsControle) : <LatLng>[];
    final hasPoints = points.isNotEmpty;
    final siteLatLng = site != null && site!.hasLocation
        ? LatLng(site!.latitude!, site!.longitude!)
        : null;
    if (kDebugMode && patrol != null) {
      debugPrint('[PatrolMap] Patrouille: ${patrol!.pointsControle.length} checkpoint(s) → ${points.length} coordonnées; site=${site?.name} coords=${siteLatLng != null ? "${site!.latitude}, ${site!.longitude}" : "non"}');
    }

    final allPointsForBounds = <LatLng>[];
    if (siteLatLng != null) allPointsForBounds.add(siteLatLng);
    allPointsForBounds.addAll(points);
    if (interventionLocation != null) allPointsForBounds.add(interventionLocation!);
    if (userLocation != null) allPointsForBounds.add(userLocation!);
    if (routeToSite != null && routeToSite!.isNotEmpty) allPointsForBounds.addAll(routeToSite!);
    final hasAnyLocation = allPointsForBounds.isNotEmpty;

    final MapOptions options = hasAnyLocation
        ? (allPointsForBounds.length == 1
            ? MapOptions(
                initialCenter: allPointsForBounds.first,
                initialZoom: 15,
                interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
              )
            : MapOptions(
                initialCameraFit: CameraFit.bounds(
                  bounds: LatLngBounds.fromPoints(allPointsForBounds),
                  padding: const EdgeInsets.all(56),
                  maxZoom: 18,
                  minZoom: 10,
                ),
                interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
              ))
        : MapOptions(
            initialCenter: _defaultCenter,
            initialZoom: _defaultZoom,
            interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
          );

    final markers = <Marker>[];
    if (userLocation != null) {
      markers.add(
        Marker(
          point: userLocation!,
          width: 44,
          height: 44,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.person_pin_circle_rounded, color: Colors.white, size: 22),
          ),
        ),
      );
    }
    if (interventionLocation != null) {
      markers.add(
        Marker(
          point: interventionLocation!,
          width: 72,
          height: 64,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.emergency_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 2),
              SizedBox(
                width: 64,
                child: Text(
                  interventionLabel ?? 'Intervention',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF374151),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (siteLatLng != null) {
      markers.add(
        Marker(
          point: siteLatLng,
          width: 72,
          height: 64,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 2),
              SizedBox(
                width: 64,
                child: Text(
                  site?.name ?? 'Site',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF374151),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      final checkpoint = patrol != null && i < patrol!.pointsControle.length
          ? patrol!.pointsControle[i]
          : null;
      final isReached = checkpoint?.status == 'REACHED';
      final label = checkpoint?.label;
      markers.add(
        Marker(
          point: point,
          width: label != null && label.isNotEmpty ? 72 : 40,
          height: label != null && label.isNotEmpty ? 52 : 40,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isReached ? const Color(0xFF22C55E) : AppColors.primaryRed,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  '${i + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (label != null && label.isNotEmpty) ...[
                const SizedBox(height: 2),
                SizedBox(
                  width: 64,
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final polylines = <Polyline>[];
    if (hasPoints && points.length > 1) {
      polylines.add(
        Polyline(
          points: points,
          strokeWidth: 5,
          color: AppColors.primaryRed.withOpacity(0.9),
          borderStrokeWidth: 2,
          borderColor: Colors.white,
        ),
      );
    }
    if (routeToSite != null && routeToSite!.length >= 2) {
      polylines.add(
        Polyline(
          points: routeToSite!,
          strokeWidth: 5,
          color: const Color(0xFF3B82F6).withOpacity(0.9),
          borderStrokeWidth: 2,
          borderColor: Colors.white,
        ),
      );
    }

    return Stack(
      children: [
        FlutterMap(
      options: options,
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'opexunit_mobile',
          maxNativeZoom: 19,
        ),
        if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
        MarkerLayer(markers: markers),
        RichAttributionWidget(
          animationConfig: const ScaleRAWA(),
          showFlutterMapAttribution: false,
          attributions: [
            TextSourceAttribution('OpenStreetMap contributors'),
          ],
          popupInitialDisplayDuration: const Duration(seconds: 2),
        ),
      ],
        ),
        if (patrol != null && hasPoints)
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Material(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(12),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Icon(
                      Icons.route_rounded,
                      color: AppColors.primaryRed,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Itinéraire de patrouille',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Rendez-vous sur la zone et suivez les points dans l\'ordre (${points.length} point${points.length > 1 ? 's' : ''})',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (patrol != null && !hasPoints)
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Material(
              color: siteLatLng != null ? Colors.blue.shade50 : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      siteLatLng != null ? Icons.location_on_rounded : Icons.info_outline_rounded,
                      color: siteLatLng != null ? Colors.blue.shade800 : Colors.orange.shade800,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            siteLatLng != null
                                ? 'Lieu de patrouille: ${site?.name ?? "Site"}'
                                : 'Aucun itinéraire affiché',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: siteLatLng != null ? Colors.blue.shade900 : Colors.orange.shade900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            siteLatLng != null
                                ? 'Rendez-vous sur le site. Aucun point de contrôle défini pour cette patrouille.'
                                : 'La patrouille n\'a pas de site avec coordonnées ni de points de contrôle. Vérifiez le backend.',
                            style: TextStyle(
                              fontSize: 11,
                              color: siteLatLng != null ? Colors.blue.shade800 : Colors.orange.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
