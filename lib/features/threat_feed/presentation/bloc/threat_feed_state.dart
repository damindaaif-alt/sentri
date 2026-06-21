import '../../../../features/caller_id/domain/entities/caller_info.dart';
import '../../domain/entities/threat_entry.dart';

sealed class ThreatFeedState {
  const ThreatFeedState();
}

final class ThreatFeedInitial extends ThreatFeedState {
  const ThreatFeedInitial();
}

final class ThreatFeedLoading extends ThreatFeedState {
  const ThreatFeedLoading();
}

final class ThreatFeedLoaded extends ThreatFeedState {
  final List<ThreatEntry> allEntries;
  final RiskCategory? activeFilter;
  final DateTime? syncedAt;
  final bool isSyncing;
  final bool autoBlockEnabled;

  const ThreatFeedLoaded({
    required this.allEntries,
    this.activeFilter,
    this.syncedAt,
    this.isSyncing = false,
    this.autoBlockEnabled = false,
  });

  List<ThreatEntry> get filtered => activeFilter == null
      ? allEntries
      : allEntries.where((e) => e.category == activeFilter).toList();

  int get criticalCount => allEntries.where((e) => e.isCritical).length;
  int get trendingCount => allEntries.where((e) => e.isTrending).length;

  ThreatFeedLoaded copyWith({
    List<ThreatEntry>? allEntries,
    RiskCategory? Function()? activeFilter,
    DateTime? syncedAt,
    bool? isSyncing,
    bool? autoBlockEnabled,
  }) =>
      ThreatFeedLoaded(
        allEntries: allEntries ?? this.allEntries,
        activeFilter:
            activeFilter != null ? activeFilter() : this.activeFilter,
        syncedAt: syncedAt ?? this.syncedAt,
        isSyncing: isSyncing ?? this.isSyncing,
        autoBlockEnabled: autoBlockEnabled ?? this.autoBlockEnabled,
      );
}

final class ThreatFeedError extends ThreatFeedState {
  final String message;
  const ThreatFeedError(this.message);
}
