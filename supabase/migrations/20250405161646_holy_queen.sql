/*
  # Add sample product variants

  1. Changes
    - Add sample color and size variants for testing
    - Include common colors and sizes
    - Set initial stock levels
*/

-- Insert sample variants for existing products
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
    ('White'),
    ('Red'),
    ('Blue'),
    ('Green')
) AS color(name)
CROSS JOIN (
  VALUES 
    ('S'),
    ('M'),
    ('L'),
    ('XL'),
    ('XXL')
) AS size(name)
WHERE 
  p.category = 'Clothes'
ON CONFLICT (product_id, color, size) DO NOTHING;

-- Add variants for accessories
INSERT INTO product_variants (product_id, color, size, stock)
SELECT 
  p.id,
  color.name,
  'One Size',
  FLOOR(RANDOM() * 10 + 1)::integer
FROM 
  products p
CROSS JOIN (
  VALUES 
    ('Gold'),
    ('Silver'),
    ('Rose Gold'),
    ('Black'),
    ('White')
) AS color(name)
WHERE 
  p.category = 'Accessories'
ON CONFLICT (product_id, color, size) DO NOTHING;