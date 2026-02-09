import 'package:flutter/material.dart';

import '../../../../core/app_strings.dart';
import '../../../../core/offline/offline_patrol_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/patrol_model.dart';
import '../controllers/agent_dashboard_controller.dart';
import 'agent_patrol_in_progress_screen.dart';

class AgentPatrolStartScreen extends StatefulWidget {
  const AgentPatrolStartScreen({super.key, this.patrolId});

  final String? patrolId;

  @override
  State<AgentPatrolStartScreen> createState() => _AgentPatrolStartScreenState();
}

class _AgentPatrolStartScreenState extends State<AgentPatrolStartScreen> {
  PatrolModel? _patrol;
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    if (widget.patrolId != null && widget.patrolId!.isNotEmpty) {
      _loadPatrolDetails();
    } else {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _loadPatrolDetails() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final p = await OfflinePatrolService.getDetails(widget.patrolId!);
      if (mounted) {
        setState(() {
          _patrol = p;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadError = e is Exception ? e.toString().replaceFirst('Exception: ', '') : '$e';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F7),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 140,
              height: 140,
              decoration: const BoxDecoration(
                color: AppColors.softRed,
                shape: BoxShape.circle,
              ),
              child: Container(
                margin: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primaryRed,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: const Icon(
                  Icons.checklist_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppStrings.patrolStartTitle,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: AppColors.primaryRed),
              )
            else if (_loadError != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Text(
                  _loadError!,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ),
              const SizedBox(height: 12),
            ],

            if (_patrol != null) _buildPatrolInfoSection(_patrol!),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                AppStrings.patrolAssigned,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),

            _PatrolItem(
              title: AppStrings.geolocation,
              subtitle: AppStrings.gpsRequired,
              checked: true,
            ),

            const SizedBox(height: 24),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFE5DADC),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFFB9AEB0)),
              ),
              child: Text(
                AppStrings.onePatrolAtATime,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF4B5563),
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _patrol == null
                    ? null
                    : () async {
                        if (_patrol!.canStart) {
                          final updated = await AgentDashboardController.instance.startPatrol(_patrol!.id);
                          if (!mounted) return;
                          if (updated != null) {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => AgentPatrolInProgressScreen(patrolId: widget.patrolId),
                              ),
                            );
                          }
                        } else if (_patrol!.isOngoing) {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => AgentPatrolInProgressScreen(patrolId: widget.patrolId),
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: Text(
                  _patrol != null && _patrol!.canStart
                      ? AppStrings.startPatrol
                      : AppStrings.validate,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatrolInfoSection(PatrolModel patrol) {
    final typeLabel = patrol.type == 'mobile' ? 'Mobile' : 'Ronde';
    final pointsCount = patrol.pointsControle.length;
    final heureDebut = patrol.heureDebut != null
        ? '${patrol.heureDebut!.hour.toString().padLeft(2, '0')}:${patrol.heureDebut!.minute.toString().padLeft(2, '0')}'
        : null;
    final heureFin = patrol.heureFin != null
        ? '${patrol.heureFin!.hour.toString().padLeft(2, '0')}:${patrol.heureFin!.minute.toString().padLeft(2, '0')}'
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informations patrouille',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 12),
            _InfoRow(label: 'Statut', value: patrol.statut.label),
            _InfoRow(label: 'Type', value: typeLabel),
            if (patrol.siteId != null && patrol.siteId!.isNotEmpty)
              _InfoRow(label: 'Site', value: patrol.siteId!),
            _InfoRow(label: 'Points de contrôle', value: '$pointsCount'),
            if (heureDebut != null) _InfoRow(label: 'Heure début', value: heureDebut),
            if (heureFin != null) _InfoRow(label: 'Heure fin', value: heureFin),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              '$label :',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF111827),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PatrolItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool checked;

  const _PatrolItem({
    required this.title,
    required this.subtitle,
    required this.checked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFD4D4D8),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_on_outlined,
              color: AppColors.primaryRed,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            checked ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            color: checked ? const Color(0xFF16A34A) : const Color(0xFF9CA3AF),
          ),
        ],
      ),
    );
  }
}
