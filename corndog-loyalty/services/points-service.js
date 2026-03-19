const { Pool } = require('pg');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL || 'postgresql://corndog:corndog123@corndog-db:5432/corndog',
});

async function getPoints(customerName) {
  const result = await pool.query(
    'SELECT * FROM loyalty_points WHERE customer_name = $1',
    [customerName]
  );
  if (result.rows.length === 0) {
    return { customer_name: customerName, points: 0, tier: 'bronze' };
  }
  return result.rows[0];
}

async function earnPoints(customerName, orderTotal) {
  const pointsEarned = Math.floor(orderTotal * 10);

  const result = await pool.query(
    `INSERT INTO loyalty_points (customer_name, points, tier, updated_at)
     VALUES ($1, $2, 'bronze', NOW())
     ON CONFLICT (customer_name) DO UPDATE
     SET points = loyalty_points.points + $2,
         tier = CASE
           WHEN loyalty_points.points + $2 >= 1000 THEN 'gold'
           WHEN loyalty_points.points + $2 >= 500 THEN 'silver'
           ELSE 'bronze'
         END,
         updated_at = NOW()
     RETURNING *`,
    [customerName, pointsEarned]
  );
  return { ...result.rows[0], points_earned: pointsEarned };
}

async function redeemPoints(customerName, pointsToRedeem) {
  const current = await getPoints(customerName);
  if (current.points < pointsToRedeem) {
    return { error: 'Insufficient points', available: current.points };
  }

  const result = await pool.query(
    `UPDATE loyalty_points
     SET points = points - $2, updated_at = NOW()
     WHERE customer_name = $1
     RETURNING *`,
    [customerName, pointsToRedeem]
  );
  return { ...result.rows[0], points_redeemed: pointsToRedeem };
}

module.exports = { getPoints, earnPoints, redeemPoints };
