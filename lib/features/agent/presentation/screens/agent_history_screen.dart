import 'package:flutter/material.dart';

import '../../../../core/app_strings.dart';
import '../../../../core/auth/session_storage.dart';
import '../../../../core/offline/offline_patrol_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/alert_model.dart';
import '../../data/models/intervention_model.dart';
import '../../data/models/patrol_model.dart';
import '../widgets/agent_bottom_nav_bar.dart';
import 'agent_intervention_detail_screen.dart';

import '../../../../core/network/api_config.dart';
import '../../../../core/network/services/alert_api_service.dart';
import '../../../../core/network/services/intervention_api_service.dart';
import '../../../../core/network/services/report_api_service.dart';

/// Données d'un élément d'historique (liste + détail).
class HistoryItemData {
  final String id;
  final HistoryType type;
  final String title;
  final String site;
  final String? startDateTime;
  final String? endDateTime;
  final String? dateTime;
  final String statusLabel;
  final String? observation;
  final bool hasPhoto;
  final bool hasLocation;
  final DateTime? sortDate;

  HistoryItemData({
    required this.id,
    required this.type,
    required this.title,
    required this.site,
    this.startDateTime,
    this.endDateTime,
    this.dateTime,
    String? statusLabel,
    this.observation,
    this.hasPhoto = false,
    this.hasLocation = false,
    this.sortDate,
  }) : statusLabel = statusLabel ?? AppStrings.statusOk;
}

enum HistoryType { patrol, checkin, intervention, alert }

String _formatDate(DateTime d) {
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} · ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

class AgentHistoryScreen extends StatefulWidget {
  const AgentHistoryScreen({super.key, this.historyScreenBuilder});

  final Widget Function()? historyScreenBuilder;

  @override
  State<AgentHistoryScreen> createState() => _AgentHistoryScreenState();
}

class _AgentHistoryScreenState extends State<AgentHistoryScreen> {
  List<HistoryItemData> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = SessionStorage.getUser();
    if (user == null) {
      if (mounted) setState(() { _items = []; _loading = false; });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final list = <HistoryItemData>[];

    try {
      // Patrouilles terminées (agent = moi)
      final patrols = await OfflinePatrolService.getHistory(agentId: user.id);
      for (final p in patrols) {
        if (p.statut != PatrolStatus.completed) continue;
        final start = p.heureDebut != null ? _formatDate(p.heureDebut!) : null;
        final end = p.heureFin != null ? _formatDate(p.heureFin!) : null;
        list.add(HistoryItemData(
          id: p.id,
          type: HistoryType.patrol,
          title: AppStrings.patrolCompletedTitle,
          site: p.siteId ?? AppStrings.siteA,
          startDateTime: start,
          endDateTime: end,
          statusLabel: p.statut.label,
          sortDate: p.heureFin ?? p.heureDebut ?? p.createdAt,
        ));
      }

      // Interventions où l'utilisateur est assigné (agents_envoyes)
      final interventions = await InterventionApiService.getHistory();
      for (final i in interventions) {
        if (!i.agentIds.contains(user.id)) continue;
        final dt = i.createdAt ?? i.heureDepart ?? i.heureArrivee;
        list.add(HistoryItemData(
          id: i.id,
          type: HistoryType.intervention,
          title: '${i.type.label} • ${i.statut.label}',
          site: i.hasLocation ? '${i.latitude?.toStringAsFixed(4)}, ${i.longitude?.toStringAsFixed(4)}' : '—',
          dateTime: dt != null ? _formatDate(dt) : null,
          statusLabel: i.statut.label,
          sortDate: dt,
        ));
      }

      // Alertes (historique de l'utilisateur)
      final alerts = await AlertApiService.getHistory();
      for (final a in alerts) {
        list.add(HistoryItemData(
          id: a.id,
          type: HistoryType.alert,
          title: 'Alerte ${a.type.value}',
          site: a.hasLocation ? '${a.latitude?.toStringAsFixed(4)}, ${a.longitude?.toStringAsFixed(4)}' : '—',
          dateTime: a.createdAt != null ? _formatDate(a.createdAt!) : null,
          statusLabel: a.statut.label,
          observation: a.source,
          hasLocation: a.hasLocation,
          sortDate: a.createdAt,
        ));
      }

      list.sort((a, b) {
        final da = a.sortDate ?? DateTime(0);
        final db = b.sortDate ?? DateTime(0);
        return db.compareTo(da);
      });

      if (mounted) setState(() { _items = list; _loading = false; _error = null; });
    } catch (e) {
      if (mounted) setState(() {
        _loading = false;
        _error = e is Exception ? e.toString().replaceFirst('Exception: ', '') : '$e';
        _items = [];
      });
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
          AppStrings.history,
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _error!,
                          style: const TextStyle(color: Color(0xFF6B7280)),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                )
                  : _items.isEmpty
                  ? Center(
                      child: Text(
                        'Aucun historique (patrouilles terminées, interventions, alertes).',
                        style: const TextStyle(fontSize: 15, color: Color(0xFF6B7280)),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.primaryRed,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          return _HistoryCard(
                            item: item,
                            onTap: () {
                              if (item.type == HistoryType.intervention) {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => AgentInterventionDetailScreen(
                                      interventionId: item.id,
                                    ),
                                  ),
                                );
                              } else {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => AgentHistoryDetailScreen(
                                      item: item,
                                      historyScreenBuilder: widget.historyScreenBuilder,
                                    ),
                                  ),
                                );
                              }
                            },
                          );
                        },
                      ),
                    ),
      bottomNavigationBar: AgentBottomNavBar(
        currentIndex: 2,
        isHistoryDetail: false,
        historyScreenBuilder: widget.historyScreenBuilder,
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final HistoryItemData item;
  final VoidCallback onTap;

  const _HistoryCard({required this.item, required this.onTap});

  IconData _iconForType() {
    switch (item.type) {
      case HistoryType.patrol:
        return Icons.directions_walk_rounded;
      case HistoryType.checkin:
        return Icons.qr_code_scanner_rounded;
      case HistoryType.intervention:
        return Icons.warning_amber_rounded;
      case HistoryType.alert:
        return Icons.notification_important_rounded;
    }
  }

  Color _iconColorForType() {
    switch (item.type) {
      case HistoryType.patrol:
        return AppColors.primaryRed;
      case HistoryType.checkin:
        return const Color(0xFF3B82F6);
      case HistoryType.intervention:
        return const Color(0xFFF97316);
      case HistoryType.alert:
        return const Color(0xFFDC2626);
    }
  }

  String _subtitle() {
    if (item.startDateTime != null && item.endDateTime != null) {
      return 'De ${item.startDateTime!.split(' · ').last} à ${item.endDateTime!.split(' · ').last}';
    }
    if (item.dateTime != null) {
      return item.dateTime!;
    }
    return item.site;
  }

  @override
  Widget build(BuildContext context) {
    final icon = _iconForType();
    final iconColor = _iconColorForType();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${AppStrings.locationLabel} : ${item.site}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _subtitle(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF111827),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.statusLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF16A34A),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF9CA3AF),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Écran de détail d'un élément d'historique.
/// Pour une patrouille terminée, charge et affiche le rapport lié (GET /api/reports/patrol?patrol_id=...).
class AgentHistoryDetailScreen extends StatefulWidget {
  final HistoryItemData item;
  final Widget Function()? historyScreenBuilder;

  const AgentHistoryDetailScreen({
    super.key,
    required this.item,
    this.historyScreenBuilder,
  });

  @override
  State<AgentHistoryDetailScreen> createState() => _AgentHistoryDetailScreenState();
}

class _AgentHistoryDetailScreenState extends State<AgentHistoryDetailScreen> {
  ReportModel? _linkedReport;
  bool _reportLoading = false;
  String? _reportError;

  @override
  void initState() {
    super.initState();
    if (widget.item.type == HistoryType.patrol) _loadPatrolReport();
  }

  Future<void> _loadPatrolReport() async {
    setState(() {
      _reportLoading = true;
      _reportError = null;
    });
    try {
      final list = await ReportApiService.getPatrolReports(patrolId: widget.item.id);
      if (mounted) {
        setState(() {
          _reportLoading = false;
          _linkedReport = list.isNotEmpty ? list.first : null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _reportLoading = false;
          _reportError = e is Exception ? e.toString().replaceFirst('Exception: ', '') : '$e';
        });
      }
    }
  }

  IconData _iconForType() {
    switch (widget.item.type) {
      case HistoryType.patrol:
        return Icons.directions_walk_rounded;
      case HistoryType.checkin:
        return Icons.qr_code_scanner_rounded;
      case HistoryType.intervention:
        return Icons.warning_amber_rounded;
      case HistoryType.alert:
        return Icons.notification_important_rounded;
    }
  }

  Color _iconColorForType() {
    switch (widget.item.type) {
      case HistoryType.patrol:
        return AppColors.primaryRed;
      case HistoryType.checkin:
        return const Color(0xFF3B82F6);
      case HistoryType.intervention:
        return const Color(0xFFF97316);
      case HistoryType.alert:
        return const Color(0xFFDC2626);
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = _iconColorForType();
    final item = widget.item;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black87,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          AppStrings.detail,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailBlock(
              icon: _iconForType(),
              iconColor: iconColor,
              title: item.title,
              statusLabel: item.statusLabel,
            ),
            const SizedBox(height: 20),
            _InfoRow(label: AppStrings.location, value: item.site),
            if (item.startDateTime != null && item.endDateTime != null) ...[
              const SizedBox(height: 12),
              _InfoRow(label: AppStrings.start, value: item.startDateTime!),
              const SizedBox(height: 12),
              _InfoRow(label: AppStrings.end, value: item.endDateTime!),
            ] else if (item.dateTime != null) ...[
              const SizedBox(height: 12),
              _InfoRow(label: AppStrings.dateTime, value: item.dateTime!),
            ],
            // Pour patrouille terminée : bloc rapport lié (observations, anomalies, résumé, actions, photos)
            if (item.type == HistoryType.patrol) ...[
              const SizedBox(height: 20),
              _buildLinkedReportSection(),
            ],
            if (item.observation != null && item.observation!.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                AppStrings.observation,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  item.observation!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF111827),
                    height: 1.4,
                  ),
                ),
              ),
            ],
            if (item.hasPhoto || item.hasLocation) ...[
              const SizedBox(height: 20),
              Text(
                AppStrings.associatedItems,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              if (item.hasPhoto)
                _AttachmentTile(
                  icon: Icons.camera_alt_outlined,
                  title: AppStrings.photoDeService,
                  subtitle: AppStrings.onePhotoTaken,
                  kind: _AttachmentKind.photo,
                ),
              if (item.hasPhoto && item.hasLocation)
                const SizedBox(height: 8),
              if (item.hasLocation)
                _AttachmentTile(
                  icon: Icons.location_on_outlined,
                  title: AppStrings.geolocation,
                  subtitle: AppStrings.gpsPositionRecorded,
                  kind: _AttachmentKind.location,
                ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: AgentBottomNavBar(
        currentIndex: 2,
        isHistoryDetail: true,
        historyScreenBuilder: widget.historyScreenBuilder,
      ),
    );
  }

  Widget _buildLinkedReportSection() {
    if (_reportLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (_reportError != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          _reportError!,
          style: const TextStyle(fontSize: 14, color: Color(0xFFDC2626)),
        ),
      );
    }
    final r = _linkedReport;
    if (r == null) {
      return const SizedBox.shrink();
    }
    final sectionStyle = const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: Color(0xFF6B7280),
      letterSpacing: 0.5,
    );
    final boxDecoration = BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
    final children = <Widget>[
      Text(
        AppStrings.reportRecorded,
        style: sectionStyle,
      ),
      const SizedBox(height: 8),
    ];
    if (r.observations != null && r.observations!.isNotEmpty) {
      children.addAll([
        Text(AppStrings.observation, style: sectionStyle),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: boxDecoration,
          child: Text(
            r.observations!,
            style: const TextStyle(fontSize: 14, color: Color(0xFF111827), height: 1.4),
          ),
        ),
        const SizedBox(height: 14),
      ]);
    }
    if (r.anomalies.isNotEmpty) {
      children.addAll([
        Text(AppStrings.anomaliesList, style: sectionStyle),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: boxDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: r.anomalies.map((a) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('• $a', style: const TextStyle(fontSize: 14, color: Color(0xFF111827), height: 1.4)),
            )).toList(),
          ),
        ),
        const SizedBox(height: 14),
      ]);
    }
    if (r.resume != null && r.resume!.isNotEmpty) {
      children.addAll([
        Text(AppStrings.reportResume, style: sectionStyle),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: boxDecoration,
          child: Text(
            r.resume!,
            style: const TextStyle(fontSize: 14, color: Color(0xFF111827), height: 1.4),
          ),
        ),
        const SizedBox(height: 14),
      ]);
    }
    if (r.actions != null && r.actions!.isNotEmpty) {
      children.addAll([
        Text(AppStrings.reportActions, style: sectionStyle),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: boxDecoration,
          child: Text(
            r.actions!,
            style: const TextStyle(fontSize: 14, color: Color(0xFF111827), height: 1.4),
          ),
        ),
        const SizedBox(height: 14),
      ]);
    }
    if (r.tempsReaction != null) {
      children.addAll([
        Text(AppStrings.tempsReaction, style: sectionStyle),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: boxDecoration,
          child: Text(
            '${r.tempsReaction} min',
            style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
          ),
        ),
        const SizedBox(height: 14),
      ]);
    }
    if (r.degats != null && r.degats!.isNotEmpty) {
      children.addAll([
        Text(AppStrings.reportDegats, style: sectionStyle),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: boxDecoration,
          child: Text(
            r.degats!,
            style: const TextStyle(fontSize: 14, color: Color(0xFF111827), height: 1.4),
          ),
        ),
        const SizedBox(height: 14),
      ]);
    }
    if (r.photos.isNotEmpty) {
      children.addAll([
        Text(AppStrings.photoDeService, style: sectionStyle),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: r.photos.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final url = ApiConfig.uploadsUrl(r.photos[i]);
              if (url.isEmpty) return const SizedBox.shrink();
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  url,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 100,
                    height: 100,
                    color: const Color(0xFFE5E7EB),
                    child: const Icon(Icons.broken_image_outlined),
                  ),
                ),
              );
            },
          ),
        ),
      ]);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}

class _DetailBlock extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String statusLabel;

  const _DetailBlock({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.statusLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              statusLabel,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF16A34A),
              ),
            ),
          ),
        ],
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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

enum _AttachmentKind { photo, location }

class _AttachmentTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final _AttachmentKind kind;

  _AttachmentTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.kind,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          final message = kind == _AttachmentKind.photo
              ? 'Prévisualisation de la photo à brancher (stockage / caméra).'
              : 'Ouverture de la carte à brancher (GPS / map).';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
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
                  color: Color(0xFFE5E7EB),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
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
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF9CA3AF),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

