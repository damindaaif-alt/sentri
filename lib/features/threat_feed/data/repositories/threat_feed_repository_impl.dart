import 'package:injectable/injectable.dart';

import '../../../../core/database/sentri_database.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/threat_entry.dart';
import '../../domain/repositories/threat_feed_repository.dart';
import '../datasources/threat_feed_local_datasource.dart';
import '../datasources/threat_feed_remote_datasource.dart';

@Injectable(as: ThreatFeedRepository)
class ThreatFeedRepositoryImpl implements ThreatFeedRepository {
  final ThreatFeedRemoteDataSource _remote;
  final ThreatFeedLocalDataSource _local;

  const ThreatFeedRepositoryImpl(this._remote, this._local);

  @override
  Future<List<ThreatEntry>> getLatest() async {
    final cached = await _local.getAll();
    if (cached.isNotEmpty) return cached.map((e) => e.toDomain()).toList();
    return sync();
  }

  @override
  Future<List<ThreatEntry>> sync() async {
    final models = await _remote.fetchLatest();
    await _local.replaceAll(models);
    return models.map((e) => e.toDomain()).toList();
  }

  @override
  Future<void> autoBlockCritical() async {
    final entries = await _local.getAll();
    final db = getIt<SentriDatabase>();
    for (final e in entries) {
      if (e.riskScore >= 80) {
        await db.blockNumber(e.phoneNumber, label: _labelFor(e));
        await _local.setAutoBlocked(e.id, true);
      }
    }
  }

  @override
  Future<DateTime?> lastSyncedAt() => _local.lastSyncedAt();

  static String _labelFor(e) =>
      '${e.category[0].toUpperCase()}${e.category.substring(1)} — auto-blocked by Sentri';
}
