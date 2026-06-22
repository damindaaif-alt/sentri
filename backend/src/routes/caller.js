const express = require('express');
const { lookupPhone } = require('../services/ipqs');
const { addReport, getReport } = require('../services/reportStore');

const router = express.Router();

const _unknown = (number) => ({
  phone_number: number,
  name: null,
  organization: null,
  risk_score: 0,
  category: 'unknown',
  spoofing_status: 'unknown',
  report_count: 0,
  is_verified_business: false,
  last_reported_at: null,
  evidence_tags: [],
});

router.get('/lookup', async (req, res) => {
  const { number } = req.query;
  if (!number) {
    return res.status(400).json({ error: 'number query parameter required' });
  }

  let info;
  try {
    info = await lookupPhone(number);
  } catch (err) {
    console.error('[lookup] IPQS error:', err.message);
    info = _unknown(number);
  }

  // Merge community reports
  const report = getReport(number);
  if (report) {
    info.report_count += report.count;
    if (report.lastAt) info.last_reported_at = report.lastAt;
    if (info.category === 'unknown') {
      const top = Object.entries(report.categories).sort(([, a], [, b]) => b - a)[0];
      if (top) info.category = top[0];
    }
  }

  return res.json(info);
});

router.post('/report', (req, res) => {
  const { phone_number, category, note } = req.body;
  if (!phone_number || !category) {
    return res.status(400).json({ error: 'phone_number and category are required' });
  }
  addReport(phone_number, category, note);
  return res.json({ success: true });
});

module.exports = router;
