import 'package:flutter/material.dart';

import '../../../../core/app_locale.dart';
import '../../../../core/app_strings.dart';
import '../../../../core/theme/app_colors.dart';

/// Écran Paramètres client : langue (FR/EN persistant), information sur les identifiants fournis par l'admin.
class ClientSettingsScreen extends StatelessWidget {
  const ClientSettingsScreen({super.key});

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
          AppStrings.settings,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ValueListenableBuilder<Locale>(
        valueListenable: appLocaleNotifier,
        builder: (context, locale, _) {
          final langLabel = locale.languageCode == 'en' ? AppStrings.english : AppStrings.french;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            children: [
              _SettingsTile(
                icon: Icons.language_rounded,
                title: AppStrings.language,
                subtitle: langLabel,
                onTap: () => _showLanguageSheet(context),
              ),
              const SizedBox(height: 20),
              _CredentialsInfoCard(
                message: AppStrings.credentialsFromAdminOnCreation,
              ),
            ],
          );
        },
      ),
    );
  }

  void _showLanguageSheet(BuildContext context) {
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
                trailing: current == 'fr'
                    ? const Icon(Icons.check_rounded, color: AppColors.primaryRed)
                    : null,
                onTap: () async {
                  await setAppLocale('fr');
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: Text(AppStrings.english),
                trailing: current == 'en'
                    ? const Icon(Icons.check_rounded, color: AppColors.primaryRed)
                    : null,
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

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
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

class _CredentialsInfoCard extends StatelessWidget {
  final String message;

  const _CredentialsInfoCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.primaryRed, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF374151),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
