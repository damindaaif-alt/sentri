// In-memory store — replace with a database for production
const _store = new Map();

function addReport(phoneNumber, category, note) {
  const existing = _store.get(phoneNumber) ?? {
    count: 0,
    categories: {},
    lastAt: null,
  };
  existing.count += 1;
  existing.categories[category] = (existing.categories[category] ?? 0) + 1;
  existing.lastAt = new Date().toISOString();
  if (note) existing.lastNote = note;
  _store.set(phoneNumber, existing);
}

function getReport(phoneNumber) {
  return _store.get(phoneNumber) ?? null;
}

module.exports = { addReport, getReport };
