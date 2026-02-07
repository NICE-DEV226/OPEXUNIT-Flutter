import 'package:flutter/material.dart';

import '../../../../core/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/agent_bottom_nav_bar.dart';

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
  }) : statusLabel = statusLabel ?? AppStrings.statusOk;
}

enum HistoryType { patrol, checkin, intervention }

class AgentHistoryScreen extends StatelessWidget {
  const AgentHistoryScreen({super.key, this.historyScreenBuilder});

  /// Fourni pour que la navbar (Accueil, Synchro, Historique, Profil) fonctionne depuis cet écran.
  final Widget Function()? historyScreenBuilder;

  static List<HistoryItemData> get _items => [
        HistoryItemData(
          id: '1',
          type: HistoryType.patrol,
          title: AppStrings.patrolCompletedTitle,
          site: AppStrings.siteA,
          startDateTime: '${AppStrings.thursday12Jan2022} · 14:30',
          endDateTime: '${AppStrings.thursday12Jan2022} · 15:45',
          statusLabel: AppStrings.statusOk,
          observation: AppStrings.routinePatrolNoIncident,
          hasPhoto: true,
          hasLocation: true,
        ),
        HistoryItemData(
          id: '2',
          type: HistoryType.checkin,
          title: AppStrings.checkinStartTitle,
          site: AppStrings.siteA,
          dateTime: '${AppStrings.thursday12Jan2022} · 08:45',
          statusLabel: AppStrings.statusOk,
          observation: AppStrings.controlPointNorth,
          hasPhoto: true,
          hasLocation: true,
        ),
        HistoryItemData(
          id: '3',
          type: HistoryType.intervention,
          title: AppStrings.intervention,
          site: AppStrings.siteA,
          dateTime: '${AppStrings.thursday12Jan2022} · 10:20',
          statusLabel: AppStrings.statusOk,
          observation: AppStrings.alarmCheckFalseAlert,
          hasPhoto: true,
        ),
      ];

  @override
  Widget build(BuildContext context) {
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
          AppStrings.history,
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = _items[index];
            return _HistoryCard(
            item: item,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => AgentHistoryDetailScreen(
                    item: item,
                    historyScreenBuilder: historyScreenBuilder,
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: AgentBottomNavBar(
        currentIndex: 2,
        isHistoryDetail: false,
        historyScreenBuilder: historyScreenBuilder,
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
class AgentHistoryDetailScreen extends StatelessWidget {
  final HistoryItemData item;
  final Widget Function()? historyScreenBuilder;

  const AgentHistoryDetailScreen({
    super.key,
    required this.item,
    this.historyScreenBuilder,
  });

  IconData _iconForType() {
    switch (item.type) {
      case HistoryType.patrol:
        return Icons.directions_walk_rounded;
      case HistoryType.checkin:
        return Icons.qr_code_scanner_rounded;
      case HistoryType.intervention:
        return Icons.warning_amber_rounded;
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = _iconColorForType();

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
          style: TextStyle(
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
        historyScreenBuilder: historyScreenBuilder,
      ),
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

