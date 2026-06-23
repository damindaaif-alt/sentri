const Database = require('better-sqlite3');
const path = require('path');
const fs = require('fs');

const dataDir = process.env.DATA_DIR
  ? path.resolve(process.env.DATA_DIR)
  : path.join(__dirname, '../../../data');

fs.mkdirSync(dataDir, { recursive: true });

const db = new Database(path.join(dataDir, 'reports.db'));

db.exec(`
  CREATE TABLE IF NOT EXISTS reports (
    phone_number TEXT PRIMARY KEY,
    count        INTEGER NOT NULL DEFAULT 0,
    categories   TEXT    NOT NULL DEFAULT '{}',
    last_note    TEXT,
    last_at      TEXT
  )
`);

module.exports = db;
