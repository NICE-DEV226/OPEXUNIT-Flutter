import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Types d'actions mises en file pour synchronisation ultérieure.
const String kActionPatrolStart = 'patrol_start';
const String kActionPatrolCheckpoint = 'patrol_checkpoint';
const String kActionPatrolGps = 'patrol_gps';
const String kActionPatrolEnd = 'patrol_end';
const String kActionInterventionClose = 'intervention_close';
const String kActionAlertTrigger = 'alert_trigger';

/// Stockage local SQLite : file d'actions en attente + cache patrouilles.
class OfflineStorage {
  OfflineStorage._();

  static Database? _db;
  static const String _dbName = 'opexunit_offline.db';
  // v3 : ajout cache sites client (cached_client_sites)
  static const int _dbVersion = 3;

  static Future<Database> get database async {
    if (_db != null && _db!.isOpen) return _db!;
    _db = await _open();
    return _db!;
  }

  static Future<Database> _open() async {
    String? path;
    try {
      final dir = await getApplicationDocumentsDirectory();
      if (dir.path.isNotEmpty) path = join(dir.path, _dbName);
    } catch (e) {
      if (kDebugMode) debugPrint('[OfflineStorage] getApplicationDocumentsDirectory failed: $e');
    }
    if (path == null || path.isEmpty) {
      try {
        final tmp = await getTemporaryDirectory();
        if (tmp.path.isNotEmpty) path = join(tmp.path, _dbName);
      } catch (e2) {
        if (kDebugMode) debugPrint('[OfflineStorage] getTemporaryDirectory failed: $e2');
      }
    }
    if (path == null || path.isEmpty) {
      if (kDebugMode) debugPrint('[OfflineStorage] using in-memory database (path_provider unavailable)');
      path = inMemoryDatabasePath;
    } else if (kDebugMode) {
      debugPrint('[OfflineStorage] open $path');
    }
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS cached_dashboard (
          agent_id TEXT PRIMARY KEY,
          data_json TEXT NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS cached_client_sites (
          client_id TEXT PRIMARY KEY,
          data_json TEXT NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');
    }
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE pending_actions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action_type TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        synced_at INTEGER NULL,
        error TEXT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE cached_patrol_list (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        agent_id TEXT NOT NULL,
        data_json TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE cached_patrol_detail (
        patrol_id TEXT PRIMARY KEY,
        data_json TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE offline_patrol_state (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
    if (version >= 2) {
      await db.execute('''
        CREATE TABLE cached_dashboard (
          agent_id TEXT PRIMARY KEY,
          data_json TEXT NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');
    }
    if (version >= 3) {
      await db.execute('''
        CREATE TABLE cached_client_sites (
          client_id TEXT PRIMARY KEY,
          data_json TEXT NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');
    }
  }

  // ---------- Pending actions ----------

  static Future<int> enqueueAction(String actionType, Map<String, dynamic> payload) async {
    final db = await database;
    final id = await db.insert('pending_actions', {
      'action_type': actionType,
      'payload_json': jsonEncode(payload),
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'synced_at': null,
      'error': null,
    });
    if (kDebugMode) debugPrint('[OfflineStorage] enqueue $actionType id=$id');
    return id;
  }

  static Future<List<Map<String, dynamic>>> getPendingActions() async {
    final db = await database;
    final rows = await db.query(
      'pending_actions',
      where: 'synced_at IS NULL',
      orderBy: 'created_at ASC',
    );
    return rows.map((r) {
      return {
        'id': r['id'] as int?,
        'action_type': r['action_type'] as String? ?? '',
        'payload': jsonDecode(r['payload_json'] as String? ?? '{}') as Map<String, dynamic>,
        'created_at': r['created_at'] as int? ?? 0,
      };
    }).toList();
  }

  static Future<void> markActionSynced(int id) async {
    final db = await database;
    await db.update(
      'pending_actions',
      {'synced_at': DateTime.now().millisecondsSinceEpoch, 'error': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> markActionError(int id, String error) async {
    final db = await database;
    await db.update(
      'pending_actions',
      {'error': error},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<int> getPendingCount() async {
    final db = await database;
    final r = await db.rawQuery(
      'SELECT COUNT(*) as c FROM pending_actions WHERE synced_at IS NULL',
    );
    return (r.first['c'] as int?) ?? 0;
  }

  static Future<void> deleteSyncedActions() async {
    final db = await database;
    await db.delete('pending_actions', where: 'synced_at IS NOT NULL');
  }

  // ---------- Cache patrol list ----------

  static Future<void> cachePatrolList(String agentId, List<Map<String, dynamic>> list) async {
    final db = await database;
    await db.insert(
      'cached_patrol_list',
      {
        'id': 1,
        'agent_id': agentId,
        'data_json': jsonEncode(list),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Map<String, dynamic>>?> getCachedPatrolList(String agentId) async {
    final db = await database;
    final rows = await db.query(
      'cached_patrol_list',
      where: 'agent_id = ?',
      whereArgs: [agentId],
    );
    if (rows.isEmpty) return null;
    final data = rows.first['data_json'] as String?;
    if (data == null || data.isEmpty) return null;
    final list = jsonDecode(data);
    if (list is! List) return null;
    return list.whereType<Map<String, dynamic>>().toList();
  }

  // ---------- Cache patrol detail ----------

  static Future<void> cachePatrolDetail(String patrolId, Map<String, dynamic> data) async {
    final db = await database;
    await db.insert(
      'cached_patrol_detail',
      {
        'patrol_id': patrolId,
        'data_json': jsonEncode(data),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<Map<String, dynamic>?> getCachedPatrolDetail(String patrolId) async {
    final db = await database;
    final rows = await db.query(
      'cached_patrol_detail',
      where: 'patrol_id = ?',
      whereArgs: [patrolId],
    );
    if (rows.isEmpty) return null;
    final data = rows.first['data_json'] as String?;
    if (data == null || data.isEmpty) return null;
    final decoded = jsonDecode(data);
    return decoded is Map<String, dynamic> ? decoded : null;
  }

  // ---------- Offline patrol state (patrouille "en cours" démarrée hors ligne) ----------

  static Future<void> setOfflinePatrolState(String key, String value) async {
    final db = await database;
    await db.insert(
      'offline_patrol_state',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<String?> getOfflinePatrolState(String key) async {
    final db = await database;
    final rows = await db.query(
      'offline_patrol_state',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  static Future<void> removeOfflinePatrolState(String key) async {
    final db = await database;
    await db.delete('offline_patrol_state', where: 'key = ?', whereArgs: [key]);
  }

  // ---------- Cache dashboard (patrouilles + interventions) pour lecture hors ligne ----------

  static Future<void> cacheDashboard(String agentId, Map<String, dynamic> data) async {
    final db = await database;
    await db.insert(
      'cached_dashboard',
      {
        'agent_id': agentId,
        'data_json': jsonEncode(data),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<Map<String, dynamic>?> getCachedDashboard(String agentId) async {
    final db = await database;
    final rows = await db.query(
      'cached_dashboard',
      where: 'agent_id = ?',
      whereArgs: [agentId],
    );
    if (rows.isEmpty) return null;
    final data = rows.first['data_json'] as String?;
    if (data == null || data.isEmpty) return null;
    final decoded = jsonDecode(data);
    return decoded is Map<String, dynamic> ? decoded : null;
  }

  // ---------- Cache sites client (dashboard client hors ligne) ----------

  static Future<void> cacheClientSites(String clientId, List<Map<String, dynamic>> list) async {
    final db = await database;
    await db.insert(
      'cached_client_sites',
      {
        'client_id': clientId,
        'data_json': jsonEncode(list),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Map<String, dynamic>>?> getCachedClientSites(String clientId) async {
    final db = await database;
    final rows = await db.query(
      'cached_client_sites',
      where: 'client_id = ?',
      whereArgs: [clientId],
    );
    if (rows.isEmpty) return null;
    final data = rows.first['data_json'] as String?;
    if (data == null || data.isEmpty) return null;
    final list = jsonDecode(data);
    if (list is! List) return null;
    return list.whereType<Map<String, dynamic>>().toList();
  }
}
