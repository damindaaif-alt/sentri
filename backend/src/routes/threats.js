const express = require('express');
const { THREATS } = require('../services/threatStore');

const router = express.Router();

router.get('/latest', (_req, res) => res.json(THREATS));

module.exports = router;
