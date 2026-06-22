import '../../../../core/error/failures.dart';
import '../entities/caller_info.dart';

abstract interface class CallerIdRepository {
  /// Look up a phone number. Hits local cache first, falls back to cloud.
  /// Returns the caller info plus an optional failure if the network call failed
  /// (the CallerInfo is always valid — an unknown placeholder on failure).
  Future<(CallerInfo, Failure?)> lookup(String phoneNumber);

  /// Submit an anonymous report for a number.
  Future<void> reportNumber({
    required String phoneNumber,
    required RiskCategory category,
    String? note,
  });

  /// Invalidate the local cache entry for a number.
  Future<void> invalidateCache(String phoneNumber);
}
