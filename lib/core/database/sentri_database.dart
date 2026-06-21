import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

@singleton
class SentriDatabase {
  static const _dbName = 'sentri.db';
  static const _dbVersion = 2;

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = join(await getDatabasesPath(), _dbName);
    return openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE caller_cache (
        phone_number TEXT PRIMARY KEY,
        payload TEXT NOT NULL,
        cached_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE blocked_numbers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        phone_number TEXT UNIQUE NOT NULL,
        label TEXT,
        is_permanent INTEGER NOT NULL DEFAULT 1,
        blocked_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE call_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        phone_number TEXT NOT NULL,
        name TEXT,
        risk_score INTEGER NOT NULL DEFAULT 0,
        risk_category TEXT NOT NULL DEFAULT 'unknown',
        was_blocked INTEGER NOT NULL DEFAULT 0,
        duration_seconds INTEGER NOT NULL DEFAULT 0,
        timestamp INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE user_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
    await _createThreatEntriesTable(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) await _createThreatEntriesTable(db);
  }

  Future<void> _createThreatEntriesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS threat_entries (
        id TEXT PRIMARY KEY,
        phone_number TEXT NOT NULL,
        category TEXT NOT NULL,
        risk_score INTEGER NOT NULL,
        region TEXT,
        report_count INTEGER NOT NULL DEFAULT 0,
        is_trending INTEGER NOT NULL DEFAULT 0,
        is_auto_blocked INTEGER NOT NULL DEFAULT 0,
        first_seen_ms INTEGER NOT NULL,
        last_seen_ms INTEGER NOT NULL,
        tags TEXT
      )
    ''');
  }

  // --- Caller Cache ---

  Future<Map<String, dynamic>?> getCachedCaller(
    String phoneNumber, {
    Duration ttl = const Duration(hours: 1),
  }) async {
    final db = await database;
    final cutoff =
        DateTime.now().subtract(ttl).millisecondsSinceEpoch;
    final rows = await db.query(
      'caller_cache',
      where: 'phone_number = ? AND cached_at > ?',
      whereArgs: [phoneNumber, cutoff],
    );
    if (rows.isEmpty) return null;
    return jsonDecode(rows.first['payload'] as String) as Map<String, dynamic>;
  }

  Future<void> cacheCaller(String phoneNumber, Map<String, dynamic> payload) async {
    final db = await database;
    await db.insert(
      'caller_cache',
      {
        'phone_number': phoneNumber,
        'payload': jsonEncode(payload),
        'cached_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> invalidateCallerCache(String phoneNumber) async {
    final db = await database;
    await db.delete('caller_cache',
        where: 'phone_number = ?', whereArgs: [phoneNumber]);
  }

  Future<int> clearAllCallerCache() async {
    final db = await database;
    return db.delete('caller_cache');
  }

  Future<List<Map<String, dynamic>>> getAllCachedCallers({int limit = 20}) async {
    final db = await database;
    final rows = await db.query(
      'caller_cache',
      orderBy: 'cached_at DESC',
      limit: limit,
    );
    return rows.map((r) {
      final payload = jsonDecode(r['payload'] as String) as Map<String, dynamic>;
      return {'phone_number': r['phone_number'], ...payload};
    }).toList();
  }

  // --- Blocked Numbers ---

  Future<List<Map<String, dynamic>>> getAllBlockedNumbers() async {
    final db = await database;
    return db.query('blocked_numbers', orderBy: 'blocked_at DESC');
  }

  Future<bool> isBlocked(String phoneNumber) async {
    final db = await database;
    final rows = await db.query(
      'blocked_numbers',
      where: 'phone_number = ?',
      whereArgs: [phoneNumber],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<void> blockNumber(String phoneNumber, {String? label}) async {
    final db = await database;
    await db.insert(
      'blocked_numbers',
      {
        'phone_number': phoneNumber,
        'label': label,
        'is_permanent': 1,
        'blocked_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> unblockNumber(String phoneNumber) async {
    final db = await database;
    await db.delete('blocked_numbers',
        where: 'phone_number = ?', whereArgs: [phoneNumber]);
  }

  // --- Settings ---

  Future<String?> getSetting(String key) async {
    final db = await database;
    final rows = await db.query('user_settings',
        where: 'key = ?', whereArgs: [key]);
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'user_settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> close() async => _db?.close();
}
