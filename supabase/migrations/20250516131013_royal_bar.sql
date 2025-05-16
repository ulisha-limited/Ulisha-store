/*
  # Add variants for watches and gym wear

  1. Changes
    - Add color options for Smart Watches
    - Add size options for Gym Wear
    - Set initial stock levels
*/

-- Insert watch variants
INSERT INTO product_variants (product_id, color, size, stock)
SELECT 
  p.id,
  color.name,
  'One Size',
  FLOOR(RANDOM() * 10 + 1)::integer -- Random stock between 1-10
FROM 
  products p
CROSS JOIN (
  VALUES 
    ('Black'),
    ('Silver'),
    ('Gold'),
    ('Rose Gold'),
    ('Space Gray'),
    ('Midnight Blue')
) AS color(name)
WHERE 
  p.category = 'Smart Watches'
ON CONFLICT (product_id, color, size) DO NOTHING;

-- Insert gym wear variants
INSERT INTO product_variants (product_id, color, size, stock)
SELECT 
  p.id,
  color.name,
  size.name,
  FLOOR(RANDOM() * 10 + 1)::integer -- Random stock between 1-10
FROM 
  products p
CROSS JOIN (
  VALUES 
    ('Black'),
    ('Gray'),
    ('Navy'),
    ('Red'),
    ('White'),
    ('Blue')
) AS color(name)
CROSS JOIN (
  VALUES 
    ('XS'),
    ('S'),
    ('M'),
    ('L'),
    ('XL'),
    ('XXL'),
    ('3XL')
) AS size(name)
WHERE 
  p.category = 'Gym Wear'
ON CONFLICT (product_id, color, size) DO NOTHING;