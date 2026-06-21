import 'package:call_log/call_log.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/sentri_database.dart';
import '../../../caller_id/domain/entities/caller_info.dart';
import '../../domain/entities/call_record.dart';
import '../../domain/repositories/call_log_repository.dart';

@Injectable(as: CallLogRepository)
class CallLogRepositoryImpl implements CallLogRepository {
  final SentriDatabase _db;
  const CallLogRepositoryImpl(this._db);

  @override
  Future<List<CallRecord>> getRecent({int limit = 100}) async {
    final entries = await CallLog.query(
      dateFrom: DateTime.now()
          .subtract(const Duration(days: 30))
          .millisecondsSinceEpoch,
    );

    final records = <CallRecord>[];
    for (final entry in entries.take(limit)) {
      final number = entry.number ?? '';
      final cached = await _db.getCachedCaller(number);

      records.add(CallRecord(
        phoneNumber: number,
        name: entry.name?.isNotEmpty == true ? entry.name : null,
        direction: _mapDirection(entry.callType),
        riskScore: cached != null ? (cached['risk_score'] as int? ?? 0) : 0,
        riskCategory: cached != null
            ? _parseCategory(cached['category'] as String? ?? 'unknown')
            : RiskCategory.unknown,
        wasBlocked: entry.callType == CallType.blocked,
        durationSeconds: entry.duration ?? 0,
        timestamp: DateTime.fromMillisecondsSinceEpoch(entry.timestamp ?? 0),
      ));
    }
    return records;
  }

  static CallDirection _mapDirection(CallType? type) => switch (type) {
        CallType.incoming => CallDirection.incoming,
        CallType.outgoing => CallDirection.outgoing,
        CallType.missed => CallDirection.missed,
        CallType.rejected => CallDirection.rejected,
        CallType.blocked => CallDirection.blocked,
        _ => CallDirection.unknown,
      };

  static RiskCategory _parseCategory(String raw) =>
      RiskCategory.values.firstWhere(
        (e) => e.name == raw,
        orElse: () => RiskCategory.unknown,
      );
}
