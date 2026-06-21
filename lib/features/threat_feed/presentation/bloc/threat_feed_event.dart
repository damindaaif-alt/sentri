import '../../../../features/caller_id/domain/entities/caller_info.dart';

sealed class ThreatFeedEvent {
  const ThreatFeedEvent();
}

final class ThreatFeedLoadRequested extends ThreatFeedEvent {
  const ThreatFeedLoadRequested();
}

final class ThreatFeedSyncRequested extends ThreatFeedEvent {
  const ThreatFeedSyncRequested();
}

final class ThreatFeedFilterChanged extends ThreatFeedEvent {
  final RiskCategory? category; // null = All
  const ThreatFeedFilterChanged(this.category);
}

final class ThreatFeedAutoBlockRequested extends ThreatFeedEvent {
  const ThreatFeedAutoBlockRequested();
}
