import 'package:equatable/equatable.dart';

import '../../../caller_id/domain/entities/caller_info.dart';

class CallRecord extends Equatable {
  final int id;
  final String phoneNumber;
  final String? name;
  final int riskScore;
  final RiskCategory riskCategory;
  final bool wasBlocked;
  final int durationSeconds;
  final DateTime timestamp;

  const CallRecord({
    required this.id,
    required this.phoneNumber,
    this.name,
    required this.riskScore,
    required this.riskCategory,
    required this.wasBlocked,
    required this.durationSeconds,
    required this.timestamp,
  });

  @override
  List<Object?> get props =>
      [id, phoneNumber, name, riskScore, wasBlocked, durationSeconds, timestamp];
}
