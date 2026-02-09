import 'package:flutter/material.dart';
import '../../../../core/app_strings.dart';
import '../../../../core/auth/session_storage.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/network/services/auth_api_service.dart';
import '../../../../core/services/gps_tracking_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/screens/login_screen.dart';
// ignore: unused_import — extension PatrolStatusExt.label utilisée via patrol.statut.label
import '../../data/models/patrol_model.dart';
import '../controllers/agent_dashboard_controller.dart';
import '../widgets/agent_bottom_nav_bar.dart';
import 'agent_alert_screen.dart';
import 'agent_checkin_screen.dart';
import 'agent_history_screen.dart';
import 'agent_message_screen.dart';
import 'agent_notifications_screen.dart';
import 'agent_intervention_list_screen.dart';
import 'agent_patrol_in_progress_screen.dart';
import 'agent_patrol_list_screen.dart';
import 'agent_patrol_start_screen.dart';
import 'agent_settings_screen.dart';
import 'agent_sync_screen.dart';

class AgentHomeScreen extends StatelessWidget {
  const AgentHomeScreen({super.key});

  /// Clé pour ouvrir le drawer (menu 3 traits) depuis le leading de l'AppBar.
  static final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// Builder récursif pour que la navbar (Synchro, Historique, Profil) ait toujours
  /// un accès valide à l'écran Historique et puisse naviguer entre tous les onglets.
  static Widget Function()? _historyBuilderCache;
  static Widget Function() get _historyBuilder {
    _historyBuilderCache ??= () => AgentHistoryScreen(
          historyScreenBuilder: _historyBuilder,
        );
    return _historyBuilderCache!;
  }

  static void _showNotificationsPreview(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => _NotificationsPreviewSheet(
        onSeeAll: () {
          Navigator.of(sheetContext).pop();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const AgentNotificationsScreen(),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.black87),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        title: Text(
          AppStrings.homeTitle,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded,
                color: Colors.black87),
            onPressed: () => _showNotificationsPreview(context),
          ),
        ],
      ),
      drawer: Drawer(
        width: 280,
        backgroundColor: Colors.white,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.black87),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: const EdgeInsets.all(8),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.settings_rounded,
                    color: Colors.black87, size: 24),
                title: Text(
                  AppStrings.settings,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop(); // ferme le drawer
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AgentSettingsScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout_rounded,
                    color: AppColors.primaryRed, size: 24),
                title: Text(
                  AppStrings.logout,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryRed,
                  ),
                ),
                onTap: () async {
                  Navigator.of(context).pop(); // ferme le drawer
                  GpsTrackingService.stop();
                  try {
                    await AuthApiService.logout();
                  } catch (_) {}
                  await SessionStorage.clear();
                  if (!context.mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _ResumeGpsTracking(),
            const _AgentHeaderCard(),
            const SizedBox(height: 24),
            const _DashboardSection(),
            const SizedBox(height: 24),
            Center(
              child: Text(
                AppStrings.roundTime,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                '04 : 24 : 15',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _ActionCard(
                    icon: Icons.qr_code_scanner_rounded,
                    title: AppStrings.checkin,
                    subtitle: AppStrings.scanQrNfc,
                    color: const Color(0xFF3B82F6),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AgentCheckinScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionCard(
                    icon: Icons.directions_walk_rounded,
                    title: AppStrings.patrols,
                    subtitle: 'Assignées, en cours, terminées',
                    color: const Color(0xFFEF4444),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AgentPatrolListScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ActionCard(
                    icon: Icons.emergency_rounded,
                    title: AppStrings.interventions,
                    subtitle: 'Assignées, en cours',
                    color: const Color(0xFFF59E0B),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AgentInterventionListScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionCard(
                    icon: Icons.history_rounded,
                    title: AppStrings.history,
                    subtitle: AppStrings.recentActivities,
                    color: const Color(0xFF8B5CF6),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AgentHomeScreen._historyBuilder(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              AppStrings.recentActivities,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _ActivityItem(
              icon: Icons.qr_code_scanner_rounded,
              iconColor: const Color(0xFF3B82F6),
              title: AppStrings.checkinValidated,
              subtitle: AppStrings.siteAPoint,
              time: '10 min',
            ),
            const SizedBox(height: 8),
            _ActivityItem(
              icon: Icons.directions_walk_rounded,
              iconColor: AppColors.primaryRed,
              title: AppStrings.patrolStart,
              subtitle: AppStrings.patrolInProgress,
              time: '25 min',
            ),
            const SizedBox(height: 8),
            _ActivityItem(
              icon: Icons.check_circle_rounded,
              iconColor: const Color(0xFF22C55E),
              title: AppStrings.patrolCompleted,
              subtitle: AppStrings.reportRecorded,
              time: 'Hier',
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      floatingActionButton: Padding(
        // Remonte les boutons flottants pour ne pas les coller à la barre
        padding: const EdgeInsets.only(bottom: 72),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _RoundLabelButton(
              icon: Icons.warning_amber_rounded,
              label: AppStrings.alert,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AgentAlertScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _RoundLabelButton(
              icon: Icons.chat_bubble_outline_rounded,
              label: AppStrings.message,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AgentMessageScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: AgentBottomNavBar(
        currentIndex: 0,
        historyScreenBuilder: _historyBuilder,
      ),
    );
  }
}

/// Widget invisible qui reprend le suivi GPS au chargement de l'accueil agent (si check-in prise de poste actif).
class _ResumeGpsTracking extends StatefulWidget {
  const _ResumeGpsTracking();

  @override
  State<_ResumeGpsTracking> createState() => _ResumeGpsTrackingState();
}

class _ResumeGpsTrackingState extends State<_ResumeGpsTracking> {
  @override
  void initState() {
    super.initState();
    GpsTrackingService.maybeResume();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _AgentHeaderCard extends StatelessWidget {
  const _AgentHeaderCard();

  static String _initials(String? fullName) {
    if (fullName == null || fullName.isEmpty) return '?';
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0].isNotEmpty ? parts[0][0] : ''}${parts[1].isNotEmpty ? parts[1][0] : ''}'.toUpperCase();
    }
    return parts.isNotEmpty && parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
  }

  /// URL complète pour la photo de profil (chemin relatif → baseUrl + path).
  static String _photoUrlOf(dynamic user) {
    if (user == null) return '';
    final path = user.photoProfil as String?;
    return ApiConfig.uploadsUrl(path);
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionStorage.getUser();
    final displayName = user?.fullName ?? 'Agent';
    final matricule = user?.matricule ?? '';
    final initials = _initials(user?.fullName);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: const Color(0xFFE5E7EB),
            backgroundImage: _photoUrlOf(user).isNotEmpty
                ? NetworkImage(_photoUrlOf(user))
                : null,
            child: _photoUrlOf(user).isEmpty
                ? Text(
                    initials,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4B5563),
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
                  displayName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  matricule.isNotEmpty ? 'ID: $matricule' : 'Agent',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _PillBadge(
                label: AppStrings.synchro,
                color: AppColors.primaryRed,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AgentSyncScreen(
                        bottomNavigationBar: AgentBottomNavBar(
                          currentIndex: 1,
                          historyScreenBuilder: AgentHomeScreen._historyBuilder,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 6),
              _PillBadge(
                label: AppStrings.serviceActive,
                color: const Color(0xFF16A34A),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Section unique : patrouille + intervention, alimentée par GET user/me (dashboard).
class _DashboardSection extends StatefulWidget {
  const _DashboardSection();

  @override
  State<_DashboardSection> createState() => _DashboardSectionState();
}

class _DashboardSectionState extends State<_DashboardSection> {
  final AgentDashboardController _dashboardController =
      AgentDashboardController.instance;

  @override
  void initState() {
    super.initState();
    _dashboardController.loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _dashboardController,
      builder: (context, _) {
        final isLoading = _dashboardController.isLoading;
        final patrol = _dashboardController.currentPatrol;
        final hasPatrol = _dashboardController.hasPatrol;
        final hasIntervention = _dashboardController.hasIntervention;
        final errorMessage = _dashboardController.errorMessage;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isLoading && patrol == null && !hasIntervention)
              _buildLoadingCard()
            else ...[
              if (hasPatrol && patrol != null) _buildPatrolCard(context, patrol),
              if (!hasPatrol)
                _buildNoPatrolCard(errorMessage),
            if (hasPatrol && patrol != null) const SizedBox(height: 12),
            if (hasIntervention) ...[
              _buildInterventionCard(context),
              const SizedBox(height: 12),
            ],
            ],
          ],
        );
      },
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildNoPatrolCard(String? errorMessage) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.directions_walk_rounded,
                    color: AppColors.primaryRed),
              ),
              const SizedBox(width: 12),
              Text(
                AppStrings.patrolAssigned,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.onePatrolAtATime,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
            ),
          ),
          if (errorMessage != null && errorMessage.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: TextStyle(
                fontSize: 12,
                color: Colors.red.shade700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPatrolCard(BuildContext context, dynamic patrol) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: patrol.isOngoing
                      ? const Color(0xFF22C55E).withOpacity(0.12)
                      : AppColors.primaryRed.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.directions_walk_rounded,
                  color: patrol.isOngoing
                      ? const Color(0xFF22C55E)
                      : AppColors.primaryRed,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.patrolAssigned,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      (patrol.statut as PatrolStatus).label,
                      style: TextStyle(
                        fontSize: 12,
                        color: patrol.isOngoing
                            ? const Color(0xFF22C55E)
                            : const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _dashboardController.isLoading
                  ? null
                  : () async {
                      if (patrol.canStart) {
                        final updated = await _dashboardController
                            .startPatrol(patrol.id);
                        if (context.mounted && updated != null) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AgentPatrolStartScreen(
                                  patrolId: patrol.id),
                            ),
                          );
                        }
                      } else if (patrol.isOngoing) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AgentPatrolInProgressScreen(
                                patrolId: patrol.id),
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: patrol.isOngoing
                    ? const Color(0xFF22C55E)
                    : AppColors.primaryRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.play_arrow_rounded, size: 20),
              label: Text(
                patrol.canStart
                    ? AppStrings.startAction
                    : AppStrings.continue_,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterventionCard(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const AgentInterventionListScreen(),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(0xFFF59E0B).withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFF59E0B),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Color(0xFFF59E0B).withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emergency_rounded,
                  color: Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.intervention,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Vous avez une intervention assignée',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFF59E0B),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PillBadge extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _PillBadge({
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    if (onTap == null) {
      return badge;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: badge,
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
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
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String time;

  const _ActivityItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
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
          Text(
            time,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundLabelButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _RoundLabelButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.primaryRed,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryRed,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet : dernières notifications + lien "Voir tout" vers la page complète.
class _NotificationsPreviewSheet extends StatelessWidget {
  final VoidCallback onSeeAll;

  const _NotificationsPreviewSheet({required this.onSeeAll});

  static const List<({String title, String subtitle, String time, IconData icon, Color color})> _lastNotifications = [
    (title: 'Ronde validée', subtitle: 'Site A · Point de contrôle', time: '10 min', icon: Icons.check_circle_rounded, color: Color(0xFF22C55E)),
    (title: 'Rappel patrouille', subtitle: 'Prochaine ronde à 14h', time: '25 min', icon: Icons.directions_walk_rounded, color: AppColors.primaryRed),
    (title: 'Message reçu', subtitle: 'Centre de contrôle', time: 'Hier', icon: Icons.chat_bubble_outline_rounded, color: Color(0xFF6366F1)),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                AppStrings.recentNotifications,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ..._lastNotifications.map((n) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: n.color.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(n.icon, color: n.color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          n.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          n.subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    n.time,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 12),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onSeeAll,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppStrings.seeAll,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryRed,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 20,
                        color: AppColors.primaryRed,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
