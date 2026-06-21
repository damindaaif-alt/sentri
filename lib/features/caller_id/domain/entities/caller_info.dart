import 'package:equatable/equatable.dart';

enum RiskCategory {
  unknown,
  safe,
  telemarketing,
  robocall,
  spam,
  scam,
  vishing,
  spoofed,
  malicious,
}

enum SpoofingStatus { unknown, verified, likelySpoofed, confirmed }

class CallerInfo extends Equatable {
  final String phoneNumber;
  final String? name;
  final String? organization;
  final int riskScore; // 0–100
  final RiskCategory category;
  final SpoofingStatus spoofingStatus;
  final int reportCount;
  final bool isVerifiedBusiness;
  final DateTime? lastReportedAt;
  final List<String> evidenceTags;

  const CallerInfo({
    required this.phoneNumber,
    this.name,
    this.organization,
    required this.riskScore,
    required this.category,
    required this.spoofingStatus,
    required this.reportCount,
    this.isVerifiedBusiness = false,
    this.lastReportedAt,
    this.evidenceTags = const [],
  });

  bool get isHighRisk => riskScore >= 60;
  bool get isCritical => riskScore >= 80;
  bool get isUnknown => category == RiskCategory.unknown && reportCount == 0;

  @override
  List<Object?> get props => [
        phoneNumber,
        name,
        organization,
        riskScore,
        category,
        spoofingStatus,
        reportCount,
        isVerifiedBusiness,
        lastReportedAt,
        evidenceTags,
      ];
}
