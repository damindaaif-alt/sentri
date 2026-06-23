const db = require('./db');

const _select = db.prepare('SELECT * FROM reports WHERE phone_number = ?');

const _upsert = db.prepare(`
  INSERT INTO reports (phone_number, count, categories, last_note, last_at)
  VALUES (?, ?, ?, ?, ?)
  ON CONFLICT(phone_number) DO UPDATE SET
    count      = excluded.count,
    categories = excluded.categories,
    last_note  = excluded.last_note,
    last_at    = excluded.last_at
`);

function getReport(phoneNumber) {
  const row = _select.get(phoneNumber);
  if (!row) return null;
  return {
    count:      row.count,
    categories: JSON.parse(row.categories),
    lastNote:   row.last_note,
    lastAt:     row.last_at,
  };
}

function addReport(phoneNumber, category, note) {
  const existing = getReport(phoneNumber) ?? { count: 0, categories: {} };
  existing.count += 1;
  existing.categories[category] = (existing.categories[category] ?? 0) + 1;
  _upsert.run(
    phoneNumber,
    existing.count,
    JSON.stringify(existing.categories),
    note ?? existing.lastNote ?? null,
    new Date().toISOString(),
  );
}

module.exports = { addReport, getReport };
