import 'package:flutter/material.dart';

import '../../../../core/app_strings.dart';

/// Journal / Historique des événements pour le client.
class ClientJournalScreen extends StatelessWidget {
  const ClientJournalScreen({super.key});

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
          AppStrings.journal,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _JournalTile(
            timeAgo: AppStrings.agoHours(2),
            title: AppStrings.lastIncident,
            description: '${AppStrings.perimeterPatrolAt('14h30')} ${AppStrings.noIncidentToReport}',
          ),
          const SizedBox(height: 12),
          _JournalTile(
            timeAgo: AppStrings.yesterdayAt('18h'),
            title: AppStrings.lastIncident,
            description: AppStrings.siteSecureSummary,
          ),
        ],
      ),
    );
  }
}

class _JournalTile extends StatelessWidget {
  final String timeAgo;
  final String title;
  final String description;

  const _JournalTile({
    required this.timeAgo,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
            timeAgo,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
