import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/app_strings.dart';
import '../../../../core/auth/session_storage.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/network/services/user_api_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/models/user_model.dart';

/// Écran de modification du profil : photo (upload) et ville.
/// Upload photo : POST /api/upload/file (target=profile) → puis PUT /api/users/me avec photoProfil (URL) + ville.
class AgentEditProfileScreen extends StatefulWidget {
  const AgentEditProfileScreen({super.key});

  @override
  State<AgentEditProfileScreen> createState() => _AgentEditProfileScreenState();
}

class _AgentEditProfileScreenState extends State<AgentEditProfileScreen> {
  final _villeController = TextEditingController();

  bool _loading = false;
  String? _errorMessage;
  /// Base64 pour l’aperçu local après prise de photo.
  String? _photoBase64;
  /// Chemin du fichier pris (pour upload POST /api/upload/file).
  String? _photoFilePath;

  @override
  void initState() {
    super.initState();
    final user = SessionStorage.getUser();
    if (user?.ville != null && user!.ville!.isNotEmpty) {
      _villeController.text = user.ville!;
    }
  }

  @override
  void dispose() {
    _villeController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    setState(() => _errorMessage = null);
    try {
      final status = await Permission.camera.status;
      if (status.isPermanentlyDenied) {
        if (!mounted) return;
        setState(() => _errorMessage =
            'Caméra bloquée. Ouvrez les réglages pour autoriser.');
        return;
      }
      if (status.isDenied) {
        final result = await Permission.camera.request();
        if (!mounted) return;
        if (result.isPermanentlyDenied || result.isDenied) {
          setState(() => _errorMessage = 'L\'accès à la caméra est nécessaire.');
          return;
        }
      }
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked == null || !mounted) return;
      final bytes = await picked.readAsBytes();
      final base64 = base64Encode(bytes);
      setState(() {
        _photoBase64 = base64;
        _photoFilePath = picked.path;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage =
          e is Exception ? e.toString().replaceFirst('Exception: ', '') : 'Erreur');
    }
  }

  Future<void> _save() async {
    final ville = _villeController.text.trim();
    final hasNewPhoto = _photoFilePath != null && File(_photoFilePath!).existsSync();
    if (!hasNewPhoto && ville.isEmpty) {
      setState(() => _errorMessage = 'Modifiez au moins la photo ou la ville.');
      return;
    }
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      String? photoProfilPath;
      if (hasNewPhoto) {
        photoProfilPath = await UserApiService.uploadFile(
          File(_photoFilePath!),
          target: 'profile',
        );
      }
      final body = <String, dynamic>{};
      if (photoProfilPath != null) body['photoProfil'] = photoProfilPath;
      if (ville.isNotEmpty) body['ville'] = ville;
      if (body.isEmpty) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final user = await UserApiService.updateMe(body);
      await SessionStorage.updateUser(user);
      await SessionStorage.setProfileComplete(user.profileComplete);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profil mis à jour'),
          backgroundColor: Colors.green.shade700,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = e is Exception ? e.toString().replaceFirst('Exception: ', '') : 'Erreur';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionStorage.getUser();
    final photoUrl = user?.photoProfil != null && user!.photoProfil!.isNotEmpty
        ? ApiConfig.uploadsUrl(user.photoProfil)
        : null;

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
          AppStrings.editProfile,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.editProfileTitle,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _loading ? null : _takePhoto,
              child: Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundColor: const Color(0xFFE5E7EB),
                      child: _photoBase64 != null
                          ? ClipOval(
                              child: Image.memory(
                                base64Decode(_photoBase64!),
                                width: 104,
                                height: 104,
                                fit: BoxFit.cover,
                              ),
                            )
                          : (photoUrl != null && photoUrl.isNotEmpty)
                              ? ClipOval(
                                  child: Image.network(
                                    photoUrl,
                                    width: 104,
                                    height: 104,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _initialAvatar(user),
                                  ),
                                )
                              : _initialAvatar(user),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryRed,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Appuyez pour changer la photo',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _villeController,
              decoration: const InputDecoration(
                labelText: 'Ville',
                hintText: 'Ex: Paris',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(fontSize: 13, color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(AppStrings.save),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _initialAvatar(UserModel? user) {
    final name = user?.fullName ?? '';
    final initial = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';
    return Text(
      initial,
      style: const TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: Color(0xFF4B5563),
      ),
    );
  }
}
