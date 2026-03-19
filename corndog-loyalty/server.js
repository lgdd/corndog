// dd-trace must be initialized before all other imports
const tracer = require('dd-trace').init({
  service: 'corndog-loyalty',
  logInjection: true,
});

const express = require('express');
const winston = require('winston');
const { requestContextMiddleware } = require('./middleware/request-context');
const loyaltyRoutes = require('./routes/loyalty');

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  defaultMeta: { service: 'corndog-loyalty' },
  transports: [new winston.transports.Console()],
});

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json({ limit: '50mb' }));
app.use(requestContextMiddleware);

app.get('/health', (_req, res) => {
  res.json({ status: 'ok', service: 'corndog-loyalty' });
});

app.use('/api/loyalty', loyaltyRoutes);

app.use((err, _req, res, _next) => {
  logger.error('Unhandled error', { error: err.message, stack: err.stack });
  res.status(500).json({ error: 'Internal server error' });
});

app.listen(PORT, () => {
  logger.info(`corndog-loyalty listening on port ${PORT}`);
});

module.exports = app;
