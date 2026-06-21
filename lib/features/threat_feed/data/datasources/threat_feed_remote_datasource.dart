import 'package:injectable/injectable.dart';

import '../models/threat_entry_model.dart';

abstract interface class ThreatFeedRemoteDataSource {
  Future<List<ThreatEntryModel>> fetchLatest();
}

@Injectable(as: ThreatFeedRemoteDataSource)
class ThreatFeedRemoteDataSourceImpl implements ThreatFeedRemoteDataSource {
  const ThreatFeedRemoteDataSourceImpl();

  // Simulates a threat intelligence API response.
  // Replace with a real Dio call once the backend is live.
  @override
  Future<List<ThreatEntryModel>> fetchLatest() async {
    await Future.delayed(const Duration(milliseconds: 600));
    final now = DateTime.now().millisecondsSinceEpoch;
    final dayMs = const Duration(days: 1).inMilliseconds;

    return [
      _entry('t01', '+12025551847', 'scam',      95, 'US', 1423, true,  ['irs_scam', 'tax_fraud'],             now - dayMs * 2,  now - 3600000),
      _entry('t02', '+18005559231', 'robocall',   82, 'US', 891,  true,  ['auto_warranty'],                     now - dayMs * 5,  now - 7200000),
      _entry('t03', '+14155552049', 'vishing',    91, 'US', 2104, true,  ['bank_fraud', 'wire_transfer'],       now - dayMs * 1,  now - 1800000),
      _entry('t04', '+12125558823', 'scam',       88, 'US', 674,  false, ['medicare_fraud', 'health_ins'],      now - dayMs * 7,  now - dayMs),
      _entry('t05', '+14085553312', 'telemarketing',63,'US',312,  false, ['solar_panels'],                      now - dayMs * 10, now - dayMs * 2),
      _entry('t06', '+14125550918', 'vishing',    94, 'US', 3021, true,  ['crypto_scam', 'investment_fraud'],   now - dayMs * 1,  now - 900000),
      _entry('t07', '+17025554401', 'robocall',   78, 'US', 445,  false, ['vacation_pkg'],                      now - dayMs * 14, now - dayMs * 3),
      _entry('t08', '+14435559872', 'scam',       86, 'US', 1102, true,  ['social_security', 'govt_imperson'],  now - dayMs * 3,  now - dayMs),
      _entry('t09', '+13125557743', 'spam',       71, 'US', 228,  false, ['loan_offer'],                        now - dayMs * 20, now - dayMs * 5),
      _entry('t10', '+19175556618', 'vishing',    89, 'US', 1567, false, ['bank_fraud'],                        now - dayMs * 4,  now - dayMs * 1),
      _entry('t11', '+441632960887','scam',       92, 'GB', 2340, true,  ['hmrc_scam', 'tax_fraud'],            now - dayMs * 2,  now - 7200000),
      _entry('t12', '+447911123456','vishing',    85, 'GB', 789,  false, ['bank_fraud'],                        now - dayMs * 6,  now - dayMs * 2),
      _entry('t13', '+610288880000','scam',       90, 'AU', 1876, true,  ['ato_scam', 'tax_fraud'],             now - dayMs * 1,  now - 3600000),
      _entry('t14', '+6591234567',  'robocall',   75, 'SG', 334,  false, ['parcel_scam'],                       now - dayMs * 8,  now - dayMs * 3),
      _entry('t15', '+60312345678', 'scam',       83, 'MY', 612,  false, ['macau_scam'],                        now - dayMs * 5,  now - dayMs * 1),
      _entry('t16', '+6621234567',  'vishing',    88, 'TH', 891,  true,  ['investment_fraud', 'crypto_scam'],   now - dayMs * 2,  now - 5400000),
      _entry('t17', '+6281234567890','scam',      91, 'ID', 1203, true,  ['online_shop_fraud'],                 now - dayMs * 1,  now - 1800000),
      _entry('t18', '+639123456789','robocall',   70, 'PH', 289,  false, ['insurance_scam'],                    now - dayMs * 12, now - dayMs * 4),
      _entry('t19', '+919876543210','scam',       87, 'IN', 1456, true,  ['tech_support', 'microsoft_scam'],    now - dayMs * 3,  now - dayMs),
      _entry('t20', '+8613012345678','vishing',   93, 'CN', 2789, true,  ['customs_fraud', 'parcel_scam'],      now - dayMs * 1,  now - 900000),
      _entry('t21', '+12015554499', 'scam',       84, 'US', 732,  false, ['student_loan_forgiveness'],           now - dayMs * 9,  now - dayMs * 2),
      _entry('t22', '+13015558821', 'telemarketing',61,'US',178,  false, ['home_security'],                     now - dayMs * 18, now - dayMs * 6),
      _entry('t23', '+12695553307', 'vishing',    90, 'US', 1921, true,  ['amazon_imperson', 'refund_scam'],    now - dayMs * 2,  now - 3600000),
      _entry('t24', '+18885551234', 'robocall',   76, 'US', 503,  false, ['extended_warranty'],                 now - dayMs * 11, now - dayMs * 3),
      _entry('t25', '+14695558839', 'scam',       82, 'US', 645,  false, ['utility_shutoff'],                   now - dayMs * 7,  now - dayMs * 2),
      _entry('t26', '+442071234567','scam',       87, 'GB', 934,  false, ['bank_fraud', 'vishing'],             now - dayMs * 4,  now - dayMs),
      _entry('t27', '+33123456789', 'telemarketing',65,'FR',241,  false, ['insurance_offer'],                   now - dayMs * 15, now - dayMs * 5),
      _entry('t28', '+4930123456',  'scam',       80, 'DE', 567,  false, ['polizei_scam'],                      now - dayMs * 6,  now - dayMs * 2),
      _entry('t29', '+81312345678', 'vishing',    86, 'JP', 1102, true,  ['ore_ore_scam'],                      now - dayMs * 3,  now - dayMs),
      _entry('t30', '+82212345678', 'scam',       88, 'KR', 876,  false, ['prosecutor_scam'],                   now - dayMs * 4,  now - dayMs * 1),
      _entry('t31', '+13475552928', 'vishing',    95, 'US', 3412, true,  ['crypto_scam', 'investment_fraud'],   now - 3600000,    now - 600000),
      _entry('t32', '+16175551844', 'scam',       93, 'US', 2108, true,  ['irs_scam'],                          now - 7200000,    now - 1200000),
      _entry('t33', '+17145553390', 'robocall',   79, 'US', 398,  false, ['political_robo'],                    now - dayMs * 13, now - dayMs * 4),
      _entry('t34', '+12015557724', 'scam',       91, 'US', 1743, true,  ['social_security', 'debt_collector'],  now - dayMs * 2,  now - 5400000),
      _entry('t35', '+447700900000','vishing',    89, 'GB', 1234, true,  ['bank_fraud'],                        now - dayMs * 1,  now - 3600000),
      _entry('t36', '+14154443322', 'spam',       68, 'US', 187,  false, ['survey_spam'],                       now - dayMs * 25, now - dayMs * 8),
      _entry('t37', '+12125559900', 'vishing',    96, 'US', 4210, true,  ['bank_fraud', 'account_takeover'],    now - 1800000,    now - 300000),
      _entry('t38', '+18005552233', 'telemarketing',60,'US',145,  false, ['credit_card_offer'],                 now - dayMs * 30, now - dayMs * 10),
      _entry('t39', '+14155553399', 'scam',       85, 'US', 892,  false, ['package_delivery', 'phishing'],      now - dayMs * 5,  now - dayMs * 1),
      _entry('t40', '+19292221111', 'vishing',    92, 'US', 2567, true,  ['bank_fraud', 'wire_transfer'],       now - dayMs * 1,  now - 2700000),
    ];
  }

  static ThreatEntryModel _entry(
    String id,
    String number,
    String category,
    int score,
    String region,
    int reports,
    bool trending,
    List<String> tags,
    int firstMs,
    int lastMs,
  ) =>
      ThreatEntryModel(
        id: id,
        phoneNumber: number,
        category: category,
        riskScore: score,
        region: region,
        reportCount: reports,
        isTrending: trending,
        isAutoBlocked: false,
        firstSeenMs: firstMs,
        lastSeenMs: lastMs,
        tags: tags,
      );
}
