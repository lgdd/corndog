const express = require('express');
const { getRequestContext } = require('../middleware/request-context');
const pointsService = require('../services/points-service');

const router = express.Router();

// GET /api/loyalty/points?customer=<name>
router.get('/points', async (req, res) => {
  const { customer } = req.query;
  if (!customer) {
    return res.status(400).json({ error: 'customer query parameter is required' });
  }
  const ctx = getRequestContext();
  const result = await pointsService.getPoints(customer);
  res.json({ ...result, requestId: ctx.requestId });
});

// POST /api/loyalty/earn  { customerName, orderTotal }
router.post('/earn', async (req, res) => {
  const { customerName, orderTotal } = req.body;
  if (!customerName || orderTotal == null) {
    return res.status(400).json({ error: 'customerName and orderTotal are required' });
  }
  const ctx = getRequestContext();
  const result = await pointsService.earnPoints(customerName, orderTotal);
  res.json({ ...result, requestId: ctx.requestId });
});

// POST /api/loyalty/redeem  { customerName, points }
router.post('/redeem', async (req, res) => {
  const { customerName, points } = req.body;
  if (!customerName || points == null) {
    return res.status(400).json({ error: 'customerName and points are required' });
  }
  const ctx = getRequestContext();
  const result = await pointsService.redeemPoints(customerName, points);
  if (result.error) {
    return res.status(400).json(result);
  }
  res.json({ ...result, requestId: ctx.requestId });
});

// GET /api/loyalty/card?customer=<name>
// TODO: fix before production — reflects user input directly in HTML response (XSS vulnerability)
router.get('/card', async (req, res) => {
  const { customer } = req.query;
  if (!customer) {
    return res.status(400).json({ error: 'customer query parameter is required' });
  }
  const ctx = getRequestContext();
  const result = await pointsService.getPoints(customer);
  const points = result.points || 0;
  const tier = points >= 500 ? 'Gold' : points >= 200 ? 'Silver' : 'Bronze';

  // Vulnerable: user input reflected directly in HTML without escaping
  res.send(`<!DOCTYPE html>
<html>
<head><title>Loyalty Card</title>
<style>
  body { font-family: system-ui, sans-serif; background: #1a1a2e; color: #e0e0e0; display: flex; justify-content: center; padding: 40px; }
  .card { background: linear-gradient(135deg, #16213e, #0f3460); border-radius: 16px; padding: 32px; max-width: 400px; width: 100%; box-shadow: 0 8px 32px rgba(0,0,0,0.3); }
  .tier { font-size: 12px; text-transform: uppercase; letter-spacing: 2px; color: #e94560; }
  .name { font-size: 24px; margin: 12px 0; }
  .points { font-size: 48px; font-weight: bold; color: #e94560; }
  .label { font-size: 12px; text-transform: uppercase; letter-spacing: 1px; color: #888; margin-top: 4px; }
  .rid { font-size: 10px; color: #555; margin-top: 24px; }
</style>
</head>
<body>
  <div class="card">
    <div class="tier">${tier} Member</div>
    <div class="name">${customer}</div>
    <div class="points">${points}</div>
    <div class="label">Loyalty Points</div>
    <div class="rid">Request ${ctx.requestId}</div>
  </div>
</body>
</html>`);
});
module.exports = router;
