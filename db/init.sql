-- DBM: monitoring user and pg_stat_statements
CREATE USER datadog WITH PASSWORD 'datadog';
GRANT pg_monitor TO datadog;

CREATE SCHEMA IF NOT EXISTS datadog;
GRANT USAGE ON SCHEMA datadog TO datadog;
GRANT USAGE ON SCHEMA public TO datadog;

CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

CREATE OR REPLACE FUNCTION datadog.explain_statement(
   l_query TEXT,
   OUT explain JSON
)
RETURNS SETOF JSON AS
$$
DECLARE
  curs REFCURSOR;
  plan JSON;
BEGIN
  SET TRANSACTION READ ONLY;
  OPEN curs FOR EXECUTE pg_catalog.concat('EXPLAIN (FORMAT JSON) ', l_query);
  FETCH curs INTO plan;
  CLOSE curs;
  RETURN QUERY SELECT plan;
END;
$$
LANGUAGE 'plpgsql'
RETURNS NULL ON NULL INPUT
SECURITY DEFINER;

-- Application schema
CREATE TABLE IF NOT EXISTS menu_items (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  description TEXT,
  price DECIMAL(10,2) NOT NULL,
  emoji VARCHAR(10)
);

CREATE TABLE IF NOT EXISTS orders (
  id SERIAL PRIMARY KEY,
  customer_name VARCHAR(200) NOT NULL,
  items JSONB NOT NULL,
  special_instructions TEXT,
  total_price DECIMAL(10,2) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO menu_items (id, name, description, price, emoji) VALUES
  (1, 'Classic Corndog',     'Golden fried corndog on a stick, the original',       4.99, '🌭'),
  (2, 'Spicy Jalapeño Dog',  'Packed with jalapeños, for the brave',                5.99, '🔥'),
  (3, 'Cheese-Stuffed Dog',  'Oozing cheddar inside a crispy cornbread shell',      6.49, '🧀'),
  (4, 'Vegan Dog',           'Plant-based sausage, same great cornbread coating',   5.49, '🌱')
ON CONFLICT (id) DO NOTHING;

CREATE TABLE IF NOT EXISTS loyalty_points (
  id SERIAL PRIMARY KEY,
  customer_name VARCHAR(200) NOT NULL UNIQUE,
  points INTEGER NOT NULL DEFAULT 0,
  tier VARCHAR(20) NOT NULL DEFAULT 'bronze',
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
