import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/app_strings.dart';
import '../../../../core/auth/session_storage.dart';
import '../../../../core/network/services/auth_api_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../agent/presentation/screens/agent_home_screen.dart';
import '../../../client/presentation/screens/client_home_screen.dart';

/// Écran de complétion du profil après première connexion.
/// Le profil est marqué complet (et email de bienvenue envoyé) uniquement quand photo ET ville sont renseignés.
/// Changer le mot de passe reste optionnel.
class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _villeController = TextEditingController();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  String? _photoBase64;
  File? _photoFile;
  bool _showChangePassword = false;

  /// True si photo et ville sont renseignés (le backend marquera alors le profil complet et enverra l'email de bienvenue).
  bool get _canCompleteProfile {
    final hasPhoto = _photoBase64 != null && _photoBase64!.isNotEmpty;
    final hasVille = _villeController.text.trim().isNotEmpty;
    return hasPhoto && hasVille;
  }

  @override
  void dispose() {
    _villeController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked == null || !mounted) return;
      // Utiliser readAsBytes() du XFile pour éviter les erreurs de chemin (Android content URI)
      final bytes = await picked.readAsBytes();
      final base64 = base64Encode(bytes);
      final file = File(picked.path);
      setState(() {
        _photoFile = file.existsSync() ? file : null;
        _photoBase64 = base64;
        _errorMessage = null;
      });
    } on Exception catch (e) {
      if (!mounted) return;
      final msg = e.toString().toLowerCase();
      if (msg.contains('camera') || msg.contains('denied') || msg.contains('permission')) {
        setState(() => _errorMessage =
            'Accès à la caméra refusé. Autorisez la caméra dans les réglages du téléphone.');
      } else {
        setState(() => _errorMessage = 'Impossible de prendre la photo. Réessayez.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Impossible de prendre la photo. Réessayez.');
      }
    }
  }

  /// Ouvre uniquement l'appareil photo (pas la galerie). Demande la permission avant.
  Future<void> _takePhoto() async {
    setState(() => _errorMessage = null);
    try {
      final status = await Permission.camera.status;
      if (status.isPermanentlyDenied) {
        if (!mounted) return;
        setState(() => _errorMessage =
            'Caméra bloquée. Appuyez sur « Ouvrir réglages » ci-dessous pour autoriser.');
        return;
      }
      if (status.isDenied) {
        final result = await Permission.camera.request();
        if (!mounted) return;
        if (result.isPermanentlyDenied) {
          setState(() => _errorMessage =
              'Caméra bloquée. Utilisez « Ouvrir réglages » pour autoriser l\'accès.');
          return;
        }
        if (result.isDenied) {
          setState(() => _errorMessage = 'L\'accès à la caméra est nécessaire pour la photo.');
          return;
        }
      }
      await _pickImage(ImageSource.camera);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage =
          'Erreur caméra: ${e is Exception ? e.toString().replaceFirst('Exception: ', '') : 'réessayez'}');
    }
  }

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_showChangePassword) {
        final oldP = _oldPasswordController.text;
        final newP = _newPasswordController.text;
        final confirm = _confirmPasswordController.text;
        if (oldP.isEmpty || newP.isEmpty) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Remplissez l\'ancien et le nouveau mot de passe.';
          });
          return;
        }
        if (newP != confirm) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Les deux mots de passe ne correspondent pas.';
          });
          return;
        }
        if (newP.length < 6) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Le nouveau mot de passe doit faire au moins 6 caractères.';
          });
          return;
        }
        await AuthApiService.changePassword(oldPassword: oldP, newPassword: newP);
      }

      // Photo et ville requis : le backend ne met profileComplete à true (et envoie l'email de bienvenue) que si les deux sont présents
      final photo = _photoBase64 != null && _photoBase64!.isNotEmpty ? _photoBase64! : null;
      final ville = _villeController.text.trim().isEmpty ? null : _villeController.text.trim();
      if (photo == null || ville == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Photo et ville sont requis pour compléter le profil.';
        });
        return;
      }

      final user = await AuthApiService.completeProfile(photoProfil: photo, ville: ville);
      await SessionStorage.updateUser(user);
      await SessionStorage.setProfileComplete(user.profileComplete);
      if (!mounted) return;
      _navigateToHome(user.isClient);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e is Exception ? e.toString().replaceFirst('Exception: ', '') : 'Erreur';
      });
    }
  }

  void _navigateToHome(bool isClient) {
    if (isClient) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ClientHomeScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AgentHomeScreen()),
      );
    }
  }

  /// Passer : enregistre les données actuelles (photo/ville partielles). Le backend ne marque pas le profil complet ; à la prochaine connexion l'utilisateur reviendra ici.
  Future<void> _skip() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final user = await AuthApiService.completeProfile(
        photoProfil: _photoBase64 != null && _photoBase64!.isNotEmpty ? _photoBase64 : null,
        ville: _villeController.text.trim().isEmpty ? null : _villeController.text.trim(),
      );
      await SessionStorage.updateUser(user);
      await SessionStorage.setProfileComplete(user.profileComplete);
      if (!mounted) return;
      _navigateToHome(user.isClient);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e is Exception ? e.toString().replaceFirst('Exception: ', '') : 'Erreur';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionStorage.getUser();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compléter le profil'),
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (user != null) ...[
                Text(
                  'Bonjour ${user.fullName}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Photo et ville sont requis pour compléter votre profil. L\'email de bienvenue sera envoyé à la complétion. Vous pourrez changer votre mot de passe si vous le souhaitez.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              const Text(
                'Photo de profil (prise avec l\'appareil photo)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isLoading ? null : _takePhoto,
                  borderRadius: BorderRadius.circular(60),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade400, width: 2),
                    ),
                    child: (_photoFile != null || _photoBase64 != null)
                      ? ClipOval(
                          child: _photoFile != null && _photoFile!.existsSync()
                              ? Image.file(
                                  _photoFile!,
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                )
                              : Image.memory(
                                  base64Decode(_photoBase64!),
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt_rounded, size: 40, color: Colors.grey.shade600),
                            const SizedBox(height: 4),
                            Text(
                              'Prendre une photo',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _villeController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Ville (requis pour compléter le profil)',
                  border: OutlineInputBorder(),
                  hintText: 'Ex: Paris',
                ),
              ),
              const SizedBox(height: 24),
              Material(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: _isLoading
                      ? null
                      : () => setState(() => _showChangePassword = !_showChangePassword),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Icon(
                          _showChangePassword ? Icons.expand_less : Icons.lock_rounded,
                          color: Colors.grey.shade700,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Changer mon mot de passe',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          _showChangePassword ? Icons.expand_less : Icons.expand_more,
                          color: Colors.grey.shade600,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_showChangePassword) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _oldPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Ancien mot de passe',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Nouveau mot de passe',
                    border: OutlineInputBorder(),
                    hintText: 'Min. 6 caractères',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirmer le nouveau mot de passe',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: TextStyle(fontSize: 13, color: Colors.red.shade700),
                ),
                if (_errorMessage!.toLowerCase().contains('réglage') ||
                    _errorMessage!.toLowerCase().contains('bloquée')) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => openAppSettings(),
                    icon: const Icon(Icons.settings, size: 18),
                    label: const Text('Ouvrir les réglages'),
                  ),
                ],
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading || !_canCompleteProfile ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
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
              const SizedBox(height: 12),
              TextButton(
                onPressed: _isLoading ? null : _skip,
                child: const Text('Passer pour l\'instant'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
