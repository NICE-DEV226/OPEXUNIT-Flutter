import 'package:flutter/material.dart';

import '../../../../core/app_locale.dart';
import '../../../../core/app_strings.dart';
import '../../../../core/auth/session_storage.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/services/gps_tracking_service.dart';
import '../../../../core/network/services/auth_api_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import 'agent_edit_profile_screen.dart';
import 'agent_settings_screen.dart';

class AgentProfileScreen extends StatefulWidget {
  const AgentProfileScreen({super.key, this.historyScreenBuilder, this.bottomNavBar});

  final Widget Function()? historyScreenBuilder;
  /// Barre de navigation du bas (fournie par l'appelant pour éviter import circulaire).
  final Widget? bottomNavBar;

  @override
  State<AgentProfileScreen> createState() => _AgentProfileScreenState();
}

class _AgentProfileScreenState extends State<AgentProfileScreen> {
  bool _modeOffline = false;

  UserModel? get _user => SessionStorage.getUser();

  @override
  Widget build(BuildContext context) {
    final user = _user;
    return ValueListenableBuilder<Locale>(
      valueListenable: appLocaleNotifier,
      builder: (_, locale, __) {
        final title = AppStrings.profile;
        final systemStatus = AppStrings.systemStatus;
        final operational = AppStrings.operational;
        final preference = AppStrings.preference;
        final modeOffline = AppStrings.offlineMode;
        final modeOfflineDesc = AppStrings.offlineModeDesc;
        final language = AppStrings.language;
        final logout = AppStrings.logout;
        final gpsLabel = AppStrings.gpsUpdate;
        final cameraLabel = AppStrings.authorized;
        final networkLabel = AppStrings.strongSignal4g;
        final active = AppStrings.active;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F7),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              title,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_rounded, color: Colors.black87),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AgentSettingsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          bottomNavigationBar: widget.bottomNavBar,
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _showPhotoOptions,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      _buildPhotoAvatar(user),
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user?.fullName ?? '—',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (user != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryRed,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _roleLabel(user.role),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (user.matricule != null && user.matricule!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'ID: ${user.matricule}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _UserInfoCard(user: user),
                ],
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () async {
                    final updated = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => const AgentEditProfileScreen(),
                      ),
                    );
                    if (updated == true && mounted) setState(() {});
                  },
                  icon: const Icon(Icons.edit_rounded, size: 20),
                  label: Text(AppStrings.editProfile),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryRed,
                    side: const BorderSide(color: AppColors.primaryRed),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  ),
                ),
                const SizedBox(height: 28),
                _SystemStatusCard(
                  title: systemStatus,
                  statusLabel: operational,
                  items: [
                    _StatusRow(icon: Icons.location_on_outlined, label: gpsLabel, status: active),
                    _StatusRow(icon: Icons.videocam_outlined, label: cameraLabel, status: active),
                    _StatusRow(icon: Icons.wifi_rounded, label: networkLabel, status: active),
                  ],
                ),
                const SizedBox(height: 16),
                _PreferenceCard(
                  title: preference,
                  children: [
                    _PreferenceRow(
                      icon: Icons.cloud_off_rounded,
                      title: modeOffline,
                      subtitle: modeOfflineDesc,
                      trailing: Switch(
                        value: _modeOffline,
                        onChanged: (v) => setState(() => _modeOffline = v),
                        activeColor: AppColors.primaryRed,
                      ),
                    ),
                    _LanguageRow(
                      label: language,
                      onTap: _showLanguageSheet,
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
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
                    icon: const Icon(Icons.logout_rounded, size: 20),
                    label: Text(logout),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF4B5563),
                      side: const BorderSide(color: Color(0xFFD1D5DB)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhotoAvatar(UserModel? user) {
    final photoUrl = user?.photoProfil != null && user!.photoProfil!.isNotEmpty
        ? ApiConfig.uploadsUrl(user.photoProfil)
        : null;
    final name = user?.fullName ?? '';
    final initial = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';
    return CircleAvatar(
      radius: 52,
      backgroundColor: const Color(0xFFE5E7EB),
      child: photoUrl != null && photoUrl.isNotEmpty
          ? ClipOval(
              child: Image.network(
                photoUrl,
                width: 104,
                height: 104,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4B5563),
                  ),
                ),
              ),
            )
          : Text(
              initial,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: Color(0xFF4B5563),
              ),
            ),
    );
  }

  static String _roleLabel(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return 'Administrateur';
      case 'SUPERVISEUR':
        return 'Superviseur';
      case 'AGENT':
        return 'Agent de sécurité';
      case 'CLIENT':
        return 'Client';
      default:
        return role;
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primaryRed),
                title: Text(AppStrings.takePhoto),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppStrings.cameraToConnect),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.primaryRed),
                title: Text(AppStrings.chooseFromGallery),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppStrings.galleryToConnect),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguageSheet() {
    final current = appLocaleNotifier.value.languageCode;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(AppStrings.french),
                trailing: current == 'fr' ? const Icon(Icons.check_rounded, color: AppColors.primaryRed) : null,
                onTap: () async {
                  await setAppLocale('fr');
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: Text(AppStrings.english),
                trailing: current == 'en' ? const Icon(Icons.check_rounded, color: AppColors.primaryRed) : null,
                onTap: () async {
                  await setAppLocale('en');
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserInfoCard extends StatelessWidget {
  final UserModel user;

  const _UserInfoCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    if (user.email.isNotEmpty) {
      rows.add(_InfoRow(icon: Icons.email_outlined, label: 'Email', value: user.email));
    }
    if (user.telephone.isNotEmpty) {
      rows.add(_InfoRow(icon: Icons.phone_outlined, label: 'Téléphone', value: user.telephone));
    }
    if (user.ville != null && user.ville!.isNotEmpty) {
      rows.add(_InfoRow(icon: Icons.location_city_outlined, label: 'Ville', value: user.ville!));
    }
    if (user.siteAffecte != null && user.siteAffecte!.isNotEmpty) {
      rows.add(_InfoRow(icon: Icons.place_outlined, label: 'Site', value: user.siteAffecte!));
    }
    if (user.zoneAffectee != null && user.zoneAffectee!.isNotEmpty) {
      rows.add(_InfoRow(icon: Icons.map_outlined, label: 'Zone', value: user.zoneAffectee!));
    }
    if (rows.isEmpty) return const SizedBox.shrink();
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informations',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6B7280),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          ...rows,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF6B7280)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SystemStatusCard extends StatelessWidget {
  final String title;
  final String statusLabel;
  final List<Widget> items;

  const _SystemStatusCard({
    required this.title,
    required this.statusLabel,
    required this.items,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6B7280),
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF16A34A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...items,
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String status;

  const _StatusRow({required this.icon, required this.label, required this.status});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 22, color: const Color(0xFF7C3AED)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF22C55E),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                status,
                style: const TextStyle(fontSize: 12, color: Color(0xFF16A34A), fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreferenceCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _PreferenceCard({required this.title, required this.children});

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6B7280),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _PreferenceRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  const _PreferenceRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: const Color(0xFF6B7280)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _LanguageRow({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final locale = appLocaleNotifier.value.languageCode;
    final value = locale == 'en' ? AppStrings.english : AppStrings.french;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.language_rounded, size: 22, color: Color(0xFF6B7280)),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
              const Spacer(),
              Text(
                value,
                style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
