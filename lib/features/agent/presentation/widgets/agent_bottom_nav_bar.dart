import 'package:flutter/material.dart';

import '../../../../core/app_strings.dart';
import '../screens/agent_profile_screen.dart';
import '../screens/agent_sync_screen.dart';

/// Barre de navigation du bas pour l'agent (Accueil, Synchro, Historique, Profil).
/// À utiliser sur l'accueil, la liste historique et l'écran de détail historique.
class AgentBottomNavBar extends StatelessWidget {
  /// 0 = Accueil, 1 = Synchro, 2 = Historique, 3 = Profil
  final int currentIndex;
  /// true si on est sur l'écran détail d'un élément d'historique (tap Historique = pop).
  final bool isHistoryDetail;
  /// Fourni par l'accueil pour ouvrir l'écran Historique (évite import circulaire).
  final Widget Function()? historyScreenBuilder;

  const AgentBottomNavBar({
    super.key,
    required this.currentIndex,
    this.isHistoryDetail = false,
    this.historyScreenBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SizedBox(
        height: 72,
        child: Center(
          child: Container(
            width: 349,
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: const Color(0xFFB91C1C),
              borderRadius: BorderRadius.circular(35),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: AppStrings.home,
                  selected: currentIndex == 0,
                  onTap: () => _onAccueil(context),
                ),
                _NavItem(
                  icon: Icons.sync_rounded,
                  label: AppStrings.synchro,
                  selected: currentIndex == 1,
                  onTap: () => _onSynchro(context),
                ),
                _NavItem(
                  icon: Icons.history_rounded,
                  label: AppStrings.history,
                  selected: currentIndex == 2,
                  onTap: () => _onHistorique(context),
                ),
                _NavItem(
                  icon: Icons.person_rounded,
                  label: AppStrings.profile,
                  selected: currentIndex == 3,
                  onTap: () => _onProfile(context),
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

  void _onSynchro(BuildContext context) {
    if (currentIndex == 1) return;
    final nav = Navigator.of(context);
    nav.popUntil((route) => route.isFirst);
    nav.push(
      MaterialPageRoute(
        builder: (_) => AgentSyncScreen(
          bottomNavigationBar: AgentBottomNavBar(
            currentIndex: 1,
            historyScreenBuilder: historyScreenBuilder,
          ),
        ),
      ),
    );
  }

  void _onHistorique(BuildContext context) {
    if (currentIndex == 2) {
      if (isHistoryDetail) {
        Navigator.of(context).pop();
      }
      return;
    }
    final nav = Navigator.of(context);
    nav.popUntil((route) => route.isFirst);
    final builder = historyScreenBuilder;
    if (builder != null) {
      nav.push(
        MaterialPageRoute(builder: (_) => builder()),
      );
    }
  }

  void _onProfile(BuildContext context) {
    if (currentIndex == 3) return;
    final nav = Navigator.of(context);
    nav.popUntil((route) => route.isFirst);
    nav.push(
      MaterialPageRoute(
        builder: (_) => AgentProfileScreen(
          historyScreenBuilder: historyScreenBuilder,
          bottomNavBar: AgentBottomNavBar(
            currentIndex: 3,
            historyScreenBuilder: historyScreenBuilder,
          ),
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
    final color = selected ? Colors.white : Colors.white.withOpacity(0.55);
    final content = Column(
      mainAxisSize: MainAxisSize.min,
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
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: content,
        ),
      ),
    );
  }
}

// L'onglet "Map" a été remplacé par "Synchro" (cf. cahier des charges : cartographie = interface supervision, pas app agent).

