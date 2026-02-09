import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/app_strings.dart';
import '../../../../core/models/route_step_model.dart';
import '../../../../core/offline/offline_patrol_service.dart';
import '../../../../core/network/services/route_service.dart';
import '../../../../core/network/services/site_api_service.dart';
import '../../../../core/services/navigation_voice_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/patrol_model.dart';
import '../../data/models/site_model.dart';
import '../widgets/patrol_map_widget.dart';
import 'agent_patrol_in_progress_screen.dart';
import 'agent_patrol_start_screen.dart';

class AgentPatrolMapScreen extends StatefulWidget {
  const AgentPatrolMapScreen({super.key, this.patrolId});

  final String? patrolId;

  @override
  State<AgentPatrolMapScreen> createState() => _AgentPatrolMapScreenState();
}

class _AgentPatrolMapScreenState extends State<AgentPatrolMapScreen> {
  PatrolModel? _patrol;
  SiteModel? _site;
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
    _loadPatrol();
  }

  Future<void> _loadPatrol() async {
    if (widget.patrolId == null || widget.patrolId!.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _site = null;
    });
    try {
      final p = await OfflinePatrolService.getDetails(widget.patrolId!);
      SiteModel? site;
      if (mounted && p != null && p.siteId != null && p.siteId!.isNotEmpty) {
        try {
          site = await SiteApiService.getById(p.siteId!);
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _patrol = p;
          _site = site;
          _loading = false;
          if (kDebugMode && p != null) {
            debugPrint('[PatrolMap] Patrouille chargée: ${p.pointsControle.length} point(s) site=${site?.name}');
          }
        });
        // Sans checkpoints mais avec un site : charger position + itinéraire vers le site automatiquement
        if (p != null && p.pointsControle.isEmpty && site != null && site.hasLocation) {
          unawaited(_loadRouteToSite(speak: false));
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

  /// Charge la position utilisateur et l'itinéraire vers le site. [speak] = true pour l'assistance vocale.
  Future<void> _loadRouteToSite({bool speak = true}) async {
    if (_site == null || !_site!.hasLocation) return;
    setState(() {
      _loadingRoute = true;
      _error = null;
    });
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _loadingRoute = false;
            _error = AppStrings.positionUnavailable;
          });
        }
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _loadingRoute = false;
            _error = AppStrings.positionUnavailable;
          });
        }
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      final userLatLng = LatLng(position.latitude, position.longitude);
      final siteLatLng = LatLng(_site!.latitude!, _site!.longitude!);
      final result = await RouteService.getRouteWithSteps(userLatLng, siteLatLng);
      final routePoints = result.points;
      final steps = result.steps;
      if (speak) {
        final distanceMeters = RouteService.distanceMeters(userLatLng, siteLatLng);
        await NavigationVoiceService.speakStartNavigation(
          _site!.name,
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
      if (mounted) {
        setState(() {
          _loadingRoute = false;
          _error = AppStrings.positionUnavailable;
        });
      }
    }
  }

  Future<void> _startNavigationToSite() async {
    await _loadRouteToSite(speak: true);
  }

  @override
  Widget build(BuildContext context) {
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
          AppStrings.patrol,
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
                : _error != null
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
                              TextButton(
                                onPressed: _loadPatrol,
                                child: const Text('Réessayer'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : PatrolMapWidget(
                        patrol: _patrol,
                        site: _site,
                        userLocation: _userLocation,
                        routeToSite: _routeToSite,
                      ),
          ),
          if (_routeSteps.isNotEmpty)
            Positioned(
              left: 12,
              right: 12,
              bottom: 80,
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
                            Icon(
                              _instructionsExpanded ? Icons.keyboard_arrow_down_rounded : Icons.list_rounded,
                              color: Colors.blue.shade700,
                              size: 24,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${AppStrings.navigationInstructions} (${_routeSteps.length})',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.blue.shade900,
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
                        constraints: const BoxConstraints(maxHeight: 220),
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
                                        color: i == 0
                                            ? Colors.green.shade100
                                            : i == _routeSteps.length - 1
                                                ? Colors.blue.shade100
                                                : Colors.blue.shade50,
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '${i + 1}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: i == 0
                                              ? Colors.green.shade800
                                              : i == _routeSteps.length - 1
                                                  ? Colors.blue.shade800
                                                  : Colors.blue.shade700,
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
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.black87,
                                              height: 1.3,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            AppStrings.tapToListen,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.volume_up_rounded, size: 20, color: Colors.blue.shade700),
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
          if (_site != null && _site!.hasLocation && !_loading && _error == null)
            Positioned(
              top: 12,
              right: 12,
              child: Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(999),
                color: Colors.white,
                child: InkWell(
                  onTap: _loadingRoute ? null : _startNavigationToSite,
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
                          Icon(Icons.directions_rounded, color: Colors.blue.shade700, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          AppStrings.navigateToSite,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      if (widget.patrolId != null && widget.patrolId!.isNotEmpty) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => AgentPatrolInProgressScreen(patrolId: widget.patrolId),
                          ),
                        );
                      } else {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AgentPatrolStartScreen(),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: Text(AppStrings.startAction),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
