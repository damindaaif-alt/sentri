import '../../../caller_id/domain/entities/caller_info.dart';
import '../../domain/entities/threat_entry.dart';

class ThreatEntryModel {
  final String id;
  final String phoneNumber;
  final String category;
  final int riskScore;
  final String? region;
  final int reportCount;
  final bool isTrending;
  final bool isAutoBlocked;
  final int firstSeenMs;
  final int lastSeenMs;
  final List<String> tags;

  const ThreatEntryModel({
    required this.id,
    required this.phoneNumber,
    required this.category,
    required this.riskScore,
    this.region,
    required this.reportCount,
    this.isTrending = false,
    this.isAutoBlocked = false,
    required this.firstSeenMs,
    required this.lastSeenMs,
    this.tags = const [],
  });

  factory ThreatEntryModel.fromJson(Map<String, dynamic> j) =>
      ThreatEntryModel(
        id: j['id'] as String,
        phoneNumber: j['phone_number'] as String,
        category: j['category'] as String,
        riskScore: (j['risk_score'] as num).toInt(),
        region: j['region'] as String?,
        reportCount: (j['report_count'] as num).toInt(),
        isTrending: j['is_trending'] as bool? ?? false,
        isAutoBlocked: j['is_auto_blocked'] as bool? ?? false,
        firstSeenMs: (j['first_seen_ms'] as num).toInt(),
        lastSeenMs: (j['last_seen_ms'] as num).toInt(),
        tags: (j['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'phone_number': phoneNumber,
        'category': category,
        'risk_score': riskScore,
        'region': region,
        'report_count': reportCount,
        'is_trending': isTrending ? 1 : 0,
        'is_auto_blocked': isAutoBlocked ? 1 : 0,
        'first_seen_ms': firstSeenMs,
        'last_seen_ms': lastSeenMs,
        'tags': tags.join(','),
      };

  factory ThreatEntryModel.fromDb(Map<String, dynamic> row) =>
      ThreatEntryModel(
        id: row['id'] as String,
        phoneNumber: row['phone_number'] as String,
        category: row['category'] as String,
        riskScore: row['risk_score'] as int,
        region: row['region'] as String?,
        reportCount: row['report_count'] as int,
        isTrending: (row['is_trending'] as int) == 1,
        isAutoBlocked: (row['is_auto_blocked'] as int) == 1,
        firstSeenMs: row['first_seen_ms'] as int,
        lastSeenMs: row['last_seen_ms'] as int,
        tags: (row['tags'] as String?)
                ?.split(',')
                .where((t) => t.isNotEmpty)
                .toList() ??
            [],
      );

  ThreatEntry toDomain() => ThreatEntry(
        id: id,
        phoneNumber: phoneNumber,
        category: _parseCategory(category),
        riskScore: riskScore,
        region: region,
        reportCount: reportCount,
        isTrending: isTrending,
        isAutoBlocked: isAutoBlocked,
        firstSeen: DateTime.fromMillisecondsSinceEpoch(firstSeenMs),
        lastSeen: DateTime.fromMillisecondsSinceEpoch(lastSeenMs),
        tags: tags,
      );

  static RiskCategory _parseCategory(String raw) =>
      RiskCategory.values.firstWhere(
        (e) => e.name == raw,
        orElse: () => RiskCategory.unknown,
      );
}
