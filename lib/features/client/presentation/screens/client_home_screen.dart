import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shake/shake.dart';

import '../../../../core/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/client_bottom_nav_bar.dart';
import 'client_contact_security_screen.dart';
import 'client_detailed_alert_screen.dart';
import 'client_journal_screen.dart';
import 'client_notifications_screen.dart';

/// Dashboard client : état du site, agents en service, dernier incident, SOS, actions.
class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  /// Nom affiché (sera remplacé par les données utilisateur / API).
  static String get _displayName => 'M. Dupont';

  ShakeDetector? _shakeDetector;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      try {
        _shakeDetector = ShakeDetector.autoStart(
          onPhoneShake: (_) {
            if (!mounted) return;
            _sendSosSimpleAndOpenScreen(context);
          },
          minimumShakeCount: 2,
          shakeSlopTimeMS: 400,
          shakeCountResetTime: 2500,
        );
      } catch (_) {
        _shakeDetector = null;
      }
    }
  }

  @override
  void dispose() {
    _shakeDetector?.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final timeStr = _formatTime(now);
    final dateStr = _formatDate(now);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: Column(
          children: [
            // Header : Bonjour + heure, cloche
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.helloClient(_displayName),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$timeStr • $dateStr',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.notifications_none_rounded,
                            size: 26, color: Color(0xFF111827)),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryRed,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ClientNotificationsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // État du site
                    _SectionTitle(title: AppStrings.siteStatus),
                    const SizedBox(height: 8),
                    _StatusCard(
                      status: AppStrings.secure,
                      isSecure: true,
                    ),

                    const SizedBox(height: 20),

                    // Agents en service
                    _SectionTitle(title: AppStrings.agentsOnDuty),
                    const SizedBox(height: 8),
                    _AgentsCard(count: 4),

                    const SizedBox(height: 20),

                    // Dernier incident
                    _SectionTitle(title: AppStrings.lastIncident),
                    const SizedBox(height: 8),
                    _LastIncidentCard(
                      timeAgo: AppStrings.agoHours(2),
                      description: '${AppStrings.perimeterPatrolAt('14h30')} ${AppStrings.noIncidentToReport}',
                    ),

                    const SizedBox(height: 24),

                    // Bouton SOS — Tap = choix (simple / avec message), Maintien 1s = envoi immédiat
                    Center(
                      child: Column(
                        children: [
                          _SosButton(
                            onTap: () => _showSosChoiceSheet(context),
                            onLongPress: () => _sendSosSimpleAndOpenScreen(context),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppStrings.hold1sImmediate,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              AppStrings.sosShakeHint,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF9CA3AF),
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Actions : Appeler agent | Journal
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.phone_rounded,
                            label: AppStrings.callAgent,
                            sublabel: AppStrings.call,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const ClientContactSecurityScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.history_rounded,
                            label: AppStrings.journal,
                            sublabel: AppStrings.clientHistory,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const ClientJournalScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Barre de navigation
            const ClientBottomNavBar(currentIndex: 0),
          ],
        ),
      ),
    );
  }

  static String _formatTime(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static String _formatDate(DateTime d) {
    const days = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    const months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'];
    final dayName = days[d.weekday - 1];
    final month = months[d.month - 1];
    return '$dayName ${d.day} $month';
  }

  void _showSosChoiceSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppStrings.triggerAlertQuestion,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    _sendSosSimpleAndOpenScreen(context);
                  },
                  icon: const Icon(Icons.warning_amber_rounded, size: 22),
                  label: Text(AppStrings.sendNow),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ClientDetailedAlertScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.message_rounded, size: 22),
                  label: Text(AppStrings.sendWithMessage),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryRed,
                    side: const BorderSide(color: AppColors.primaryRed),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: Text(AppStrings.cancel),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _sendSosSimpleAndOpenScreen(BuildContext context) {
    // TODO: envoi API alerte simple (GPS, timestamp)
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.primaryRed, size: 28),
            const SizedBox(width: 12),
            Expanded(child: Text(AppStrings.alertSentSuccess)),
          ],
        ),
        content: Text(
          AppStrings.alertSentConfirmationMessage,
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primaryRed),
            child: Text(AppStrings.ok),
          ),
        ],
      ),
    );
  }

}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Color(0xFF6B7280),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String status;
  final bool isSecure;

  const _StatusCard({required this.status, required this.isSecure});

  @override
  Widget build(BuildContext context) {
    final color = isSecure ? const Color(0xFF16A34A) : AppColors.primaryRed;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            AppStrings.currentStatus,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const Spacer(),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            status,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.check_circle_rounded, color: color, size: 24),
        ],
      ),
    );
  }
}

class _AgentsCard extends StatelessWidget {
  final int count;

  const _AgentsCard({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            count.toString().padLeft(2, '0'),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(width: 12),
          Icon(Icons.people_outline_rounded,
              size: 28, color: Colors.grey.shade400),
        ],
      ),
    );
  }
}

class _LastIncidentCard extends StatelessWidget {
  final String timeAgo;
  final String description;

  const _LastIncidentCard({
    required this.timeAgo,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              timeAgo,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF374151),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _SosButton extends StatefulWidget {
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _SosButton({this.onTap, this.onLongPress});

  @override
  State<_SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<_SosButton> {
  bool _pressing = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onLongPressStart: (_) => setState(() => _pressing = true),
      onLongPressEnd: (_) => setState(() => _pressing = false),
      onLongPress: widget.onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: _pressing ? const Color(0xFF991B1B) : AppColors.primaryRed,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryRed.withValues(alpha: 0.4),
              blurRadius: _pressing ? 20 : 12,
              spreadRadius: _pressing ? 2 : 0,
            ),
          ],
        ),
        child: Center(
          child: Text(
            AppStrings.sosAlert,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, size: 28, color: const Color(0xFF3B82F6)),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              Text(
                sublabel,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
