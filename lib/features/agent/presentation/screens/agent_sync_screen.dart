import 'package:flutter/material.dart';

import '../../../../core/app_strings.dart';
import '../../../../core/theme/app_colors.dart';

class AgentSyncScreen extends StatefulWidget {
  const AgentSyncScreen({super.key, this.bottomNavigationBar});

  /// Barre de navigation à afficher en bas quand l'écran est ouvert depuis l'onglet Synchro.
  final Widget? bottomNavigationBar;

  @override
  State<AgentSyncScreen> createState() => _AgentSyncScreenState();
}

class _AgentSyncScreenState extends State<AgentSyncScreen> {
  late Map<String, bool> _selected;

  List<_SyncCategory> get _categories => [
    _SyncCategory(
      id: 'reports',
      title: AppStrings.anomalyReports,
      subtitle: AppStrings.criticalData,
      count: 12,
    ),
    _SyncCategory(
      id: 'checkins',
      title: AppStrings.checkins,
      subtitle: AppStrings.validatedLocations,
      count: 20,
    ),
    _SyncCategory(
      id: 'patrols',
      title: AppStrings.patrols,
      subtitle: AppStrings.movementLogs,
      count: 5,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selected = {'reports': true, 'checkins': true, 'patrols': true};
  }

  int get _totalCount =>
      _categories.fold(0, (sum, c) => sum + c.count);

  int get _selectedCount {
    int total = 0;
    for (final c in _categories) {
      if (_selected[c.id] == true) {
        total += c.count;
      }
    }
    return total;
  }

  bool get _allSelected =>
      _selected.values.every((v) => v == true);

  void _toggleAll() {
    final newValue = !_allSelected;
    setState(() {
      _selected.updateAll((key, value) => newValue);
    });
  }

  void _toggleOne(String id) {
    setState(() {
      _selected[id] = !(_selected[id] ?? false);
    });
  }

  void _openDetails(_SyncCategory category) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AgentSyncDetailsScreen(category: category),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = _totalCount;
    final selectedCount = _selectedCount;

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
          AppStrings.sync,
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
                  '$total ${AppStrings.itemsPending}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 16,
                      color: Color(0xFF9CA3AF),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      AppStrings.lastSyncToday,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                          padding: const EdgeInsets.fromLTRB(
                              16, 14, 16, 8),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
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
                              GestureDetector(
                                onTap: _toggleAll,
                                child: Text(
                                  _allSelected
                                      ? AppStrings.deselectAllLabel
                                      : AppStrings.selectAllLabel,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryRed,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(
                          height: 1,
                          thickness: 0.8,
                          color: Color(0xFFE5E7EB),
                        ),
                        ..._categories.map(
                          (c) => _SyncCategoryTile(
                            category: c,
                            selected: _selected[c.id] ?? false,
                            onToggleSelected: () => _toggleOne(c.id),
                            onOpenDetails: () => _openDetails(c),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.syncDisclaimer,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: selectedCount == 0
                          ? null
                          : () => _showSyncDialog(
                                context: context,
                                selectedCount: selectedCount,
                                totalCount: total,
                                allSelected: selectedCount == total,
                              ),
                      icon: const Icon(Icons.cloud_upload_rounded, size: 20),
                      label: Text(AppStrings.syncAllLabel),
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
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: selectedCount == 0
                          ? null
                          : () => _showSyncDialog(
                                context: context,
                                selectedCount: selectedCount,
                                totalCount: total,
                                allSelected: selectedCount == total,
                              ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: selectedCount == 0
                            ? const Color(0xFF9CA3AF)
                            : AppColors.primaryRed,
                        side: BorderSide(
                          color: selectedCount == 0
                              ? const Color(0xFFD1D5DB)
                              : AppColors.primaryRed,
                          width: 2,
                        ),
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
                        '${AppStrings.syncSelectionLabel} ($selectedCount)',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (widget.bottomNavigationBar != null) widget.bottomNavigationBar!,
        ],
      ),
    );
  }
}

class _SyncCategory {
  final String id;
  final String title;
  final String subtitle;
  final int count;

  _SyncCategory({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.count,
  });
}

class _SyncCategoryTile extends StatelessWidget {
  final _SyncCategory category;
  final bool selected;
  final VoidCallback onToggleSelected;
  final VoidCallback onOpenDetails;

  const _SyncCategoryTile({
    required this.category,
    required this.selected,
    required this.onToggleSelected,
    required this.onOpenDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggleSelected,
            behavior: HitTestBehavior.opaque,
            child: _SyncCheckbox(selected: selected),
          ),
          const SizedBox(width: 12),
          Expanded(
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
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
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: Color(0xFF9CA3AF),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AgentSyncDetailsScreen extends StatelessWidget {
  final _SyncCategory category;

  const AgentSyncDetailsScreen({super.key, required this.category});

  IconData _iconForCategory() {
    switch (category.id) {
      case 'reports':
        return Icons.description_outlined;
      case 'checkins':
        return Icons.location_pin;
      case 'patrols':
        return Icons.directions_walk_rounded;
      default:
        return Icons.insert_drive_file_outlined;
    }
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
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black87,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          category.title,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: category.count,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final number = index + 1;
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
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
                        '${category.title} #$number',
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
                const SizedBox(width: 8),
                const Icon(
                  Icons.cloud_upload_rounded,
                  size: 18,
                  color: Color(0xFF9CA3AF),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SyncCheckbox extends StatelessWidget {
  final bool selected;

  const _SyncCheckbox({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color:
              selected ? AppColors.primaryRed : const Color(0xFFD4D4D8),
          width: 2,
        ),
        color:
            selected ? AppColors.primaryRed : Colors.transparent,
      ),
      child: selected
          ? const Icon(
              Icons.check,
              size: 14,
              color: Colors.white,
            )
          : null,
    );
  }
}

void _showSyncDialog({
  required BuildContext context,
  required int selectedCount,
  required int totalCount,
  required bool allSelected,
}) {
  showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'sync-success',
    barrierColor: Colors.black.withOpacity(0.45),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return const SizedBox.shrink();
    },
    transitionBuilder:
        (dialogContext, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInBack,
      );

      Future.delayed(const Duration(milliseconds: 1500), () {
        if (Navigator.of(dialogContext).canPop()) {
          Navigator.of(dialogContext).pop();
        }
      });

      final String title =
          allSelected ? AppStrings.syncCompleteTitle : AppStrings.syncPartialTitle;
      final String message = allSelected
          ? AppStrings.syncCompleteMessage(totalCount)
          : AppStrings.syncPartialMessage(selectedCount, totalCount);

      return FadeTransition(
        opacity: animation,
        child: Center(
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(curved),
            child: Material(
              color: Colors.transparent,
              child: Container(
                width:
                    MediaQuery.of(dialogContext).size.width * 0.78,
                padding:
                    const EdgeInsets.fromLTRB(20, 28, 20, 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircleAvatar(
                      radius: 32,
                      backgroundColor: AppColors.primaryRed,
                      child: Icon(
                        Icons.cloud_done_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF4B5563),
                      ),
                      textAlign: TextAlign.center,
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

