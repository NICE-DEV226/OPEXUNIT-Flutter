import 'package:flutter/material.dart';

import '../../../../core/app_strings.dart';
import '../../../../core/auth/session_storage.dart';
import '../../../../core/network/services/intervention_api_service.dart';
import '../../../../core/network/services/report_api_service.dart';
import '../../../../core/offline/connectivity_service.dart';
import '../../../../core/offline/offline_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/intervention_model.dart';

/// Formulaire de rapport pour clôturer une intervention.
/// Crée le rapport (POST /api/reports/intervention) puis clôture (POST /api/interventions/:id/close) avec reportId.
class AgentInterventionReportScreen extends StatefulWidget {
  const AgentInterventionReportScreen({
    super.key,
    required this.interventionId,
    this.intervention,
  });

  final String interventionId;
  final InterventionModel? intervention;

  @override
  State<AgentInterventionReportScreen> createState() => _AgentInterventionReportScreenState();
}

class _AgentInterventionReportScreenState extends State<AgentInterventionReportScreen> {
  final _observationsController = TextEditingController();
  final _resumeController = TextEditingController();
  final _actionsController = TextEditingController();
  final _degatsController = TextEditingController();
  final _anomaliesController = TextEditingController();
  final _tempsReactionController = TextEditingController();

  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _observationsController.dispose();
    _resumeController.dispose();
    _actionsController.dispose();
    _degatsController.dispose();
    _anomaliesController.dispose();
    _tempsReactionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      final observations = _observationsController.text.trim();
      final resume = _resumeController.text.trim();
      final actions = _actionsController.text.trim();
      final degats = _degatsController.text.trim();
      final anomaliesStr = _anomaliesController.text.trim();
      final anomalies = anomaliesStr.isEmpty ? null : anomaliesStr.split(RegExp(r'[\n,;]')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      final tempsReactionStr = _tempsReactionController.text.trim();
      final tempsReaction = tempsReactionStr.isEmpty ? null : int.tryParse(tempsReactionStr);

      final online = await ConnectivityService.checkOnline();
      final agentId = SessionStorage.getUser()?.id;

      if (!online) {
        final payload = <String, dynamic>{'interventionId': widget.interventionId};
        if (agentId != null && agentId.isNotEmpty) payload['agentId'] = agentId;
        if (observations.isNotEmpty) payload['observations'] = observations;
        if (resume.isNotEmpty) payload['resume'] = resume;
        if (actions.isNotEmpty) payload['actions'] = actions;
        if (degats.isNotEmpty) payload['degats'] = degats;
        if (anomalies != null && anomalies.isNotEmpty) payload['anomalies'] = anomalies;
        if (tempsReaction != null) payload['temps_reaction'] = tempsReaction;
        await OfflineStorage.enqueueAction(kActionInterventionClose, payload);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Rapport enregistré localement. Il sera envoyé à la prochaine synchronisation.'),
            backgroundColor: Colors.green.shade700,
          ),
        );
        Navigator.of(context).pop(true);
        return;
      }

      final result = await ReportApiService.createInterventionReport(
        interventionId: widget.interventionId,
        agentId: agentId,
        observations: observations.isEmpty ? null : observations,
        resume: resume.isEmpty ? null : resume,
        actions: actions.isEmpty ? null : actions,
        degats: degats.isEmpty ? null : degats,
        anomalies: anomalies,
        tempsReaction: tempsReaction,
      );

      await InterventionApiService.close(widget.interventionId, reportId: result.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Intervention clôturée. Rapport enregistré.'),
          backgroundColor: Colors.green.shade700,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _error = e is Exception ? e.toString().replaceFirst('Exception: ', '') : '$e';
      });
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
          AppStrings.closeIntervention,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.closeInterventionSubtitle,
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 20),
            _buildLabel(AppStrings.observation),
            _buildTextField(_observationsController, AppStrings.description, minLines: 4),
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
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(fontSize: 13, color: Colors.red)),
            ],
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Clôturer et enregistrer le rapport'),
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
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
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
