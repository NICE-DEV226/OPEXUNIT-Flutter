import 'package:flutter/material.dart';

import '../../../../core/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/client_bottom_nav_bar.dart';
import 'client_settings_screen.dart';
import 'client_site_detail_screen.dart';

/// Identifiant de site pour résolution des libellés (FR/EN).
enum _SiteId { entrepotNord, entrepotSud, laboRD }

/// Donnée mock pour une carte site.
class _SiteItem {
  final _SiteId id;
  final bool hasIncident;
  final int agentCount;
  final bool reinforcementRequired;

  const _SiteItem({
    required this.id,
    required this.hasIncident,
    required this.agentCount,
    this.reinforcementRequired = false,
  });
}

/// Écran Statut client "Mes Sites" : synthèse sécurisés/alertes, liste des sites avec statut.
class ClientStatusScreen extends StatefulWidget {
  final ClientBottomNavBar bottomNavBar;

  const ClientStatusScreen({
    super.key,
    required this.bottomNavBar,
  });

  @override
  State<ClientStatusScreen> createState() => _ClientStatusScreenState();
}

class _ClientStatusScreenState extends State<ClientStatusScreen> {
  static const String _userName = 'Marc';
  final _searchController = TextEditingController();
  final _sites = const [
    _SiteItem(
      id: _SiteId.entrepotNord,
      hasIncident: true,
      agentCount: 1,
      reinforcementRequired: true,
    ),
    _SiteItem(
      id: _SiteId.entrepotSud,
      hasIncident: false,
      agentCount: 2,
    ),
    _SiteItem(
      id: _SiteId.laboRD,
      hasIncident: false,
      agentCount: 5,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const securedCount = 4;
    const alertsCount = 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSearchBar(),
                    const SizedBox(height: 20),
                    _buildSummaryCards(securedCount, alertsCount),
                    const SizedBox(height: 24),
                    ..._sites.map((s) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _SiteCard(
                            item: s,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ClientSiteDetailScreen(
                                    siteName: _siteName(s.id),
                                    siteLocation: _siteLocation(s.id),
                                  ),
                                ),
                              );
                            },
                          ),
                        )),
                  ],
                ),
              ),
            ),
            widget.bottomNavBar,
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.primaryRed.withValues(alpha: 0.15),
            child: Text(
              _userName.isNotEmpty ? _userName[0].toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryRed,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.helloClient(_userName),
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.mySites,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF374151), size: 26),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ClientSettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: AppStrings.searchSitePlaceholder,
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 15),
        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF9CA3AF), size: 22),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildSummaryCards(int secured, int alerts) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: AppStrings.securedLabel,
            count: secured,
            isPositive: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            label: AppStrings.alertsLabel,
            count: alerts,
            isPositive: false,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final int count;
  final bool isPositive;

  const _SummaryCard({
    required this.label,
    required this.count,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isPositive ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2);
    final fg = isPositive ? const Color(0xFF16A34A) : AppColors.primaryRed;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: fg,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

String _siteName(_SiteId id) {
  switch (id) {
    case _SiteId.entrepotNord:
      return AppStrings.entrepotNord;
    case _SiteId.entrepotSud:
      return AppStrings.entrepotSud;
    case _SiteId.laboRD:
      return AppStrings.laboRD;
  }
}

String _siteLocation(_SiteId id) {
  switch (id) {
    case _SiteId.entrepotNord:
      return AppStrings.zoneIndustrielleA;
    case _SiteId.entrepotSud:
      return AppStrings.zoneLogistiqueSud;
    case _SiteId.laboRD:
      return AppStrings.campusTech;
  }
}

class _SiteCard extends StatelessWidget {
  final _SiteItem item;
  final VoidCallback onTap;

  const _SiteCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasIncident = item.hasIncident;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(
            color: hasIncident ? AppColors.primaryRed : Colors.transparent,
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            hasIncident ? Icons.error_rounded : Icons.check_circle_rounded,
                            size: 20,
                            color: hasIncident ? AppColors.primaryRed : const Color(0xFF16A34A),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            hasIncident
                                ? AppStrings.incidentInProgress
                                : AppStrings.secure,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: hasIncident ? AppColors.primaryRed : const Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _siteName(item.id),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _siteLocation(item.id),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: item.reinforcementRequired
                              ? AppColors.primaryRed.withValues(alpha: 0.1)
                              : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.people_outline_rounded,
                              size: 16,
                              color: item.reinforcementRequired
                                  ? AppColors.primaryRed
                                  : const Color(0xFF6B7280),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              item.reinforcementRequired
                                  ? AppStrings.agentReinforcement(item.agentCount)
                                  : AppStrings.agentsCount(item.agentCount),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: item.reinforcementRequired
                                    ? AppColors.primaryRed
                                    : const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 80,
                    height: 80,
                    color: const Color(0xFFE5E7EB),
                    child: Icon(
                      Icons.warehouse_rounded,
                      size: 36,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
