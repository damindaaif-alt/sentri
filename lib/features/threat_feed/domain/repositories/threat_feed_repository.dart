import '../entities/threat_entry.dart';

abstract interface class ThreatFeedRepository {
  Future<List<ThreatEntry>> getLatest();
  Future<List<ThreatEntry>> sync();
  Future<void> autoBlockCritical();
  Future<DateTime?> lastSyncedAt();
}
