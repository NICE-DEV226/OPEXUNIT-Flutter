import 'package:flutter/material.dart';

import '../../../../core/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import 'client_contact_security_screen.dart';
import 'client_detailed_alert_screen.dart';

/// Écran détail d'un site : image, agents sur site, activité récente, bouton Signaler un incident.
class ClientSiteDetailScreen extends StatelessWidget {
  final String siteName;
  final String siteLocation;

  const ClientSiteDetailScreen({
    super.key,
    required this.siteName,
    required this.siteLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              siteName,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            centerTitle: true,
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: Colors.black87),
                onSelected: (value) => _onSiteMenuSelected(context, value),
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'contact',
                    child: Row(
                      children: [
                        const Icon(Icons.phone_rounded, size: 22, color: Color(0xFF374151)),
                        const SizedBox(width: 12),
                        Text(AppStrings.contactSecurity),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'incident',
                    child: Row(
                      children: [
                        const Icon(Icons.campaign_rounded, size: 22, color: Color(0xFF374151)),
                        const SizedBox(width: 12),
                        Text(AppStrings.reportIncident),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'refresh',
                    child: Row(
                      children: [
                        const Icon(Icons.refresh_rounded, size: 22, color: Color(0xFF374151)),
                        const SizedBox(width: 12),
                        Text(AppStrings.refresh),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSiteImage(context),
                _buildAgentsSection(context),
                _buildRecentActivity(context),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildReportIncidentButton(context),
    );
  }

  void _onSiteMenuSelected(BuildContext context, String value) {
    switch (value) {
      case 'contact':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const ClientContactSecurityScreen(),
          ),
        );
        break;
      case 'incident':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ClientDetailedAlertScreen(siteName: siteName),
          ),
        );
        break;
      case 'refresh':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.refreshed)),
        );
        break;
    }
  }

  Widget _buildSiteImage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Stack(
        alignment: Alignment.bottomLeft,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 200,
              width: double.infinity,
              color: const Color(0xFFE5E7EB),
              child: Icon(
                Icons.warehouse_rounded,
                size: 64,
                color: Colors.grey.shade400,
              ),
            ),
          ),
          Positioned(
            left: 16,
            bottom: 12,
            child: Text(
              AppStrings.agentsOnSite,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                shadows: [Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 1))],
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF374151),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                AppStrings.activeCount(3),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentsSection(BuildContext context) {
    final agents = [
      _AgentRow(name: 'Marc Dubois', role: AppStrings.teamLeader, isReporting: false),
      _AgentRow(name: 'Sarah Leblanc', role: AppStrings.canineAgent, isReporting: false),
      _AgentRow(name: 'Jean Moreau', role: AppStrings.reportingInProgress, isReporting: true),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...agents.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _AgentTile(agent: a),
              )),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.recentActivity,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 14),
          _ActivityItem(
            time: AppStrings.minutesAgo,
            title: AppStrings.intrusionAlertZoneB,
            subtitle: AppStrings.rearDoorSensorTriggered,
            isAlert: true,
          ),
          _ActivityItem(
            time: '10:45',
            title: AppStrings.controlRoundCompleted,
            subtitle: AppStrings.northSectorVerified,
            isAlert: false,
          ),
          _ActivityItem(
            time: '09:00',
            title: AppStrings.serviceStartDayTeam,
            subtitle: null,
            isAlert: false,
          ),
        ],
      ),
    );
  }

  Widget _buildReportIncidentButton(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ClientDetailedAlertScreen(siteName: siteName),
                ),
              );
            },
            icon: const Icon(Icons.campaign_rounded, size: 24, color: Colors.white),
            label: Text(
              AppStrings.reportIncident,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AgentRow {
  final String name;
  final String role;
  final bool isReporting;

  _AgentRow({required this.name, required this.role, required this.isReporting});
}

class _AgentTile extends StatelessWidget {
  final _AgentRow agent;

  const _AgentTile({required this.agent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: agent.isReporting
                ? AppColors.primaryRed.withValues(alpha: 0.15)
                : const Color(0xFFE0F2FE),
            child: Text(
              agent.name.split(' ').where((e) => e.isNotEmpty).take(2).map((e) => e[0].toUpperCase()).join(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: agent.isReporting ? AppColors.primaryRed : const Color(0xFF0284C7),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  agent.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: agent.isReporting ? AppColors.primaryRed : const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  agent.role,
                  style: TextStyle(
                    fontSize: 13,
                    color: agent.isReporting ? AppColors.primaryRed : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              agent.isReporting ? Icons.record_voice_over_rounded : Icons.phone_rounded,
              color: agent.isReporting ? AppColors.primaryRed : const Color(0xFF374151),
              size: 24,
            ),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final String time;
  final String title;
  final String? subtitle;
  final bool isAlert;

  const _ActivityItem({
    required this.time,
    required this.title,
    this.subtitle,
    required this.isAlert,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 52,
            child: Text(
              time,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isAlert ? AppColors.primaryRed : const Color(0xFF111827),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
