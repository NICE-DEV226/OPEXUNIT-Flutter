import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import 'client_command_center_chat_screen.dart';

/// Numéro du centre de secours (à remplacer par config / API par site).
const String kEmergencyCenterPhoneNumber = '+33800000000';

/// Écran "Contacter la sécurité" : appeler le centre ou envoyer un message.
/// Aligné CDC : client contacte le centre de commandement / permanence, pas les agents en direct.
class ClientContactSecurityScreen extends StatelessWidget {
  const ClientContactSecurityScreen({super.key});

  Future<void> _launchCall(BuildContext context, String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.cannotPlaceCall),
            backgroundColor: AppColors.primaryRed,
          ),
        );
      }
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
          AppStrings.contactSecurity,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppStrings.contactSecuritySubtitle,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF6B7280),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => _launchCall(context, kEmergencyCenterPhoneNumber),
                icon: const Icon(Icons.phone_rounded, size: 24),
                label: Text(AppStrings.callEmergencyCenter),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ClientCommandCenterChatScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.message_rounded, size: 24),
                label: Text(AppStrings.sendMessageToCenter),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryRed,
                  side: const BorderSide(color: AppColors.primaryRed),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
