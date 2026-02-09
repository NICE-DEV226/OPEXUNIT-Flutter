import 'package:flutter/material.dart';

import '../../../../core/app_strings.dart';
import '../../../../core/auth/session_storage.dart';
import '../../../../core/network/services/site_api_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../agent/data/models/site_model.dart';
import '../widgets/client_bottom_nav_bar.dart';
import 'client_settings_screen.dart';
import 'client_site_detail_screen.dart';

/// Écran Statut client "Mes Sites" : liste des sites du client (GET /api/sites?client_id=).
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
  final _searchController = TextEditingController();
  List<SiteModel> _sites = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSites();
  }

  Future<void> _loadSites() async {
    final user = SessionStorage.getUser();
    if (user == null) {
      setState(() {
        _loading = false;
        _sites = [];
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await SiteApiService.getAll(clientId: user.id);
      if (mounted) {
        setState(() {
          _sites = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e is Exception ? e.toString().replaceFirst('Exception: ', '') : '$e';
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionStorage.getUser();
    final userName = user?.fullName ?? 'Client';
    final securedCount = _sites.length;
    final alertsCount = 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context, userName),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primaryRed))
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildSearchBar(),
                              const SizedBox(height: 20),
                              _buildSummaryCards(securedCount, alertsCount),
                              const SizedBox(height: 24),
                              ..._sites.map((site) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _SiteCard(
                                      site: site,
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => ClientSiteDetailScreen(
                                              siteId: site.id,
                                              siteName: site.name,
                                              siteLocation: site.description ?? (site.hasLocation ? '${site.latitude!.toStringAsFixed(4)}, ${site.longitude!.toStringAsFixed(4)}' : ''),
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

  Widget _buildHeader(BuildContext context, String userName) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.primaryRed.withValues(alpha: 0.15),
            child: Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : '?',
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
                  AppStrings.helloClient(userName),
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

class _SiteCard extends StatelessWidget {
  final SiteModel site;
  final VoidCallback onTap;

  const _SiteCard({required this.site, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
                Icon(
                  Icons.check_circle_rounded,
                  size: 20,
                  color: const Color(0xFF16A34A),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        site.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        site.description ?? (site.hasLocation ? '${site.latitude!.toStringAsFixed(4)}, ${site.longitude!.toStringAsFixed(4)}' : ''),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppStrings.agentsOnSite,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
