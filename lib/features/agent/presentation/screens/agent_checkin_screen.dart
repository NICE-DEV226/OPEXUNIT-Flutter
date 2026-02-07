import 'package:flutter/material.dart';
import '../../../../core/app_strings.dart';
import '../../../../core/theme/app_colors.dart';

class AgentCheckinScreen extends StatelessWidget {
  const AgentCheckinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F7),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          AppStrings.serviceStart,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 8),
            // Grand cercle avec icône
            Container(
              width: 140,
              height: 140,
              decoration: const BoxDecoration(
                color: AppColors.softRed,
                shape: BoxShape.circle,
              ),
              child: Container(
                margin: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primaryRed,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: const Icon(
                  Icons.checklist_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppStrings.checkinStart,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.checkinInstructions,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),

            // Titre formulaire
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                AppStrings.form,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),

            _CheckinFormItem(
              icon: Icons.location_on_outlined,
              iconColor: const Color(0xFFB91C1C),
              title: AppStrings.geolocation,
              subtitle: AppStrings.gpsRequired,
              checked: true,
            ),
            const SizedBox(height: 10),

            _CheckinFormItem(
              icon: Icons.camera_alt_outlined,
              iconColor: const Color(0xFFB91C1C),
              title: AppStrings.photoDeService,
              subtitle: AppStrings.photoRequired,
              checked: true,
            ),

            const SizedBox(height: 20),

            // Bloc d'information
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFE5DADC),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFFB9AEB0)),
              ),
              child: Text(
                AppStrings.positionPhotoRecorded,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF4B5563),
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 32),

            // Bouton Valider
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _showCheckinSuccessDialog(context);
                },
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
                child: Text(AppStrings.validate),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showCheckinSuccessDialog(BuildContext rootContext) {
  showGeneralDialog<void>(
    context: rootContext,
    barrierDismissible: true,
    barrierLabel: 'checkin-success',
    barrierColor: Colors.black.withOpacity(0.45),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) {
      return const SizedBox.shrink();
    },
    transitionBuilder: (dialogContext, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInBack,
      );

      // Auto-fermeture + retour à l'accueil après un court délai
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (Navigator.of(dialogContext).canPop()) {
          Navigator.of(dialogContext).pop(); // ferme la popup
        }
        if (Navigator.of(rootContext).canPop()) {
          Navigator.of(rootContext).pop(); // revient à l'écran d'accueil
        }
      });

      return FadeTransition(
        opacity: animation,
        child: Center(
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(curved),
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: MediaQuery.of(dialogContext).size.width * 0.78,
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircleAvatar(
                      radius: 32,
                      backgroundColor: Color(0xFF22C55E),
                      child: Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      AppStrings.checkinRecorded,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
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


class _CheckinFormItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool checked;

  const _CheckinFormItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.checked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
              color: Color(0xFFD4D4D8),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
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
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            checked ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            color: checked ? const Color(0xFF16A34A) : const Color(0xFF9CA3AF),
          ),
        ],
      ),
    );
  }
}

