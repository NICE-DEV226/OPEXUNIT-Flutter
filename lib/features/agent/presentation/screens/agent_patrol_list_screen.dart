import 'package:flutter/material.dart';

import '../../../../core/app_strings.dart';
import '../../../../core/auth/session_storage.dart';
import '../../../../core/offline/offline_patrol_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/patrol_model.dart';
import 'agent_patrol_in_progress_screen.dart';
import 'agent_patrol_map_screen.dart';
import 'agent_patrol_start_screen.dart';

/// Liste de toutes les patrouilles de l'agent (assignées, en cours, terminées, annulées).
/// Un même flux que la carte "Patrouille assignée" : clic ouvre le même type d'écran selon le statut.
class AgentPatrolListScreen extends StatefulWidget {
  const AgentPatrolListScreen({super.key});

  @override
  State<AgentPatrolListScreen> createState() => _AgentPatrolListScreenState();
}

class _AgentPatrolListScreenState extends State<AgentPatrolListScreen> {
  List<PatrolModel> _list = [];
  bool _loading = true;
  String? _error;

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
    final user = SessionStorage.getUser();
    if (user == null || user.id.isEmpty) {
      if (mounted) setState(() {
        _loading = false;
        _error = AppStrings.sessionExpired;
      });
      return;
    }
    try {
      final list = await OfflinePatrolService.getHistory(agentId: user.id);
      if (mounted) {
        setState(() {
          _list = list;
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

  void _openPatrol(PatrolModel patrol) {
    if (patrol.canStart) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AgentPatrolStartScreen(patrolId: patrol.id),
        ),
      );
    } else if (patrol.isOngoing) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AgentPatrolInProgressScreen(patrolId: patrol.id),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AgentPatrolMapScreen(patrolId: patrol.id),
        ),
      );
    }
  }

  static Color _statusColor(PatrolStatus status) {
    switch (status) {
      case PatrolStatus.planned:
        return AppColors.primaryRed;
      case PatrolStatus.ongoing:
        return const Color(0xFF22C55E);
      case PatrolStatus.completed:
        return const Color(0xFF6B7280);
      case PatrolStatus.cancelled:
        return const Color(0xFF9CA3AF);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          AppStrings.patrols,
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
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black87),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _load,
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                )
              : _list.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.directions_walk_rounded,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            AppStrings.noPatrols,
                            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.primaryRed,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        itemCount: _list.length,
                        itemBuilder: (context, index) {
                          final patrol = _list[index];
                          final statusColor = _statusColor(patrol.statut);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              elevation: 0,
                              shadowColor: Colors.black.withOpacity(0.05),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => _openPatrol(patrol),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.12),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.directions_walk_rounded,
                                          color: statusColor,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              patrol.siteId != null && patrol.siteId!.isNotEmpty
                                                  ? 'Site ${patrol.siteId}'
                                                  : AppStrings.patrol,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              patrol.statut.label,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: statusColor,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            if (patrol.heureDebut != null || patrol.heureFin != null) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                _formatTime(patrol.heureDebut, patrol.heureFin),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.chevron_right_rounded,
                                        color: Color(0xFF9CA3AF),
                                        size: 24,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  static String _formatTime(DateTime? start, DateTime? end) {
    if (start == null && end == null) return '';
    final s = start != null
        ? '${start.day.toString().padLeft(2, '0')}/${start.month.toString().padLeft(2, '0')} ${start.hour.toString().padLeft(2, '0')}h${start.minute.toString().padLeft(2, '0')}'
        : '?';
    final e = end != null
        ? '${end.hour.toString().padLeft(2, '0')}h${end.minute.toString().padLeft(2, '0')}'
        : '';
    return e.isEmpty ? s : '$s – $e';
  }
}
