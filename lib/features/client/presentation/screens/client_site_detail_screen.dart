import 'package:flutter/material.dart';

import '../../../../core/app_strings.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/network/services/intervention_api_service.dart';
import '../../../../core/network/services/patrol_api_service.dart';
import '../../../../core/network/services/site_api_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../agent/data/models/intervention_model.dart';
import '../../../agent/data/models/patrol_model.dart';
import '../../../agent/data/models/site_model.dart';
import '../../../auth/data/models/user_model.dart';
import 'client_contact_security_screen.dart';
import 'client_detailed_alert_screen.dart';

/// Écran détail d'un site : infos complètes, agents affectés, patrouilles et interventions du site.
class ClientSiteDetailScreen extends StatefulWidget {
  final String? siteId;
  final String siteName;
  final String siteLocation;

  const ClientSiteDetailScreen({
    super.key,
    this.siteId,
    required this.siteName,
    required this.siteLocation,
  });

  @override
  State<ClientSiteDetailScreen> createState() => _ClientSiteDetailScreenState();
}

class _ClientSiteDetailScreenState extends State<ClientSiteDetailScreen> {
  SiteModel? _site;
  List<UserModel> _agents = [];
  List<PatrolModel> _patrols = [];
  List<InterventionModel> _interventions = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final siteId = widget.siteId;
    if (siteId == null || siteId.isEmpty) {
      setState(() {
        _loading = false;
        _site = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        SiteApiService.getById(siteId),
        SiteApiService.getSiteAgents(siteId),
        PatrolApiService.getHistory(siteId: siteId),
        InterventionApiService.getHistory(siteId: siteId),
      ]);
      final site = results[0] as SiteModel?;
      final agents = results[1] as List<UserModel>;
      final patrols = results[2] as List<PatrolModel>;
      final interventions = results[3] as List<InterventionModel>;
      if (mounted) {
        setState(() {
          _site = site;
          _agents = agents;
          _patrols = patrols;
          _interventions = interventions;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e is Exception ? e.toString().replaceFirst('Exception: ', '') : '$e';
        });
      }
    }
  }

  String get _displayName => _site?.name ?? widget.siteName;
  String get _displayLocation =>
      _site?.description ?? widget.siteLocation;

  String _riskLabel(String? niveau) {
    if (niveau == null) return '—';
    switch (niveau.toUpperCase()) {
      case 'HIGH':
        return 'Élevé';
      case 'MEDIUM':
        return 'Moyen';
      case 'LOW':
      default:
        return 'Faible';
    }
  }

  static String _formatDate(DateTime? d) {
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} · ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

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
              _displayName,
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
          if (_loading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primaryRed),
              ),
            )
          else if (_error != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      _error!,
                      style: const TextStyle(fontSize: 14, color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(AppStrings.refresh),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverToBoxAdapter(
              child: RefreshIndicator(
                onRefresh: _load,
                color: AppColors.primaryRed,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSiteInfo(),
                      const SizedBox(height: 20),
                      _buildAgentsSection(),
                      const SizedBox(height: 20),
                      _buildPatrolsSection(),
                      const SizedBox(height: 20),
                      _buildInterventionsSection(),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _buildReportIncidentButton(context),
    );
  }

  Widget _buildSiteInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_displayLocation.isNotEmpty) ...[
            Text(
              AppStrings.description,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _displayLocation,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF111827),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
          ],
          Row(
            children: [
              Text(
                'Niveau de risque',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _site?.niveauRisque.toUpperCase() == 'HIGH'
                      ? AppColors.primaryRed.withValues(alpha: 0.12)
                      : _site?.niveauRisque.toUpperCase() == 'MEDIUM'
                          ? Colors.orange.shade100
                          : const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _riskLabel(_site?.niveauRisque),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _site?.niveauRisque.toUpperCase() == 'HIGH'
                        ? AppColors.primaryRed
                        : _site?.niveauRisque.toUpperCase() == 'MEDIUM'
                            ? Colors.orange.shade800
                            : const Color(0xFF059669),
                  ),
                ),
              ),
            ],
          ),
          if (_site?.hasLocation == true) ...[
            const SizedBox(height: 10),
            Text(
              '${_site!.latitude!.toStringAsFixed(4)}, ${_site!.longitude!.toStringAsFixed(4)}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAgentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              AppStrings.agentsOnSite,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF374151),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                AppStrings.activeCount(_agents.length),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_agents.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
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
            child: Text(
              'Aucun agent affecté à ce site',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
          )
        else
          ..._agents.map(
            (agent) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AgentTile(
                name: agent.fullName,
                role: agent.role,
                photoUrl: agent.photoProfil,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPatrolsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.patrols,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 12),
        if (_patrols.isEmpty)
          _EmptyCard(text: AppStrings.noPatrols)
        else
          ..._patrols.take(10).map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ActivityCard(
                    time: _formatDate(p.heureFin ?? p.heureDebut ?? p.createdAt),
                    title: '${p.statut.label}',
                    subtitle: p.heureDebut != null
                        ? '${AppStrings.start} ${_formatDate(p.heureDebut)}'
                        : null,
                    isAlert: false,
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildInterventionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.interventions,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 12),
        if (_interventions.isEmpty)
          _EmptyCard(text: AppStrings.noInterventions)
        else
          ..._interventions.take(10).map(
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ActivityCard(
                    time: _formatDate(i.createdAt ?? i.heureDepart ?? i.heureArrivee),
                    title: i.displayTitle,
                    subtitle: i.hasLocation
                        ? '${i.latitude!.toStringAsFixed(4)}, ${i.longitude!.toStringAsFixed(4)}'
                        : null,
                    isAlert: i.isOpen || i.isInProgress,
                  ),
                ),
              ),
      ],
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
            builder: (_) => ClientDetailedAlertScreen(
              siteId: widget.siteId,
              siteName: _displayName,
            ),
          ),
        );
        break;
      case 'refresh':
        _load();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStrings.refreshed)),
          );
        }
        break;
    }
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
                  builder: (_) => ClientDetailedAlertScreen(
                    siteId: widget.siteId,
                    siteName: _displayName,
                  ),
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

class _AgentTile extends StatelessWidget {
  final String name;
  final String role;
  final String? photoUrl;

  const _AgentTile({
    required this.name,
    required this.role,
    this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final initials = name
        .split(' ')
        .where((e) => e.isNotEmpty)
        .take(2)
        .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
        .join();
    final url = ApiConfig.uploadsUrl(photoUrl);
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
            backgroundColor: const Color(0xFFE0F2FE),
            backgroundImage: url.isNotEmpty
                ? NetworkImage(url)
                : null,
            child: url.isEmpty
                ? Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0284C7),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  role,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.phone_rounded,
            color: Colors.grey.shade600,
            size: 24,
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String text;

  const _EmptyCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF6B7280),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final String time;
  final String title;
  final String? subtitle;
  final bool isAlert;

  const _ActivityCard({
    required this.time,
    required this.title,
    this.subtitle,
    required this.isAlert,
  });

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 52,
            child: Text(
              time,
              style: const TextStyle(
                fontSize: 12,
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
                if (subtitle != null && subtitle!.isNotEmpty) ...[
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
