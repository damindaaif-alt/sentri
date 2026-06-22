const express = require('express');
const { score } = require('../services/scorer');
const { addReport, getReport } = require('../services/reportStore');

const router = express.Router();

router.get('/lookup', (req, res) => {
  const { number } = req.query;
  if (!number) {
    return res.status(400).json({ error: 'number query parameter required' });
  }

  const result = score(number);
  const report = getReport(number);

  return res.json({
    phone_number:       number,
    name:               null,
    organization:       null,
    risk_score:         result?.risk_score         ?? 0,
    category:           result?.category            ?? 'unknown',
    spoofing_status:    'unknown',
    report_count:       result?.report_count        ?? 0,
    is_verified_business: false,
    last_reported_at:   report?.lastAt              ?? null,
    evidence_tags:      result?.evidence_tags       ?? [],
  });
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
