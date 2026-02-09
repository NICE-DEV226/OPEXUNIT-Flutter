import 'package:flutter/material.dart';

import '../../../../core/app_strings.dart';
import '../../../../core/network/services/alert_api_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_colors.dart';

/// Type d'incident pour le formulaire "Signaler un incident".
enum IncidentTypeOption { intrusion, degradation, other }

/// Écran "Signaler un incident" : site concerné, type (Intrusion/Dégradation/Autre),
/// description rapide, photo, bouton ENVOYER L'ALERTE → POST /api/alerts/trigger.
class ClientDetailedAlertScreen extends StatefulWidget {
  /// ID du site (optionnel, pour contexte).
  final String? siteId;
  /// Nom du site (ex. depuis la page détail site). Sinon valeur par défaut.
  final String? siteName;

  const ClientDetailedAlertScreen({
    super.key,
    this.siteId,
    this.siteName,
  });

  @override
  State<ClientDetailedAlertScreen> createState() => _ClientDetailedAlertScreenState();
}

class _ClientDetailedAlertScreenState extends State<ClientDetailedAlertScreen> {
  IncidentTypeOption? _selectedType;
  final _descriptionController = TextEditingController();

  String get _displaySiteName => widget.siteName ?? AppStrings.defaultSiteName;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _onSendAlert() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.confirmSendSosTitle),
        content: Text(AppStrings.confirmSendSosMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _submitAndShowSuccess();
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.primaryRed),
            child: Text(AppStrings.confirm),
          ),
        ],
      ),
    );
  }

  Future<void> _submitAndShowSuccess() async {
    try {
      final position = await getCurrentPositionOptional();
      final type = _selectedType == IncidentTypeOption.intrusion
          ? 'intrusion'
          : _selectedType == IncidentTypeOption.degradation
              ? 'degradation'
              : 'client';
      await AlertApiService.triggerAlert(
        type: type,
        source: 'client',
        priorite: 'HAUTE',
        latitude: position?.latitude,
        longitude: position?.longitude,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e is Exception ? e.toString().replaceFirst('Exception: ', '') : 'Erreur envoi alerte'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 32),
            const SizedBox(width: 12),
            Expanded(child: Text(AppStrings.incidentReportSuccessTitle)),
          ],
        ),
        content: Text(
          AppStrings.incidentReportSuccessMessage,
          style: const TextStyle(fontSize: 15, height: 1.4),
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.primaryRed),
            child: Text(AppStrings.ok),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          AppStrings.reportIncident,
          style: const TextStyle(
            color: Color(0xFF111827),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Site concerné
            Text(
              AppStrings.concernedSite,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryRed,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _displaySiteName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF374151),
              ),
            ),

            const SizedBox(height: 24),

            // Type d'incident
            Text(
              AppStrings.incidentType,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 10),
            Material(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: _showTypePicker,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedType == null
                              ? AppStrings.selectType
                              : _typeLabel(_selectedType!),
                          style: TextStyle(
                            fontSize: 15,
                            color: _selectedType == null
                                ? const Color(0xFF9CA3AF)
                                : const Color(0xFF111827),
                          ),
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF6B7280)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _TypePill(
                  label: AppStrings.intrusion,
                  selected: _selectedType == IncidentTypeOption.intrusion,
                  onTap: () => setState(() => _selectedType = IncidentTypeOption.intrusion),
                ),
                const SizedBox(width: 10),
                _TypePill(
                  label: AppStrings.degradation,
                  selected: _selectedType == IncidentTypeOption.degradation,
                  onTap: () => setState(() => _selectedType = IncidentTypeOption.degradation),
                ),
                const SizedBox(width: 10),
                _TypePill(
                  label: AppStrings.other,
                  selected: _selectedType == IncidentTypeOption.other,
                  onTap: () => setState(() => _selectedType = IncidentTypeOption.other),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Description rapide
            Text(
              AppStrings.quickDescription,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 140,
              child: TextField(
                controller: _descriptionController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: AppStrings.keyDetailsPlaceholder,
                  filled: true,
                  fillColor: const Color(0xFFF3F4F6),
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Ajouter une photo
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppStrings.addPhoto)),
                );
              },
              icon: Icon(Icons.add_rounded, size: 20, color: AppColors.primaryRed),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryRed,
                side: const BorderSide(color: AppColors.primaryRed),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.camera_alt_rounded, size: 22, color: AppColors.primaryRed),
                  const SizedBox(width: 8),
                  Text(AppStrings.addPhoto),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ENVOYER L'ALERTE
            SizedBox(
              height: 54,
              child: FilledButton(
                onPressed: _onSendAlert,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(AppStrings.sendAlertButton),
                    const SizedBox(width: 10),
                    const Icon(Icons.arrow_forward_rounded, size: 22),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTypePicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                AppStrings.incidentType,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person_rounded, color: Color(0xFF6B7280)),
              title: Text(AppStrings.intrusion),
              onTap: () {
                setState(() => _selectedType = IncidentTypeOption.intrusion);
                Navigator.of(ctx).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.build_rounded, color: Color(0xFF6B7280)),
              title: Text(AppStrings.degradation),
              onTap: () {
                setState(() => _selectedType = IncidentTypeOption.degradation);
                Navigator.of(ctx).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.more_horiz_rounded, color: Color(0xFF6B7280)),
              title: Text(AppStrings.other),
              onTap: () {
                setState(() => _selectedType = IncidentTypeOption.other);
                Navigator.of(ctx).pop();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _typeLabel(IncidentTypeOption t) {
    switch (t) {
      case IncidentTypeOption.intrusion:
        return AppStrings.intrusion;
      case IncidentTypeOption.degradation:
        return AppStrings.degradation;
      case IncidentTypeOption.other:
        return AppStrings.other;
    }
  }
}

class _TypePill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primaryRed.withValues(alpha: 0.12)
          : const Color(0xFFF3F4F6),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.primaryRed : const Color(0xFF374151),
            ),
          ),
        ),
      ),
    );
  }
}
