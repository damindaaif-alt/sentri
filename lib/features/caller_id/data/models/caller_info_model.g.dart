// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'caller_info_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CallerInfoModel _$CallerInfoModelFromJson(Map<String, dynamic> json) =>
    CallerInfoModel(
      phoneNumber: json['phone_number'] as String,
      name: json['name'] as String?,
      organization: json['organization'] as String?,
      riskScore: (json['risk_score'] as num).toInt(),
      category: json['category'] as String,
      spoofingStatus: json['spoofing_status'] as String,
      reportCount: (json['report_count'] as num).toInt(),
      isVerifiedBusiness: json['is_verified_business'] as bool? ?? false,
      lastReportedAt: json['last_reported_at'] as String?,
      evidenceTags: (json['evidence_tags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$CallerInfoModelToJson(CallerInfoModel instance) =>
    <String, dynamic>{
      'phone_number': instance.phoneNumber,
      'name': instance.name,
      'organization': instance.organization,
      'risk_score': instance.riskScore,
      'category': instance.category,
      'spoofing_status': instance.spoofingStatus,
      'report_count': instance.reportCount,
      'is_verified_business': instance.isVerifiedBusiness,
      'last_reported_at': instance.lastReportedAt,
      'evidence_tags': instance.evidenceTags,
    };
