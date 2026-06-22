const axios = require('axios');

const BASE = 'https://ipqualityscore.com/api/json/phone';

async function lookupPhone(phoneNumber) {
  const key = process.env.IPQS_API_KEY;
  if (!key) throw new Error('IPQS_API_KEY not set');

  const { data } = await axios.get(
    `${BASE}/${key}/${encodeURIComponent(phoneNumber)}`,
    { params: { strictness: 1, allow_prepaid: true }, timeout: 10000 }
  );

  if (!data.success) throw new Error(data.message || 'IPQS lookup failed');

  return _map(phoneNumber, data);
}

function _map(phoneNumber, d) {
  const score = d.fraud_score ?? 0;
  return {
    phone_number: phoneNumber,
    name: d.name && d.name !== 'N/A' ? d.name : null,
    organization: null,
    risk_score: score,
    category: _category(score, d),
    spoofing_status: d.VOIP && score >= 70 ? 'likelySpoofed' : 'unknown',
    report_count: 0,
    is_verified_business: false,
    last_reported_at: null,
    evidence_tags: _tags(d),
  };
}

function _category(score, d) {
  if (score >= 85 || d.recent_abuse) return 'scam';
  if (score >= 70) return 'spam';
  if (d.VOIP) return 'robocall';
  if (d.do_not_call) return 'telemarketing';
  if (score >= 40) return 'spam';
  return 'unknown';
}

function _tags(d) {
  const tags = [];
  if (d.leaked) tags.push('leaked_data');
  if (d.VOIP) tags.push('voip');
  if (d.prepaid) tags.push('prepaid');
  if (d.do_not_call) tags.push('do_not_call');
  if (d.recent_abuse) tags.push('recent_abuse');
  if (d.active === false) tags.push('inactive_number');
  if (d.line_type) tags.push(d.line_type.toLowerCase().replace(/\s+/g, '_'));
  return tags;
}

module.exports = { lookupPhone };
