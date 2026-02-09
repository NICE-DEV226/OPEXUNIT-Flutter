import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/auth/session_storage.dart';
import '../../../agent/presentation/screens/agent_home_screen.dart';
import '../../../client/presentation/screens/client_home_screen.dart';
import 'complete_profile_screen.dart';
import 'login_screen.dart';

/// Splash : après chargement de la session, redirige vers
/// - Login si non connecté
/// - Compléter le profil si connecté mais profil incomplet
/// - Accueil Agent ou Client selon le rôle si connecté et profil complété.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), _navigate);
  }

  void _navigate() {
    if (!mounted) return;
    if (!SessionStorage.isLoggedIn) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }
    if (!SessionStorage.isProfileComplete) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const CompleteProfileScreen()),
      );
      return;
    }
    final role = SessionStorage.getRole();
    if (role == 'client') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ClientHomeScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AgentHomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/logos/logo.png',
                width: 160,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 24),
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                  children: [
                    TextSpan(
                      text: 'OPEX',
                      style: TextStyle(color: Color(0xFFE53935)),
                    ),
                    TextSpan(
                      text: 'UNIT',
                      style: TextStyle(color: Colors.black),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
