import 'package:flutter/material.dart';

import '../../../../core/app_strings.dart';
import '../../../../core/offline/connectivity_service.dart';
import '../../../../core/offline/offline_storage.dart';
import '../../../../core/offline/sync_service.dart';
import '../../../../core/theme/app_colors.dart';

/// Types d'actions en file (voir [OfflineStorage]).
String _actionTypeLabel(String type) {
  switch (type) {
    case 'patrol_start':
      return 'Début patrouille';
    case 'patrol_checkpoint':
      return 'Point de contrôle';
    case 'patrol_gps':
      return 'Position GPS';
    case 'patrol_end':
      return 'Fin patrouille';
    case 'intervention_close':
      return 'Clôture intervention + rapport';
    case 'alert_trigger':
      return 'Alerte';
    default:
      return type;
  }
}

bool _isPatrolAction(String type) {
  return type == 'patrol_start' ||
      type == 'patrol_checkpoint' ||
      type == 'patrol_gps' ||
      type == 'patrol_end';
}

class AgentSyncScreen extends StatefulWidget {
  const AgentSyncScreen({super.key, this.bottomNavigationBar});

  final Widget? bottomNavigationBar;

  @override
  State<AgentSyncScreen> createState() => _AgentSyncScreenState();
}

class _AgentSyncScreenState extends State<AgentSyncScreen> {
  int _pendingCount = 0;
  List<Map<String, dynamic>> _pendingActions = [];
  bool _syncing = false;
  String? _syncMessage;
  bool _isOnline = true;

  List<_SyncCategory> get _categories {
    final patrols = _pendingActions.where((a) => _isPatrolAction(a['action_type'] as String? ?? '')).toList();
    final alerts = _pendingActions.where((a) => (a['action_type'] as String? ?? '') == 'alert_trigger').toList();
    final list = <_SyncCategory>[];
    if (patrols.isNotEmpty) {
      list.add(_SyncCategory(
        id: 'patrols',
        title: AppStrings.patrols,
        subtitle: 'Début, points de contrôle, positions, fin de ronde',
        count: patrols.length,
        actions: patrols,
      ));
    }
    final interventions = _pendingActions.where((a) => (a['action_type'] as String? ?? '') == 'intervention_close').toList();
    if (interventions.isNotEmpty) {
      list.add(_SyncCategory(
        id: 'interventions',
        title: AppStrings.interventions,
        subtitle: 'Rapports et clôtures d\'intervention',
        count: interventions.length,
        actions: interventions,
      ));
    }
    if (alerts.isNotEmpty) {
      list.add(_SyncCategory(
        id: 'alerts',
        title: AppStrings.alert,
        subtitle: 'Alertes déclenchées hors ligne',
        count: alerts.length,
        actions: alerts,
      ));
    }
    return list;
  }

  @override
  void initState() {
    super.initState();
    _load();
    ConnectivityService.checkOnline().then((online) {
      if (mounted) setState(() => _isOnline = online);
    });
  }

  Future<void> _load() async {
    final n = await SyncService.getPendingCount();
    final list = await OfflineStorage.getPendingActions();
    if (mounted) {
      setState(() {
        _pendingCount = n;
        _pendingActions = list;
      });
    }
  }

  Future<void> _syncNow() async {
    if (_syncing || !_isOnline) return;
    setState(() {
      _syncing = true;
      _syncMessage = null;
    });
    try {
      final online = await ConnectivityService.checkOnline();
      if (!online) {
        if (mounted) setState(() {
          _syncing = false;
          _syncMessage = 'Pas de connexion. Les données seront synchronisées à la reconnexion.';
        });
        return;
      }
      final result = await SyncService.syncPending();
      if (mounted) {
        await _load();
        setState(() {
          _syncing = false;
          if (result.syncedCount > 0) {
            _syncMessage = '${result.syncedCount} élément(s) synchronisé(s).';
            if (result.failedCount > 0) {
              _syncMessage = '$_syncMessage ${result.failedCount} erreur(s).';
            }
            _showResultDialog(synced: result.syncedCount, failed: result.failedCount, error: result.lastError);
          } else if (result.failedCount > 0 && result.lastError != null) {
            _syncMessage = result.lastError;
          } else if (_pendingCount == 0) {
            _syncMessage = 'Aucune donnée en attente.';
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() {
        _syncing = false;
        _syncMessage = e is Exception ? e.toString().replaceFirst('Exception: ', '') : 'Erreur';
      });
    }
  }

  void _showResultDialog({required int synced, int failed = 0, String? error}) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_done_rounded, color: AppColors.primaryRed, size: 48),
            const SizedBox(height: 16),
            Text(
              synced > 0 ? AppStrings.syncCompleteTitle : 'Synchronisation',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              synced > 0
                  ? AppStrings.syncCompleteMessage(synced)
                  : (error ?? 'Aucune donnée synchronisée.'),
              style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              textAlign: TextAlign.center,
            ),
            if (failed > 0) ...[
              const SizedBox(height: 8),
              Text(
                '$failed erreur(s).',
                style: TextStyle(fontSize: 13, color: Colors.orange.shade700),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppStrings.validate),
          ),
        ],
      ),
    );
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
          AppStrings.synchro,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFECACA),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.sync_rounded,
                    color: AppColors.primaryRed,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '$_pendingCount ${AppStrings.itemsPending}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                if (!_isOnline)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_off_rounded, size: 16, color: Colors.orange.shade700),
                        const SizedBox(width: 6),
                        Text(
                          'Hors ligne — synchronisation à la reconnexion',
                          style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                        ),
                      ],
                    ),
                  ),
                if (_syncMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _syncMessage!,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (_pendingCount > 0 && _isOnline)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: ElevatedButton.icon(
                      onPressed: _syncing ? null : _syncNow,
                      icon: _syncing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.sync_rounded, size: 20),
                      label: Text(_syncing ? 'Synchronisation...' : 'Synchroniser maintenant'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                          child: Row(
                            children: [
                              Text(
                                AppStrings.categories,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.6,
                                  color: Color(0xFF9CA3AF),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, thickness: 0.8, color: Color(0xFFE5E7EB)),
                        if (_categories.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'Aucune action en attente',
                              style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
                            ),
                          )
                        else
                          ..._categories.map(
                            (c) => _SyncCategoryTile(
                              category: c,
                              onOpenDetails: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => AgentSyncDetailsScreen(
                                    categoryTitle: c.title,
                                    categoryId: c.id,
                                    actions: c.actions,
                                  ),
                                ),
                              ).then((_) => _load()),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.syncDisclaimer,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: widget.bottomNavigationBar,
    );
  }
}

class _SyncCategory {
  final String id;
  final String title;
  final String subtitle;
  final int count;
  final List<Map<String, dynamic>> actions;

  _SyncCategory({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.count,
    required this.actions,
  });
}

class _SyncCategoryTile extends StatelessWidget {
  final _SyncCategory category;
  final VoidCallback onOpenDetails;

  const _SyncCategoryTile({
    required this.category,
    required this.onOpenDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onOpenDetails,
          borderRadius: BorderRadius.circular(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      category.subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${category.count}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryRed,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF9CA3AF)),
            ],
          ),
        ),
      ),
    );
  }
}

class AgentSyncDetailsScreen extends StatelessWidget {
  final String categoryTitle;
  final String categoryId;
  final List<Map<String, dynamic>> actions;

  const AgentSyncDetailsScreen({
    super.key,
    required this.categoryTitle,
    required this.categoryId,
    required this.actions,
  });

  IconData _iconForCategory() {
    switch (categoryId) {
      case 'patrols':
        return Icons.directions_walk_rounded;
      case 'alerts':
        return Icons.warning_amber_rounded;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  String _formatDate(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final icon = _iconForCategory();

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
          categoryTitle,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: actions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final action = actions[index];
          final type = action['action_type'] as String? ?? '';
          final createdAt = action['created_at'] as int? ?? 0;
          final payload = action['payload'] as Map<String, dynamic>? ?? {};
          final label = _actionTypeLabel(type);
          String subtitle = 'En attente';
          if (payload['patrolId'] != null) subtitle = 'Patrouille ${payload['patrolId']}';
          if (payload['type'] != null && type == 'alert_trigger') subtitle = 'Type: ${payload['type']}';

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
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
                    color: Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: AppColors.primaryRed),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
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
                Text(
                  _formatDate(createdAt),
                  style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.cloud_upload_rounded, size: 18, color: Color(0xFF9CA3AF)),
              ],
            ),
          );
        },
      ),
    );
  }
}
