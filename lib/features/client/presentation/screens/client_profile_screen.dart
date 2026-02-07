import 'package:flutter/material.dart';

import '../../../../core/app_strings.dart';
import '../../../../core/auth/session_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../widgets/client_bottom_nav_bar.dart';
import 'client_contact_security_screen.dart';
import 'client_personal_info_screen.dart';
import 'client_settings_screen.dart';

/// Écran Profil client : avatar, infos, cartes (informations personnelles,
/// paramètres de sécurité, contacter OPEXUNIT), déconnexion.
/// Aligné CDC §2.10 (sécurité, accès, authentification).
class ClientProfileScreen extends StatelessWidget {
  final ClientBottomNavBar bottomNavBar;

  const ClientProfileScreen({
    super.key,
    required this.bottomNavBar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F4F6),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          AppStrings.clientProfileTitle,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        children: [
          _buildProfileHeader(context),
          const SizedBox(height: 28),
          _ProfileCard(
            icon: Icons.person_rounded,
            title: AppStrings.personalInfo,
            subtitle: AppStrings.personalInfoSubtitle,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ClientPersonalInfoScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _ProfileCard(
            icon: Icons.settings_rounded,
            title: AppStrings.settings,
            subtitle: AppStrings.languageAndPreferences,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ClientSettingsScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _ProfileCard(
            icon: Icons.security_rounded,
            title: AppStrings.securitySettings,
            subtitle: AppStrings.passwordAndAuth,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ClientSettingsScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _ProfileCard(
            icon: Icons.headset_mic_rounded,
            title: AppStrings.contactOpexunit,
            subtitle: AppStrings.support24_7,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ClientContactSecurityScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 28),
          _buildLogout(context),
        ],
      ),
      bottomNavigationBar: bottomNavBar,
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 48,
          backgroundColor: const Color(0xFFFFE4E1),
          child: Text(
            AppStrings.defaultClientName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase(),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryRed,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          AppStrings.defaultClientName,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          AppStrings.defaultCompanyName,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primaryRed.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            AppStrings.clientOpexunitLabel,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryRed,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogout(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: () => _logout(context),
        icon: const Icon(Icons.logout_rounded, size: 20, color: Color(0xFF374151)),
        label: Text(
          AppStrings.logout,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
      ),
    );
  }

  void _logout(BuildContext context) async {
    await SessionStorage.clear();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 0,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
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
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primaryRed, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF), size: 24),
            ],
          ),
        ),
      ),
    );
  }
}
