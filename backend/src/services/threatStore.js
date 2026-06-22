const now = Date.now();
const DAY = 86400000;

const THREATS = [
  e('t01', '+12025551847', 'scam',         95, 'US', 1423, true,  ['irs_scam','tax_fraud'],            now-DAY*2,  now-3600000),
  e('t02', '+18005559231', 'robocall',      82, 'US', 891,  true,  ['auto_warranty'],                   now-DAY*5,  now-7200000),
  e('t03', '+14155552049', 'vishing',       91, 'US', 2104, true,  ['bank_fraud','wire_transfer'],      now-DAY*1,  now-1800000),
  e('t04', '+12125558823', 'scam',          88, 'US', 674,  false, ['medicare_fraud','health_ins'],     now-DAY*7,  now-DAY),
  e('t05', '+14085553312', 'telemarketing', 63, 'US', 312,  false, ['solar_panels'],                    now-DAY*10, now-DAY*2),
  e('t06', '+14125550918', 'vishing',       94, 'US', 3021, true,  ['crypto_scam','investment_fraud'],  now-DAY*1,  now-900000),
  e('t07', '+17025554401', 'robocall',      78, 'US', 445,  false, ['vacation_pkg'],                    now-DAY*14, now-DAY*3),
  e('t08', '+14435559872', 'scam',          86, 'US', 1102, true,  ['social_security','govt_imperson'], now-DAY*3,  now-DAY),
  e('t09', '+13125557743', 'spam',          71, 'US', 228,  false, ['loan_offer'],                      now-DAY*20, now-DAY*5),
  e('t10', '+19175556618', 'vishing',       89, 'US', 1567, false, ['bank_fraud'],                      now-DAY*4,  now-DAY),
  e('t11', '+441632960887','scam',          92, 'GB', 2340, true,  ['hmrc_scam','tax_fraud'],           now-DAY*2,  now-7200000),
  e('t12', '+447911123456','vishing',       85, 'GB', 789,  false, ['bank_fraud'],                      now-DAY*6,  now-DAY*2),
  e('t13', '+610288880000','scam',          90, 'AU', 1876, true,  ['ato_scam','tax_fraud'],            now-DAY*1,  now-3600000),
  e('t14', '+6591234567',  'robocall',      75, 'SG', 334,  false, ['parcel_scam'],                     now-DAY*8,  now-DAY*3),
  e('t15', '+60312345678', 'scam',          83, 'MY', 612,  false, ['macau_scam'],                      now-DAY*5,  now-DAY),
  e('t16', '+6621234567',  'vishing',       88, 'TH', 891,  true,  ['investment_fraud','crypto_scam'],  now-DAY*2,  now-5400000),
  e('t17', '+6281234567890','scam',         91, 'ID', 1203, true,  ['online_shop_fraud'],               now-DAY*1,  now-1800000),
  e('t18', '+639123456789','robocall',      70, 'PH', 289,  false, ['insurance_scam'],                  now-DAY*12, now-DAY*4),
  e('t19', '+919876543210','scam',          87, 'IN', 1456, true,  ['tech_support','microsoft_scam'],   now-DAY*3,  now-DAY),
  e('t20', '+8613012345678','vishing',      93, 'CN', 2789, true,  ['customs_fraud','parcel_scam'],     now-DAY*1,  now-900000),
  e('t21', '+12015554499', 'scam',          84, 'US', 732,  false, ['student_loan_forgiveness'],        now-DAY*9,  now-DAY*2),
  e('t22', '+13015558821', 'telemarketing', 61, 'US', 178,  false, ['home_security'],                   now-DAY*18, now-DAY*6),
  e('t23', '+12695553307', 'vishing',       90, 'US', 1921, true,  ['amazon_imperson','refund_scam'],   now-DAY*2,  now-3600000),
  e('t24', '+18885551234', 'robocall',      76, 'US', 503,  false, ['extended_warranty'],               now-DAY*11, now-DAY*3),
  e('t25', '+14695558839', 'scam',          82, 'US', 645,  false, ['utility_shutoff'],                 now-DAY*7,  now-DAY*2),
  e('t26', '+442071234567','scam',          87, 'GB', 934,  false, ['bank_fraud','vishing'],            now-DAY*4,  now-DAY),
  e('t27', '+33123456789', 'telemarketing', 65, 'FR', 241,  false, ['insurance_offer'],                 now-DAY*15, now-DAY*5),
  e('t28', '+4930123456',  'scam',          80, 'DE', 567,  false, ['polizei_scam'],                    now-DAY*6,  now-DAY*2),
  e('t29', '+81312345678', 'vishing',       86, 'JP', 1102, true,  ['ore_ore_scam'],                    now-DAY*3,  now-DAY),
  e('t30', '+82212345678', 'scam',          88, 'KR', 876,  false, ['prosecutor_scam'],                 now-DAY*4,  now-DAY),
  e('t31', '+13475552928', 'vishing',       95, 'US', 3412, true,  ['crypto_scam','investment_fraud'],  now-3600000, now-600000),
  e('t32', '+16175551844', 'scam',          93, 'US', 2108, true,  ['irs_scam'],                        now-7200000, now-1200000),
  e('t33', '+17145553390', 'robocall',      79, 'US', 398,  false, ['political_robo'],                  now-DAY*13, now-DAY*4),
  e('t34', '+12015557724', 'scam',          91, 'US', 1743, true,  ['social_security','debt_collector'], now-DAY*2, now-5400000),
  e('t35', '+447700900000','vishing',       89, 'GB', 1234, true,  ['bank_fraud'],                      now-DAY*1,  now-3600000),
  e('t36', '+14154443322', 'spam',          68, 'US', 187,  false, ['survey_spam'],                     now-DAY*25, now-DAY*8),
  e('t37', '+12125559900', 'vishing',       96, 'US', 4210, true,  ['bank_fraud','account_takeover'],   now-1800000, now-300000),
  e('t38', '+18005552233', 'telemarketing', 60, 'US', 145,  false, ['credit_card_offer'],               now-DAY*30, now-DAY*10),
  e('t39', '+14155553399', 'scam',          85, 'US', 892,  false, ['package_delivery','phishing'],     now-DAY*5,  now-DAY),
  e('t40', '+19292221111', 'vishing',       92, 'US', 2567, true,  ['bank_fraud','wire_transfer'],      now-DAY*1,  now-2700000),
];

function e(id, phone, category, score, region, reports, trending, tags, firstMs, lastMs) {
  return { id, phone_number: phone, category, risk_score: score, region,
           report_count: reports, is_trending: trending, is_auto_blocked: false,
           first_seen_ms: firstMs, last_seen_ms: lastMs, tags };
}

module.exports = { THREATS };
