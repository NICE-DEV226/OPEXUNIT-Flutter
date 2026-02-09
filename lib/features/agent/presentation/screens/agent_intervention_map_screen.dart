import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/app_strings.dart';
import '../../../../core/models/route_step_model.dart';
import '../../../../core/network/services/intervention_api_service.dart';
import '../../../../core/network/services/route_service.dart';
import '../../../../core/services/navigation_voice_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/intervention_model.dart';
import '../widgets/patrol_map_widget.dart';
import 'agent_alert_screen.dart';

class AgentInterventionMapScreen extends StatefulWidget {
  const AgentInterventionMapScreen({super.key, required this.interventionId});

  final String interventionId;

  @override
  State<AgentInterventionMapScreen> createState() => _AgentInterventionMapScreenState();
}

class _AgentInterventionMapScreenState extends State<AgentInterventionMapScreen> {
  InterventionModel? _intervention;
  bool _loading = true;
  String? _error;
  LatLng? _userLocation;
  List<LatLng>? _routeToSite;
  List<RouteStepModel> _routeSteps = [];
  bool _loadingRoute = false;
  bool _instructionsExpanded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final i = await InterventionApiService.getById(widget.interventionId);
      if (mounted) {
        setState(() {
          _intervention = i;
          _loading = false;
        });
        if (i != null && i.hasLocation) {
          _loadRouteToIntervention(speak: false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e is Exception ? e.toString().replaceFirst('Exception: ', '') : '$e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadRouteToIntervention({bool speak = false}) async {
    if (_intervention == null || !_intervention!.hasLocation) return;
    setState(() {
      _loadingRoute = true;
      _error = null;
    });
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() {
          _loadingRoute = false;
          _error = AppStrings.positionUnavailable;
        });
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (mounted) setState(() {
          _loadingRoute = false;
          _error = AppStrings.positionUnavailable;
        });
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      final userLatLng = LatLng(position.latitude, position.longitude);
      final destLatLng = LatLng(_intervention!.latitude!, _intervention!.longitude!);
      final result = await RouteService.getRouteWithSteps(userLatLng, destLatLng);
      final routePoints = result.points;
      final steps = result.steps;
      if (speak) {
        final distanceMeters = RouteService.distanceMeters(userLatLng, destLatLng);
        await NavigationVoiceService.speakStartNavigation(
          _intervention!.displayTitle,
          distanceMeters,
        );
        if (steps.isNotEmpty && steps.length > 1) {
          await NavigationVoiceService.speakInstruction(steps[1].displayText);
        }
      }
      if (mounted) {
        setState(() {
          _userLocation = userLatLng;
          _routeToSite = routePoints.isNotEmpty ? routePoints : null;
          _routeSteps = steps;
          _loadingRoute = false;
          _error = routePoints.isEmpty ? AppStrings.routeUnavailable : null;
        });
      }
    } catch (e) {
      if (mounted) setState(() {
        _loadingRoute = false;
        _error = AppStrings.positionUnavailable;
      });
    }
  }

  Future<void> _startNavigation() async {
    await _loadRouteToIntervention(speak: true);
  }

  @override
  Widget build(BuildContext context) {
    final hasLocation = _intervention != null && _intervention!.hasLocation;
    final interventionLatLng = hasLocation
        ? LatLng(_intervention!.latitude!, _intervention!.longitude!)
        : null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          AppStrings.intervention,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryRed))
                : _error != null && !hasLocation
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.black87),
                              ),
                              const SizedBox(height: 16),
                              TextButton(onPressed: _load, child: const Text('Réessayer')),
                            ],
                          ),
                        ),
                      )
                    : interventionLatLng == null
                        ? const Center(child: Text('Aucune localisation pour cette intervention.'))
                        : PatrolMapWidget(
                            patrol: null,
                            site: null,
                            userLocation: _userLocation,
                            routeToSite: _routeToSite,
                            interventionLocation: interventionLatLng,
                            interventionLabel: _intervention?.displayTitle ?? 'Intervention',
                          ),
          ),
          if (_routeSteps.isNotEmpty)
            Positioned(
              left: 12,
              right: 12,
              bottom: 24,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => setState(() => _instructionsExpanded = !_instructionsExpanded),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            Icon(Icons.list_rounded, color: Colors.amber.shade800, size: 24),
                            const SizedBox(width: 10),
                            Text(
                              '${AppStrings.navigationInstructions} (${_routeSteps.length})',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.amber.shade900,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              _instructionsExpanded ? Icons.expand_more : Icons.expand_less,
                              color: Colors.grey.shade700,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_instructionsExpanded)
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: ListView.builder(
                          shrinkWrap: true,
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                          itemCount: _routeSteps.length,
                          itemBuilder: (context, i) {
                            final step = _routeSteps[i];
                            return InkWell(
                              onTap: () => NavigationVoiceService.speakInstruction(step.displayText),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: i == 0 ? Colors.green.shade100
                                            : i == _routeSteps.length - 1 ? Colors.amber.shade100
                                            : Colors.amber.shade50,
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '${i + 1}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: i == 0 ? Colors.green.shade800
                                              : i == _routeSteps.length - 1 ? Colors.amber.shade900
                                              : Colors.amber.shade800,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            step.displayText,
                                            style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.3),
                                          ),
                                          Text(
                                            AppStrings.tapToListen,
                                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.volume_up_rounded, size: 20, color: Colors.amber.shade800),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          if (hasLocation && !_loading)
            Positioned(
              top: 12,
              right: 12,
              child: Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(999),
                color: Colors.white,
                child: InkWell(
                  onTap: _loadingRoute ? null : _startNavigation,
                  borderRadius: BorderRadius.circular(999),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_loadingRoute)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          Icon(Icons.directions_rounded, color: Colors.amber.shade800, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          AppStrings.navigateToSite,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (hasLocation && !_loading)
            Positioned(
              right: 12,
              bottom: _routeSteps.isNotEmpty ? 220 : 100,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AgentAlertScreen(interventionId: widget.interventionId),
                    ),
                  );
                },
                icon: const Icon(Icons.warning_amber_rounded, size: 20),
                label: Text(AppStrings.alert.toUpperCase()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
