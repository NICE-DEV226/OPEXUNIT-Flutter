import '../../../auth/data/models/user_model.dart';
import 'intervention_model.dart';
import 'patrol_model.dart';

/// Réponse type "getUserById" / "me" : user + patrouille en cours, interventions, site, zone, alertes.
class AgentDashboardModel {
  final UserModel user;
  final PatrolModel? currentPatrol;
  final List<InterventionModel> interventions;
  final String? siteId;
  final String? siteName;
  final String? zoneId;
  final String? zoneName;
  final int alertsLaunched;

  const AgentDashboardModel({
    required this.user,
    this.currentPatrol,
    this.interventions = const [],
    this.siteId,
    this.siteName,
    this.zoneId,
    this.zoneName,
    this.alertsLaunched = 0,
  });

  bool get hasPatrol => currentPatrol != null && (currentPatrol!.isPlanned || currentPatrol!.isOngoing);

  /// Interventions où l'utilisateur fait partie des agents_envoyes (assignés à lui).
  List<InterventionModel> get interventionsAssignedToMe =>
      interventions.where((i) => i.agentIds.contains(user.id)).toList();

  /// Parmi celles assignées à l'utilisateur : ouvertes ou en cours (pas clôturées).
  List<InterventionModel> get activeInterventions =>
      interventionsAssignedToMe.where((i) => i.isOpen || i.isInProgress).toList();

  bool get hasIntervention => activeInterventions.isNotEmpty;

  factory AgentDashboardModel.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    final user = userJson is Map<String, dynamic>
        ? UserModel.fromJson(userJson)
        : UserModel.fromJson(<String, dynamic>{});

    final patrolData = json['currentPatrol'] ?? json['patrol'];
    final currentPatrol = patrolData is Map<String, dynamic>
        ? PatrolModel.fromJson(patrolData)
        : null;

    final interventionsList = json['interventions'] as List? ?? [];
    final interventions = interventionsList
        .whereType<Map<String, dynamic>>()
        .map((e) => InterventionModel.fromJson(e))
        .toList();

    final site = json['site'];
    String? siteId;
    String? siteName;
    if (site is Map) {
      siteId = _oid(site['_id']) ?? _oid(site['id']);
      siteName = site['name'] as String? ?? site['libelle'] as String?;
    } else if (site is String) {
      siteId = site;
    }

    final zone = json['zone'];
    String? zoneId;
    String? zoneName;
    if (zone is Map) {
      zoneId = _oid(zone['_id']) ?? _oid(zone['id']);
      zoneName = zone['name'] as String? ?? zone['libelle'] as String?;
    } else if (zone is String) {
      zoneId = zone;
    }

    final alerts = json['alertsLaunched'] ?? json['alerts'] ?? json['alertsCount'];
    final alertsLaunched = alerts is int
        ? alerts
        : (alerts is List ? alerts.length : 0);

    return AgentDashboardModel(
      user: user,
      currentPatrol: currentPatrol,
      interventions: interventions,
      siteId: siteId ?? json['site_affecte']?.toString(),
      siteName: siteName,
      zoneId: zoneId ?? json['zone_affectee']?.toString(),
      zoneName: zoneName,
      alertsLaunched: alertsLaunched,
    );
  }

  static String? _oid(dynamic v) {
    if (v == null) return null;
    if (v is String) return v;
    if (v is Map) return (v['\$oid'] ?? v['_id'])?.toString();
    return v.toString();
  }
}
