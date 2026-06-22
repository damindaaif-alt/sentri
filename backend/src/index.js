require('dotenv').config();
const express = require('express');
const cors = require('cors');

const callerRoutes = require('./routes/caller');
const threatRoutes = require('./routes/threats');

const app = express();
app.use(cors());
app.use(express.json());

app.use('/v1/caller', callerRoutes);
app.use('/v1/threats', threatRoutes);

app.get('/health', (_req, res) => res.json({ status: 'ok' }));

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Sentri API running on port ${PORT}`));
