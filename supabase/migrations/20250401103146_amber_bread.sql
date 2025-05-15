/*
  # Add product discount functionality

  1. Changes
    - Add original_price column to products table
    - Add discount_price column to products table
    - Add discount_percentage column to products table (calculated)
    - Add discount_active column to products table
  
  2. Security
    - Maintain existing RLS policies
*/

-- Add discount-related columns to products table
ALTER TABLE products 
ADD COLUMN IF NOT EXISTS original_price numeric,
ADD COLUMN IF NOT EXISTS discount_price numeric,
ADD COLUMN IF NOT EXISTS discount_active boolean DEFAULT false,
ADD COLUMN IF NOT EXISTS discount_percentage numeric GENERATED ALWAYS AS (
  CASE 
    WHEN original_price > 0 AND discount_price > 0 
    THEN ROUND((1 - (discount_price / original_price)) * 100)
    ELSE 0 
  END
) STORED;

-- Update existing products to set original_price equal to current price
UPDATE products 
SET original_price = price 
WHERE original_price IS NULL;

-- Add constraint to ensure discount_price is less than original_price
ALTER TABLE products
ADD CONSTRAINT check_discount_price
CHECK (discount_price IS NULL OR (discount_price > 0 AND discount_price < original_price));

-- Create function to update price based on discount
CREATE OR REPLACE FUNCTION update_product_price()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.discount_active = true AND NEW.discount_price IS NOT NULL THEN
    NEW.price = NEW.discount_price;
  ELSE
    NEW.price = NEW.original_price;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update price
CREATE TRIGGER update_product_price_trigger
BEFORE INSERT OR UPDATE ON products
FOR EACH ROW
EXECUTE FUNCTION update_product_price();