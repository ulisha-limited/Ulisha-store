/*
  # Add shoe size variants

  1. Changes
    - Add shoe sizes from 25 to 47
    - Include common shoe colors
    - Set initial stock levels
*/

-- Insert shoe variants
INSERT INTO product_variants (product_id, color, size, stock)
SELECT 
  p.id,
  color.name,
  size.name::text,
  FLOOR(RANDOM() * 10 + 1)::integer -- Random stock between 1-10
FROM 
  products p
CROSS JOIN (
  VALUES 
    ('Black'),
    ('White'),
    ('Brown'),
    ('Navy'),
    ('Gray')
) AS color(name)
CROSS JOIN (
  VALUES 
    ('25'), ('26'), ('27'), ('28'), ('29'), ('30'),
    ('31'), ('32'), ('33'), ('34'), ('35'), ('36'),
    ('37'), ('38'), ('39'), ('40'), ('41'), ('42'),
    ('43'), ('44'), ('45'), ('46'), ('47')
) AS size(name)
WHERE 
  p.category = 'Shoes'
ON CONFLICT (product_id, color, size) DO NOTHING;