import '../entities/call_record.dart';

abstract interface class CallLogRepository {
  /// Returns recent call records, enriched with cached risk scores.
  Future<List<CallRecord>> getRecent({int limit = 100});
}
