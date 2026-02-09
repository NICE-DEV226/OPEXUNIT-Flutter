import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'package:flutter/foundation.dart';

import '../../../../core/app_strings.dart';
import '../../../../core/models/route_step_model.dart';
import '../../../../core/network/services/gps_api_service.dart';
import '../../../../core/offline/offline_gps_service.dart';
import '../../../../core/offline/offline_patrol_service.dart';
import '../../../../core/network/services/route_service.dart';
import '../../../../core/network/services/site_api_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/navigation_voice_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/patrol_model.dart';
import '../../data/models/site_model.dart';
import '../widgets/patrol_map_widget.dart';
import 'agent_alert_screen.dart';
import 'agent_patrol_finish_screen.dart';
import 'agent_patrol_report_screen.dart';

class AgentPatrolInProgressScreen extends StatefulWidget {
  const AgentPatrolInProgressScreen({super.key, this.patrolId});

  final String? patrolId;

  @override
  State<AgentPatrolInProgressScreen> createState() => _AgentPatrolInProgressScreenState();
}

class _AgentPatrolInProgressScreenState extends State<AgentPatrolInProgressScreen> {
  PatrolModel? _patrol;
  SiteModel? _site;
  LatLng? _userLocation;
  List<LatLng>? _routeToSite;
  List<RouteStepModel> _routeSteps = [];
  bool _instructionsExpanded = false;
  bool _loadingRoute = false;
  bool _loading = true;
  Timer? _gpsPushTimer;

  @override
  void initState() {
    super.initState();
    _loadPatrol();
  }

  @override
  void dispose() {
    _gpsPushTimer?.cancel();
    super.dispose();
  }

  void _startGpsPushLoop() {
    _gpsPushTimer?.cancel();
    _gpsPushTimer = Timer.periodic(const Duration(seconds: 45), (_) => _pushGpsPosition());
    _pushGpsPosition();
  }

  Future<void> _pushGpsPosition() async {
    if (!mounted || _patrol == null || !_patrol!.isOngoing) return;
    try {
      final position = await getCurrentPositionOptional();
      if (position == null || !mounted) return;
      final speed = position.speed >= 0 ? position.speed : null;
      final result = await OfflineGpsService.pushPosition(
        latitude: position.latitude,
        longitude: position.longitude,
        speed: speed,
      );
      if (mounted && result.alert != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sortie de zone détectée – alerte envoyée au superviseur.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.orange.shade800,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[PatrolInProgress] GPS push: $e');
    }
  }

  Future<void> _loadPatrol() async {
    if (widget.patrolId == null || widget.patrolId!.isEmpty) {
      setState(() => _loading = false);
      return;
    }
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
        });
        if (p != null && p.isOngoing) {
          _startGpsPushLoop();
        }
        if (p != null && p.pointsControle.isEmpty && site != null && site.hasLocation) {
          unawaited(_loadRouteToSite(speak: false));
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadRouteToSite({bool speak = false}) async {
    if (_site == null || !_site!.hasLocation) return;
    setState(() {
      _loadingRoute = true;
      _routeSteps = [];
    });
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        if (mounted) setState(() => _loadingRoute = false);
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _loadingRoute = false);
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
      if (speak && _site != null) {
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
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingRoute = false);
    }
  }

  static String _formatTimeRange(DateTime? start, DateTime? end) {
    if (start == null && end == null) return '';
    final s = start != null
        ? '${start.hour.toString().padLeft(2, '0')}h${start.minute.toString().padLeft(2, '0')}'
        : '?';
    final e = end != null
        ? '${end.hour.toString().padLeft(2, '0')}h${end.minute.toString().padLeft(2, '0')}'
        : '?';
    return '$s-$e';
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _TerminateChip(
              onTap: () => _showTerminateConfirmDialog(context, widget.patrolId),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryRed))
                : PatrolMapWidget(
                    patrol: _patrol,
                    site: _site,
                    userLocation: _userLocation,
                    routeToSite: _routeToSite,
                  ),
          ),

          if (_site != null && _site!.hasLocation)
            Positioned(
              left: 12,
              bottom: 220,
              child: Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(999),
                color: Colors.white,
                child: InkWell(
                  onTap: _loadingRoute
                      ? null
                      : () => _loadRouteToSite(speak: true),
                  borderRadius: BorderRadius.circular(999),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                          Icon(Icons.navigation_rounded, color: Colors.blue.shade700, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          AppStrings.navigateToSite,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            right: 24,
            bottom: 220,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AgentAlertScreen(patrolId: widget.patrolId),
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
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AgentPatrolReportScreen(patrolId: widget.patrolId),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  child: Text(AppStrings.report.toUpperCase()),
                ),
              ],
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

          // Panneau "Mission en cours" tirable vers le haut
          DraggableScrollableSheet(
            initialChildSize: 0.28,
            minChildSize: 0.12,
            maxChildSize: 0.65,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 12,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    // Poignée pour tirer
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1D5DB),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppStrings.missionInProgress,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_patrol?.heureDebut != null || _patrol?.heureFin != null)
                          Text(
                            _formatTimeRange(_patrol!.heureDebut, _patrol!.heureFin),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _patrol?.siteId != null && _patrol!.siteId!.isNotEmpty
                          ? 'Site ${_patrol!.siteId}'
                          : AppStrings.surveillanceSite4,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (_patrol != null && _patrol!.pointsControle.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Rendez-vous sur la zone de patrouille. Points à suivre dans l\'ordre :',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...List.generate(_patrol!.pointsControle.length, (i) {
                        final cp = _patrol!.pointsControle[i];
                        final label = cp.label != null && cp.label!.isNotEmpty
                            ? cp.label!
                            : 'Point ${i + 1}';
                        final reached = cp.status == 'REACHED';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: reached
                                      ? const Color(0xFF22C55E)
                                      : AppColors.primaryRed,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${i + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: reached
                                        ? Colors.grey.shade600
                                        : Colors.grey.shade800,
                                    decoration: reached
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                              ),
                              if (reached)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: Color(0xFF22C55E),
                                  size: 18,
                                ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _MissionStat(
                          label: AppStrings.distance,
                          value: '1.2 km',
                        ),
                        _MissionStat(
                          label: AppStrings.time,
                          value: '14min',
                        ),
                        Expanded(
                          child: _MissionStat(
                            label: AppStrings.description,
                            value: AppStrings.alertGivenPleaseCheck,
                            alignEnd: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TerminateChip extends StatelessWidget {
  final VoidCallback onTap;

  const _TerminateChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 16,
              color: Color(0xFF6B7280),
            ),
            SizedBox(width: 6),
            Text(
              AppStrings.endPatrol,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissionStat extends StatelessWidget {
  final String label;
  final String value;
  final bool alignEnd;

  const _MissionStat({
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: alignEnd ? 0 : 16),
      child: Column(
        crossAxisAlignment:
            alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
            textAlign: alignEnd ? TextAlign.right : TextAlign.left,
          ),
        ],
      ),
    );
  }
}

void _showTerminateConfirmDialog(BuildContext context, String? patrolId) {
  showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'terminate-patrol',
    barrierColor: Colors.black.withOpacity(0.45),
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, animation, secondaryAnimation) {
      return const SizedBox.shrink();
    },
    transitionBuilder: (dialogContext, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInBack,
      );

      return FadeTransition(
        opacity: animation,
        child: Center(
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(curved),
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: MediaQuery.of(dialogContext).size.width * 0.82,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.primaryRed,
                      child: Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppStrings.confirmTerminatePatrol,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: Text(
                            AppStrings.no,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    AgentPatrolFinishScreen(patrolId: patrolId),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryRed,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: Text(AppStrings.yes),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

