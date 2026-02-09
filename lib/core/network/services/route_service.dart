import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../models/route_step_model.dart';

/// Résultat d'un itinéraire avec instructions (tourner à gauche, etc.).
class RouteWithStepsResult {
  const RouteWithStepsResult({
    this.points = const [],
    this.steps = const [],
  });
  final List<LatLng> points;
  final List<RouteStepModel> steps;
}

/// Service d'itinéraire via OSRM (Open Source Routing Machine).
/// Utilisé pour tracer la route de la position utilisateur vers le site.
class RouteService {
  RouteService._();

  static const String _baseUrl = 'https://router.project-osrm.org';

  /// Récupère les points de l'itinéraire entre [from] et [to].
  /// Retourne une liste vide en cas d'erreur.
  static Future<List<LatLng>> getRoute(LatLng from, LatLng to) async {
    final result = await getRouteWithSteps(from, to);
    return result.points;
  }

  /// Récupère l'itinéraire avec instructions pas à pas (tourner à gauche, dans 100 m, etc.).
  static Future<RouteWithStepsResult> getRouteWithSteps(LatLng from, LatLng to) async {
    final coords = '${from.longitude},${from.latitude};${to.longitude},${to.latitude}';
    final url = '$_baseUrl/route/v1/driving/$coords?overview=full&geometries=geojson&steps=true';
    try {
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
        onTimeout: () => http.Response('', 408),
      );
      if (response.statusCode != 200) {
        if (kDebugMode) debugPrint('[RouteService] OSRM status ${response.statusCode}');
        return RouteWithStepsResult();
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>?;
      if (data == null || data['code'] != 'Ok') return RouteWithStepsResult();
      final routes = data['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) return RouteWithStepsResult();
      final route = routes.first as Map<String, dynamic>;
      final geometry = route['geometry'] as Map<String, dynamic>?;
      final list = <LatLng>[];
      if (geometry != null) {
        final coordinates = geometry['coordinates'] as List<dynamic>?;
        if (coordinates != null) {
          for (final c in coordinates) {
            final pair = c as List<dynamic>?;
            if (pair != null && pair.length >= 2) {
              final lng = (pair[0] is num) ? (pair[0] as num).toDouble() : null;
              final lat = (pair[1] is num) ? (pair[1] as num).toDouble() : null;
              if (lng != null && lat != null) list.add(LatLng(lat, lng));
            }
          }
        }
      }
      final steps = <RouteStepModel>[];
      final legs = route['legs'] as List<dynamic>?;
      if (legs != null && legs.isNotEmpty) {
        final leg = legs.first as Map<String, dynamic>;
        final stepList = leg['steps'] as List<dynamic>?;
        if (stepList != null) {
          for (var i = 0; i < stepList.length; i++) {
            final s = stepList[i] as Map<String, dynamic>?;
            if (s == null) continue;
            final stepModel = _parseStep(s, i, stepList.length);
            if (stepModel != null) steps.add(stepModel);
          }
        }
      }
      return RouteWithStepsResult(points: list, steps: steps);
    } catch (e) {
      if (kDebugMode) debugPrint('[RouteService] Error: $e');
      return RouteWithStepsResult();
    }
  }

  static RouteStepModel? _parseStep(Map<String, dynamic> s, int index, int total) {
    final maneuver = s['maneuver'] as Map<String, dynamic>?;
    final type = (maneuver?['type'] as String?) ?? '';
    final modifier = (maneuver?['modifier'] as String?) ?? 'straight';
    final distance = (s['distance'] as num?)?.toDouble() ?? 0;
    final name = s['name'] as String?;
    final streetName = name != null && name.isNotEmpty ? name : null;
    final instruction = _instructionText(type, modifier, index, total);
    if (instruction == null) return null;
    return RouteStepModel(
      instruction: instruction,
      distanceMeters: distance,
      streetName: streetName,
      index: index,
    );
  }

  static String? _instructionText(String type, String modifier, int index, int total) {
    final isArrive = type == 'arrive' || index == total - 1;
    if (isArrive) return 'Arrivée à destination';
    switch (type) {
      case 'depart':
        return 'Départ';
      case 'arrive':
        return 'Arrivée à destination';
      case 'turn':
        return _turnModifier(modifier);
      case 'new name':
        return modifier == 'straight' ? 'Continuez tout droit' : _turnModifier(modifier);
      case 'continue':
        return 'Continuez tout droit';
      case 'rotary':
      case 'roundabout':
        return 'Prenez le rond-point';
      case 'exit rotary':
      case 'exit roundabout':
        return 'Sortez du rond-point';
      case 'fork':
      case 'end of road':
        return _turnModifier(modifier);
      case 'merge':
        return 'Fusionnez';
      default:
        return _turnModifier(modifier);
    }
  }

  static String _turnModifier(String modifier) {
    switch (modifier) {
      case 'left':
        return 'Tournez à gauche';
      case 'right':
        return 'Tournez à droite';
      case 'slight left':
        return 'Légèrement à gauche';
      case 'slight right':
        return 'Légèrement à droite';
      case 'sharp left':
        return 'Tournez à gauche';
      case 'sharp right':
        return 'Tournez à droite';
      case 'uturn':
        return 'Faites demi-tour';
      default:
        return 'Continuez tout droit';
    }
  }

  /// Distance en mètres entre deux points (approximation).
  static double distanceMeters(LatLng a, LatLng b) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Meter, a, b);
  }
}
