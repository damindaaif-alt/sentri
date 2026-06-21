import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/caller_info.dart';

part 'caller_info_model.g.dart';

@JsonSerializable()
class CallerInfoModel {
  @JsonKey(name: 'phone_number')
  final String phoneNumber;
  final String? name;
  final String? organization;
  @JsonKey(name: 'risk_score')
  final int riskScore;
  final String category;
  @JsonKey(name: 'spoofing_status')
  final String spoofingStatus;
  @JsonKey(name: 'report_count')
  final int reportCount;
  @JsonKey(name: 'is_verified_business')
  final bool isVerifiedBusiness;
  @JsonKey(name: 'last_reported_at')
  final String? lastReportedAt;
  @JsonKey(name: 'evidence_tags')
  final List<String> evidenceTags;

  const CallerInfoModel({
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

  factory CallerInfoModel.fromJson(Map<String, dynamic> json) =>
      _$CallerInfoModelFromJson(json);

  Map<String, dynamic> toJson() => _$CallerInfoModelToJson(this);

  CallerInfo toDomain() => CallerInfo(
        phoneNumber: phoneNumber,
        name: name,
        organization: organization,
        riskScore: riskScore,
        category: _parseCategory(category),
        spoofingStatus: _parseSpoofing(spoofingStatus),
        reportCount: reportCount,
        isVerifiedBusiness: isVerifiedBusiness,
        lastReportedAt:
            lastReportedAt != null ? DateTime.tryParse(lastReportedAt!) : null,
        evidenceTags: evidenceTags,
      );

  static RiskCategory _parseCategory(String raw) =>
      RiskCategory.values.firstWhere(
        (e) => e.name == raw,
        orElse: () => RiskCategory.unknown,
      );

  static SpoofingStatus _parseSpoofing(String raw) =>
      SpoofingStatus.values.firstWhere(
        (e) => e.name == raw,
        orElse: () => SpoofingStatus.unknown,
      );
}
