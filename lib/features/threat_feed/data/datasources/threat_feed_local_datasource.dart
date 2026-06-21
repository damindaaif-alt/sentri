import 'package:injectable/injectable.dart';

import '../../../../core/database/sentri_database.dart';
import '../models/threat_entry_model.dart';

abstract interface class ThreatFeedLocalDataSource {
  Future<List<ThreatEntryModel>> getAll();
  Future<void> replaceAll(List<ThreatEntryModel> entries);
  Future<DateTime?> lastSyncedAt();
  Future<void> setAutoBlocked(String id, bool value);
}

@Injectable(as: ThreatFeedLocalDataSource)
class ThreatFeedLocalDataSourceImpl implements ThreatFeedLocalDataSource {
  final SentriDatabase _db;
  const ThreatFeedLocalDataSourceImpl(this._db);

  @override
  Future<List<ThreatEntryModel>> getAll() async {
    final db = await _db.database;
    final rows = await db.query('threat_entries', orderBy: 'risk_score DESC');
    return rows.map(ThreatEntryModel.fromDb).toList();
  }

  @override
  Future<void> replaceAll(List<ThreatEntryModel> entries) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.delete('threat_entries');
      for (final e in entries) {
        await txn.insert('threat_entries', e.toJson());
      }
    });
    await _db.setSetting('threat_feed_synced_at',
        DateTime.now().millisecondsSinceEpoch.toString());
  }

  @override
  Future<DateTime?> lastSyncedAt() async {
    final raw = await _db.getSetting('threat_feed_synced_at');
    if (raw == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(int.parse(raw));
  }

  @override
  Future<void> setAutoBlocked(String id, bool value) async {
    final db = await _db.database;
    await db.update(
      'threat_entries',
      {'is_auto_blocked': value ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
