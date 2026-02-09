import 'package:flutter/material.dart';

import '../../../../core/app_strings.dart';
import '../../../../core/network/services/patrol_api_service.dart';
import '../../../../core/theme/app_colors.dart';

class AgentPatrolReportScreen extends StatefulWidget {
  const AgentPatrolReportScreen({super.key, this.patrolId});

  final String? patrolId;

  @override
  State<AgentPatrolReportScreen> createState() => _AgentPatrolReportScreenState();
}

class _AgentPatrolReportScreenState extends State<AgentPatrolReportScreen> {
  final _observationController = TextEditingController();
  String _selectedType = 'Véhicule';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _observationController.dispose();
    super.dispose();
  }

  Future<void> _submitReport(BuildContext context) async {
    final patrolId = widget.patrolId;
    final text = _observationController.text.trim();
    final anomaly = text.isEmpty ? _selectedType : '$_selectedType: $text';

    setState(() => _isSubmitting = true);
    try {
      if (patrolId != null && patrolId.isNotEmpty) {
        await PatrolApiService.reportAnomaly(patrolId: patrolId, anomaly: anomaly);
      }
      if (!context.mounted) return;
      _showSignalSuccessDialog(context);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e is Exception ? e.toString().replaceFirst('Exception: ', '') : 'Erreur'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F7),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          AppStrings.makeReport,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.incidentType,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedType,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF6B7280),
                    ),
                    onSelected: (v) => setState(() => _selectedType = v),
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'Véhicule', child: Text('Véhicule')),
                      const PopupMenuItem(value: 'Incendie', child: Text('Incendie')),
                      const PopupMenuItem(value: 'Intrusion', child: Text('Intrusion')),
                      const PopupMenuItem(value: 'Accident', child: Text('Accident')),
                      const PopupMenuItem(value: 'Autre', child: Text('Autre')),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Text(
              AppStrings.observation,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              constraints: const BoxConstraints(minHeight: 160),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: TextField(
                controller: _observationController,
                maxLines: null,
                minLines: 6,
                decoration: InputDecoration(
                  hintText: AppStrings.description,
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF9CA3AF),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF111827),
                ),
              ),
            ),

            const SizedBox(height: 20),

            _ReportItem(
              icon: Icons.camera_alt_outlined,
              title: AppStrings.photoDeService,
              subtitle: AppStrings.photoRequired,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppStrings.photoRequiredStub),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            _ReportItem(
              icon: Icons.location_on_outlined,
              title: AppStrings.geolocation,
              subtitle: AppStrings.gpsRequired,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppStrings.geolocationStub),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : () => _submitReport(context),
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
                child: Text(AppStrings.continue_),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _ReportItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
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
                        color: Color(0xFF9CA3AF),
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

void _showSignalSuccessDialog(BuildContext rootContext) {
  showGeneralDialog<void>(
    context: rootContext,
    barrierDismissible: true,
    barrierLabel: 'signal-success',
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

      Future.delayed(const Duration(milliseconds: 1400), () {
        if (Navigator.of(dialogContext).canPop()) {
          Navigator.of(dialogContext).pop(); // ferme popup
        }
        if (Navigator.of(rootContext).canPop()) {
          Navigator.of(rootContext).pop(); // revient à l'écran précédent
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
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Color(0xFF22C55E),
                      child: Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    SizedBox(height: 18),
                    Text(
                      AppStrings.signalRecorded,
                      style: TextStyle(
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

