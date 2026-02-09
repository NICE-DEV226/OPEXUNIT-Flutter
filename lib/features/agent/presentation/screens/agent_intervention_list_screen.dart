import 'package:flutter/material.dart';

import '../../../../core/app_strings.dart';
import '../../../../core/auth/session_storage.dart';
import '../../../../core/network/services/intervention_api_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/intervention_model.dart';
import 'agent_intervention_detail_screen.dart';

class AgentInterventionListScreen extends StatefulWidget {
  const AgentInterventionListScreen({super.key});

  @override
  State<AgentInterventionListScreen> createState() => _AgentInterventionListScreenState();
}

class _AgentInterventionListScreenState extends State<AgentInterventionListScreen> {
  List<InterventionModel> _list = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final all = await InterventionApiService.getHistory();
      final user = SessionStorage.getUser();
      // Uniquement les interventions où l'utilisateur fait partie des agents_envoyes (assignés)
      final list = user != null
          ? all.where((i) => i.agentIds.contains(user.id)).toList()
          : <InterventionModel>[];
      if (mounted) {
        setState(() {
          _list = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e is Exception ? e.toString().replaceFirst('Exception: ', '') : '$e';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          AppStrings.interventions,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryRed))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black87)),
                        const SizedBox(height: 16),
                        TextButton(onPressed: _load, child: const Text('Réessayer')),
                      ],
                    ),
                  ),
                )
              : _list.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            AppStrings.noInterventions,
                            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.primaryRed,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: _list.length,
                        itemBuilder: (context, i) {
                          final item = _list[i];
                          return _InterventionTile(
                            intervention: item,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => AgentInterventionDetailScreen(interventionId: item.id),
                                ),
                              ).then((_) => _load());
                            },
                          );
                        },
                      ),
                    ),
    );
  }
}

class _InterventionTile extends StatelessWidget {
  const _InterventionTile({required this.intervention, required this.onTap});

  final InterventionModel intervention;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isOpen = intervention.isOpen;
    final isInProgress = intervention.isInProgress;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: (isOpen ? const Color(0xFFF59E0B) : isInProgress ? Colors.blue : Colors.grey)
                .withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isOpen ? const Color(0xFFF59E0B) : isInProgress ? Colors.blue : Colors.grey,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (isOpen ? const Color(0xFFF59E0B) : isInProgress ? Colors.blue : Colors.grey)
                      .withOpacity(0.25),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.emergency_rounded,
                  color: isOpen ? const Color(0xFFF59E0B) : isInProgress ? Colors.blue : Colors.grey,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      intervention.displayTitle,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${intervention.type.label} • ${intervention.origine.label}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                    if (intervention.createdAt != null)
                      Text(
                        _formatDate(intervention.createdAt!),
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.black54),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}
