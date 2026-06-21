import 'package:equatable/equatable.dart';

import '../../../caller_id/domain/entities/caller_info.dart';

enum CallDirection { incoming, outgoing, missed, rejected, blocked, unknown }

class CallRecord extends Equatable {
  final String phoneNumber;
  final String? name;
  final CallDirection direction;
  final int riskScore;
  final RiskCategory riskCategory;
  final bool wasBlocked;
  final int durationSeconds;
  final DateTime timestamp;

  const CallRecord({
    required this.phoneNumber,
    this.name,
    required this.direction,
    this.riskScore = 0,
    this.riskCategory = RiskCategory.unknown,
    this.wasBlocked = false,
    required this.durationSeconds,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [
        phoneNumber,
        name,
        direction,
        riskScore,
        riskCategory,
        wasBlocked,
        durationSeconds,
        timestamp,
      ];
}
