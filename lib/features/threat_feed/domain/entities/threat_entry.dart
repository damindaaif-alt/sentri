import 'package:equatable/equatable.dart';

import '../../../caller_id/domain/entities/caller_info.dart';

class ThreatEntry extends Equatable {
  final String id;
  final String phoneNumber;
  final RiskCategory category;
  final int riskScore;
  final String? region;
  final int reportCount;
  final bool isTrending;
  final bool isAutoBlocked;
  final DateTime firstSeen;
  final DateTime lastSeen;
  final List<String> tags;

  const ThreatEntry({
    required this.id,
    required this.phoneNumber,
    required this.category,
    required this.riskScore,
    this.region,
    required this.reportCount,
    this.isTrending = false,
    this.isAutoBlocked = false,
    required this.firstSeen,
    required this.lastSeen,
    this.tags = const [],
  });

  bool get isCritical => riskScore >= 80;

  @override
  List<Object?> get props => [
        id, phoneNumber, category, riskScore, region,
        reportCount, isTrending, isAutoBlocked, firstSeen, lastSeen, tags,
      ];
}
