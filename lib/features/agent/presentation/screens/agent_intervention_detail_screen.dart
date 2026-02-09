import 'package:flutter/material.dart';

import '../../../../core/app_strings.dart';
import '../../../../core/network/services/intervention_api_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/intervention_model.dart';
import 'agent_alert_screen.dart';
import 'agent_intervention_map_screen.dart';
import 'agent_intervention_report_screen.dart';

class AgentInterventionDetailScreen extends StatefulWidget {
  const AgentInterventionDetailScreen({super.key, required this.interventionId});

  final String interventionId;

  @override
  State<AgentInterventionDetailScreen> createState() => _AgentInterventionDetailScreenState();
}

class _AgentInterventionDetailScreenState extends State<AgentInterventionDetailScreen> {
  InterventionModel? _intervention;
  bool _loading = true;
  String? _error;
  bool _starting = false;

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

  Future<void> _startIntervention() async {
    if (_intervention == null || !_intervention!.canStart) return;
    setState(() => _starting = true);
    try {
      final position = await getCurrentPositionOptional();
      final updated = await InterventionApiService.start(
        widget.interventionId,
        latitude: position?.latitude,
        longitude: position?.longitude,
      );
      if (mounted) {
        setState(() {
          _intervention = updated;
          _starting = false;
        });
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AgentInterventionMapScreen(interventionId: widget.interventionId),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _starting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e is Exception ? e.toString().replaceFirst('Exception: ', '') : '$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
          AppStrings.interventionDetail,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryRed))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black87)),
                        const SizedBox(height: 16),
                        TextButton(onPressed: _load, child: const Text('Réessayer')),
                      ],
                    ),
                  ),
                )
              : _intervention == null
                  ? const Center(child: Text('Intervention introuvable'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _InfoCard(intervention: _intervention!),
                          const SizedBox(height: 24),
                          if (_intervention!.hasLocation)
                            SizedBox(
                              height: 48,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => AgentInterventionMapScreen(
                                        interventionId: widget.interventionId,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.map_rounded, size: 22),
                                label: const Text('Voir la carte'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.blue.shade700,
                                  side: BorderSide(color: Colors.blue.shade700),
                                ),
                              ),
                            ),
                          if (_intervention!.hasLocation) const SizedBox(height: 12),
                          if (_intervention!.canStart)
                            SizedBox(
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: _starting ? null : _startIntervention,
                                icon: _starting
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Icon(Icons.play_arrow_rounded, size: 22),
                                label: Text(AppStrings.startIntervention),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF59E0B),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          if (_intervention!.isInProgress) ...[
                            SizedBox(
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => AgentInterventionMapScreen(
                                        interventionId: widget.interventionId,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.map_rounded, size: 22),
                                label: const Text('Ouvrir la carte'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade700,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 48,
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final closed = await Navigator.of(context).push<bool>(
                                    MaterialPageRoute(
                                      builder: (_) => AgentInterventionReportScreen(
                                        interventionId: widget.interventionId,
                                        intervention: _intervention,
                                      ),
                                    ),
                                  );
                                  if (closed == true && mounted) _load();
                                },
                                icon: const Icon(Icons.assignment_rounded, size: 22),
                                label: Text(AppStrings.closeIntervention),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primaryRed,
                                  side: const BorderSide(color: AppColors.primaryRed),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          if (_intervention!.hasLocation || _intervention!.isInProgress) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 48,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => AgentAlertScreen(interventionId: widget.interventionId),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.warning_amber_rounded, size: 22),
                                label: Text(AppStrings.alert),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.orange.shade700,
                                  side: BorderSide(color: Colors.orange.shade700),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.intervention});

  final InterventionModel intervention;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emergency_rounded, color: Colors.amber.shade800, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  intervention.displayTitle,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _Row(label: 'Type', value: intervention.type.label),
          _Row(label: 'Origine', value: intervention.origine.label),
          _Row(label: 'Statut', value: intervention.statut.label),
          if (intervention.heureDepart != null)
            _Row(
              label: 'Heure départ',
              value: _formatDateTime(intervention.heureDepart!),
            ),
          if (intervention.heureArrivee != null)
            _Row(
              label: 'Heure arrivée',
              value: _formatDateTime(intervention.heureArrivee!),
            ),
          if (intervention.createdAt != null)
            _Row(
              label: 'Créée le',
              value: _formatDateTime(intervention.createdAt!),
            ),
          if (intervention.hasLocation)
            _Row(
              label: AppStrings.location,
              value: '${intervention.latitude!.toStringAsFixed(5)}, ${intervention.longitude!.toStringAsFixed(5)}',
            ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
