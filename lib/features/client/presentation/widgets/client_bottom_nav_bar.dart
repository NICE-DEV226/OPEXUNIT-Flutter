import 'package:flutter/material.dart';

import '../../../../core/app_strings.dart';
import '../screens/client_profile_screen.dart';
import '../screens/client_status_screen.dart';

/// Barre de navigation du bas pour le client (Accueil, Statut, Profil).
class ClientBottomNavBar extends StatelessWidget {
  /// 0 = Accueil, 1 = Statut, 2 = Profil
  final int currentIndex;

  const ClientBottomNavBar({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SizedBox(
        height: 72,
        child: Center(
          child: Container(
            width: 320,
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFB91C1C),
              borderRadius: BorderRadius.circular(35),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: AppStrings.clientHome,
                  selected: currentIndex == 0,
                  onTap: () => _onAccueil(context),
                ),
                _NavItem(
                  icon: Icons.shield_rounded,
                  label: AppStrings.clientStatus,
                  selected: currentIndex == 1,
                  onTap: () => _onStatut(context),
                ),
                _NavItem(
                  icon: Icons.person_rounded,
                  label: AppStrings.clientProfile,
                  selected: currentIndex == 2,
                  onTap: () => _onProfil(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onAccueil(BuildContext context) {
    if (currentIndex == 0) return;
    final nav = Navigator.of(context);
    nav.popUntil((route) => route.isFirst);
  }

  void _onStatut(BuildContext context) {
    if (currentIndex == 1) return;
    final nav = Navigator.of(context);
    nav.popUntil((route) => route.isFirst);
    nav.push(
      MaterialPageRoute(
        builder: (_) => ClientStatusScreen(
          bottomNavBar: ClientBottomNavBar(currentIndex: 1),
        ),
      ),
    );
  }

  void _onProfil(BuildContext context) {
    if (currentIndex == 2) return;
    final nav = Navigator.of(context);
    nav.popUntil((route) => route.isFirst);
    nav.push(
      MaterialPageRoute(
        builder: (_) => ClientProfileScreen(
          bottomNavBar: ClientBottomNavBar(currentIndex: 2),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : Colors.white.withValues(alpha: 0.55);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
              SizedBox(height: selected ? 6 : 0),
              if (selected)
                Container(
                  width: 24,
                  height: 3,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
