import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/app_strings.dart';
import '../../../../core/auth/session_storage.dart';
import '../../../../core/services/gps_tracking_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/services/checkin_api_service.dart';
import '../../data/models/checkin_model.dart';

class AgentCheckinScreen extends StatefulWidget {
  const AgentCheckinScreen({super.key});

  @override
  State<AgentCheckinScreen> createState() => _AgentCheckinScreenState();
}

class _AgentCheckinScreenState extends State<AgentCheckinScreen> {
  final _notesController = TextEditingController();

  CheckinType _type = CheckinType.start;
  Position? _position;
  bool _loadingPosition = false;
  String? _positionError;
  File? _photoFile;
  bool _sending = false;
  String? _sendError;

  @override
  void initState() {
    super.initState();
    _fetchPosition();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _fetchPosition() async {
    if (_loadingPosition) return;
    setState(() {
      _loadingPosition = true;
      _positionError = null;
    });
    try {
      final position = await getCurrentPositionOptional();
      if (!mounted) return;
      setState(() {
        _position = position;
        _loadingPosition = false;
        _positionError = position == null ? AppStrings.gpsError : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingPosition = false;
        _positionError = AppStrings.gpsError;
      });
    }
  }

  Future<void> _takePhoto() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked == null || !mounted) return;
      setState(() {
        _photoFile = File(picked.path);
        _sendError = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _sendError = 'Impossible de prendre la photo.');
      }
    }
  }

  Future<void> _submit() async {
    setState(() {
      _sending = true;
      _sendError = null;
    });

    try {
      Position? position = _position;
      if (position == null && !_loadingPosition) {
        position = await getCurrentPositionOptional();
      }

      await CheckinApiService.create(
        type: _type.value,
        latitude: position?.latitude,
        longitude: position?.longitude,
        photoKey: null, // TODO: envoyer après implémentation upload backend
        patrolId: null,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      if (!mounted) return;
      if (_type == CheckinType.start) {
        await SessionStorage.setAgentOnDuty(true);
        GpsTrackingService.start();
      } else if (_type == CheckinType.end) {
        await SessionStorage.setAgentOnDuty(false);
        GpsTrackingService.stop();
      }
      if (!mounted) return;
      _showCheckinSuccessDialog(context);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _sendError = e is Exception ? e.toString().replaceFirst('Exception: ', '') : 'Erreur réseau';
      });
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

            // Type de check-in
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.checkinTypeLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<CheckinType>(
                        value: _type,
                        isExpanded: true,
                        items: CheckinType.values
                            .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                            .toList(),
                        onChanged: (v) => setState(() => _type = v ?? CheckinType.start),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            _CheckinFormItem(
              icon: Icons.location_on_outlined,
              iconColor: const Color(0xFFB91C1C),
              title: AppStrings.geolocation,
              subtitle: _loadingPosition
                  ? AppStrings.gpsWaiting
                  : _position != null
                      ? '${_position!.latitude.toStringAsFixed(5)}, ${_position!.longitude.toStringAsFixed(5)}'
                      : (_positionError ?? AppStrings.gpsRequired),
              checked: _position != null,
              onTap: _loadingPosition ? null : _fetchPosition,
            ),
            const SizedBox(height: 10),

            _CheckinFormItem(
              icon: Icons.camera_alt_outlined,
              iconColor: const Color(0xFFB91C1C),
              title: AppStrings.photoDeService,
              subtitle: _photoFile != null ? 'Photo ajoutée' : AppStrings.photoRequired,
              checked: _photoFile != null,
              onTap: _takePhoto,
            ),

            const SizedBox(height: 14),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                hintText: AppStrings.notesOptional,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              maxLines: 2,
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 20),
            if (_sendError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _sendError!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),

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

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _sending ? null : _submit,
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
                child: _sending
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(AppStrings.validate),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showCheckinSuccessDialog(BuildContext rootContext) {
  final navigator = Navigator.of(rootContext);
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
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        navigator.pop();
                      },
                      child: Text(AppStrings.validate),
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
  final VoidCallback? onTap;

  const _CheckinFormItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.checked,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
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
      ),
    );
  }
}
