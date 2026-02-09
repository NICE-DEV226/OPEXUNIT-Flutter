import 'package:flutter/material.dart';

import '../../../../core/app_strings.dart';
import '../../../../core/auth/session_storage.dart';
import '../../../../core/network/services/report_api_service.dart';
import '../../../../core/offline/connectivity_service.dart';
import '../../../../core/offline/offline_patrol_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/patrol_controller.dart';

class AgentPatrolFinishScreen extends StatefulWidget {
  const AgentPatrolFinishScreen({super.key, this.patrolId});

  final String? patrolId;

  @override
  State<AgentPatrolFinishScreen> createState() => _AgentPatrolFinishScreenState();
}

class _AgentPatrolFinishScreenState extends State<AgentPatrolFinishScreen> {
  final _observationController = TextEditingController();
  final _resumeController = TextEditingController();
  final _actionsController = TextEditingController();
  final _degatsController = TextEditingController();
  final _anomaliesController = TextEditingController();
  final _tempsReactionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _observationController.dispose();
    _resumeController.dispose();
    _actionsController.dispose();
    _degatsController.dispose();
    _anomaliesController.dispose();
    _tempsReactionController.dispose();
    super.dispose();
  }

  Future<void> _endPatrolAndFinish(BuildContext context) async {
    final patrolId = widget.patrolId;
    final observations = _observationController.text.trim();
    final resume = _resumeController.text.trim();
    final actions = _actionsController.text.trim();
    final degats = _degatsController.text.trim();
    final anomaliesStr = _anomaliesController.text.trim();
    final anomalies = anomaliesStr.isEmpty
        ? null
        : anomaliesStr.split(RegExp(r'[\n,;]')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final tempsReaction = int.tryParse(_tempsReactionController.text.trim());

    setState(() => _isSubmitting = true);
    try {
      if (patrolId != null && patrolId.isNotEmpty) {
        final online = await ConnectivityService.checkOnline();
        final agentId = SessionStorage.getUser()?.id;
        if (online) {
          await ReportApiService.createPatrolReport(
            patrolId: patrolId,
            agentId: agentId,
            observations: observations.isEmpty ? null : observations,
            anomalies: anomalies,
            resume: resume.isEmpty ? null : resume,
            degats: degats.isEmpty ? null : degats,
            tempsReaction: tempsReaction,
            actions: actions.isEmpty ? null : actions,
          );
        }
        await OfflinePatrolService.endPatrol(
          patrolId,
          reportObservations: observations.isEmpty ? null : observations,
          reportAnomalies: anomalies,
          reportResume: resume.isEmpty ? null : resume,
          reportDegats: degats.isEmpty ? null : degats,
          reportTempsReaction: tempsReaction,
          reportActions: actions.isEmpty ? null : actions,
        );
        PatrolController.instance.loadMyPatrol();
      }
      if (!context.mounted) return;
      _showFinishSuccessDialog(context);
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          AppStrings.finishPatrol,
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
              AppStrings.finishPatrolSubtitle,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
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

            const SizedBox(height: 16),
            _buildLabel(AppStrings.reportResume),
            _buildTextField(_resumeController, '', minLines: 2),
            const SizedBox(height: 16),
            _buildLabel(AppStrings.reportActions),
            _buildTextField(_actionsController, '', minLines: 2),
            const SizedBox(height: 16),
            _buildLabel(AppStrings.reportDegats),
            _buildTextField(_degatsController, '', minLines: 2),
            const SizedBox(height: 16),
            _buildLabel(AppStrings.anomaliesList),
            _buildTextField(_anomaliesController, 'Séparer par virgule ou retour à la ligne', minLines: 2),
            const SizedBox(height: 16),
            _buildLabel(AppStrings.tempsReaction),
            _buildTextField(_tempsReactionController, 'Ex: 15', minLines: 1, keyboardType: TextInputType.number),

            const SizedBox(height: 20),

            _FinishItem(
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
            _FinishItem(
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
                onPressed: _isSubmitting ? null : () => _endPatrolAndFinish(context),
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

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    int minLines = 1,
    TextInputType? keyboardType,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: TextField(
        controller: controller,
        maxLines: null,
        minLines: minLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          isDense: true,
        ),
        style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
      ),
    );
  }
}

class _FinishItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _FinishItem({
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

void _showFinishSuccessDialog(BuildContext rootContext) {
  showGeneralDialog<void>(
    context: rootContext,
    barrierDismissible: true,
    barrierLabel: 'finish-success',
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
        // Retour à l'accueil (on vide la pile jusqu'à la première route)
        Navigator.of(rootContext).popUntil((route) => route.isFirst);
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
                      AppStrings.reportSavedTitle,
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

