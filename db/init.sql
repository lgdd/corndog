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
  emoji VARCHAR(10),
  category VARCHAR(30) NOT NULL DEFAULT 'corndogs',
  image_url VARCHAR(255) DEFAULT '',
  available_sauces JSONB DEFAULT '[]'::jsonb,
  combo_items JSONB DEFAULT NULL,
  sort_order INTEGER NOT NULL DEFAULT 0
);

-- Add new columns if upgrading from an older schema
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'menu_items' AND column_name = 'category') THEN
    ALTER TABLE menu_items ADD COLUMN category VARCHAR(30) NOT NULL DEFAULT 'corndogs';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'menu_items' AND column_name = 'image_url') THEN
    ALTER TABLE menu_items ADD COLUMN image_url VARCHAR(255) DEFAULT '';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'menu_items' AND column_name = 'available_sauces') THEN
    ALTER TABLE menu_items ADD COLUMN available_sauces JSONB DEFAULT '[]'::jsonb;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'menu_items' AND column_name = 'combo_items') THEN
    ALTER TABLE menu_items ADD COLUMN combo_items JSONB DEFAULT NULL;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'menu_items' AND column_name = 'sort_order') THEN
    ALTER TABLE menu_items ADD COLUMN sort_order INTEGER NOT NULL DEFAULT 0;
  END IF;
END $$;

-- Update existing rows (ids 1-4) with new column values
UPDATE menu_items SET category = 'corndogs', available_sauces = '["mustard","ketchup","spicy-mayo","ranch"]', sort_order = id WHERE id IN (1, 2, 3, 4) AND category = 'corndogs' AND available_sauces = '[]'::jsonb;

CREATE TABLE IF NOT EXISTS orders (
  id SERIAL PRIMARY KEY,
  customer_name VARCHAR(200) NOT NULL,
  items JSONB NOT NULL,
  special_instructions TEXT,
  total_price DECIMAL(10,2) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Corndogs
INSERT INTO menu_items (id, name, description, price, emoji, category, available_sauces, sort_order) VALUES
  (1, 'Classic Corndog',     'Golden fried corndog on a stick, the original',                   4.99, '🌭', 'corndogs', '["mustard","ketchup","spicy-mayo","ranch"]',   1),
  (2, 'Spicy Jalapeño Dog',  'Packed with jalapeños, for the brave',                            5.99, '🔥', 'corndogs', '["mustard","ketchup","spicy-mayo","ranch"]',   2),
  (3, 'Cheese-Stuffed Dog',  'Oozing cheddar inside a crispy cornbread shell',                  6.49, '🧀', 'corndogs', '["mustard","ketchup","spicy-mayo","ranch"]',   3),
  (4, 'Vegan Dog',           'Plant-based sausage, same great cornbread coating',               5.49, '🌱', 'corndogs', '["mustard","ketchup","spicy-mayo","ranch"]',   4),
  (5, 'BBQ Bacon Dog',       'Smoky bacon wrapped dog with tangy BBQ drizzle',                  6.99, '🥓', 'corndogs', '["mustard","ketchup","bbq-sauce","ranch"]',    5),
  (6, 'Mini Corn Bites',     'Bite-sized corndog poppers, perfect for sharing',                 5.49, '🍡', 'corndogs', '["mustard","ketchup","spicy-mayo","ranch"]',   6)
ON CONFLICT (id) DO NOTHING;

-- Sides
INSERT INTO menu_items (id, name, description, price, emoji, category, available_sauces, sort_order) VALUES
  (10, 'Crispy Fries',       'Golden shoestring fries, salted to perfection',                   3.49, '🍟', 'sides', '["ketchup","ranch","cheese-sauce"]',               1),
  (11, 'Onion Rings',        'Thick-cut, beer-battered and crispy',                             3.99, '🧅', 'sides', '["ketchup","ranch","spicy-mayo"]',                 2),
  (12, 'Coleslaw',           'Creamy house-made slaw with a hint of apple cider',               2.99, '🥗', 'sides', '[]',                                               3),
  (13, 'Mac & Cheese',       'Rich three-cheese blend, baked until bubbly',                     4.49, '🧀', 'sides', '[]',                                               4)
ON CONFLICT (id) DO NOTHING;

-- Drinks
INSERT INTO menu_items (id, name, description, price, emoji, category, available_sauces, sort_order) VALUES
  (14, 'Fresh Lemonade',     'Hand-squeezed lemonade, sweet and tart',                          2.99, '🍋', 'drinks', '[]', 1),
  (15, 'Iced Tea',           'Cold-brewed black tea, unsweetened',                              2.49, '🍵', 'drinks', '[]', 2),
  (16, 'Soda',               'Your choice of cola, root beer, or orange',                      1.99, '🥤', 'drinks', '[]', 3)
ON CONFLICT (id) DO NOTHING;

-- Combos (corndog + side + drink at a discount)
INSERT INTO menu_items (id, name, description, price, emoji, category, available_sauces, combo_items, sort_order) VALUES
  (20, 'Classic Combo',      'Classic Corndog + Fries + Lemonade',                              9.99, '🌭', 'combos', '["mustard","ketchup","spicy-mayo","ranch"]',
    '[{"menuItemId": 1, "role": "main"}, {"menuItemId": 10, "role": "side"}, {"menuItemId": 14, "role": "drink"}]', 1),
  (21, 'Spicy Combo',        'Spicy Jalapeño Dog + Onion Rings + Iced Tea',                    10.99, '🔥', 'combos', '["mustard","ketchup","spicy-mayo","ranch"]',
    '[{"menuItemId": 2, "role": "main"}, {"menuItemId": 11, "role": "side"}, {"menuItemId": 15, "role": "drink"}]', 2),
  (22, 'Vegan Combo',        'Vegan Dog + Coleslaw + Fresh Lemonade',                           9.99, '🌱', 'combos', '["mustard","ketchup","spicy-mayo","ranch"]',
    '[{"menuItemId": 4, "role": "main"}, {"menuItemId": 12, "role": "side"}, {"menuItemId": 14, "role": "drink"}]', 3)
ON CONFLICT (id) DO NOTHING;

CREATE TABLE IF NOT EXISTS loyalty_points (
  id SERIAL PRIMARY KEY,
  customer_name VARCHAR(200) NOT NULL UNIQUE,
  points INTEGER NOT NULL DEFAULT 0,
  tier VARCHAR(20) NOT NULL DEFAULT 'bronze',
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
