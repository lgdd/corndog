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

// POST /api/loyalty/validate-config  { rules: { ... deeply nested ... } }
// TODO: fix before production — add depth limit to JSON processing
router.post('/validate-config', (req, res) => {
  const config = req.body;
  const ctx = getRequestContext();

  // Recursively count nesting depth to "validate" the config structure.
  // CVE-2025-59466: deeply nested objects (~15k levels) cause a stack
  // overflow that becomes an unrecoverable process crash when
  // async_hooks / AsyncLocalStorage is active.
  function countDepth(obj) {
    if (typeof obj !== 'object' || obj === null) return 0;
    let max = 0;
    for (const key of Object.keys(obj)) {
      const d = countDepth(obj[key]);
      if (d > max) max = d;
    }
    return max + 1;
  }

  try {
    const depth = countDepth(config);
    res.json({
      valid: true,
      depth,
      requestId: ctx.requestId,
    });
  } catch (err) {
    res.status(400).json({ valid: false, error: err.message });
  }
});

module.exports = router;
