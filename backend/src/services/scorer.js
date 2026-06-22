const { getReport } = require('./reportStore');
const { THREATS } = require('./threatStore');

// Points per report by category
const WEIGHT = { scam: 22, vishing: 22, malicious: 22, spoofed: 18,
                 spam: 15, robocall: 15, telemarketing: 10 };
// Maximum score by category
const CAP    = { scam: 95, vishing: 95, malicious: 95, spoofed: 88,
                 spam: 80, robocall: 80, telemarketing: 65 };

/**
 * Returns a scoring result for a phone number, or null if unknown.
 * Checks the seed threat list first, then community reports.
 */
function score(phoneNumber) {
  const key = last9(phoneNumber);

  // 1. Seed threat list — exact last-9 match
  const threat = THREATS.find(t => last9(t.phone_number) === key);
  if (threat) {
    return {
      risk_score:   threat.risk_score,
      category:     threat.category,
      report_count: threat.report_count,
      evidence_tags: threat.tags,
    };
  }

  // 2. Community reports
  const report = getReport(phoneNumber);
  if (!report) return null;

  const [[topCategory]] = Object.entries(report.categories)
    .sort(([, a], [, b]) => b - a);
  const weight = WEIGHT[topCategory] ?? 10;
  const cap    = CAP[topCategory]    ?? 80;
  // First report gives the base weight; each extra adds half
  const raw = weight + (report.count - 1) * Math.ceil(weight / 2);

  return {
    risk_score:    Math.min(Math.round(raw), cap),
    category:      topCategory,
    report_count:  report.count,
    evidence_tags: ['community_reported'],
  };
}

function last9(number) {
  const d = number.replace(/\D/g, '');
  return d.length > 9 ? d.slice(-9) : d;
}

module.exports = { score };
