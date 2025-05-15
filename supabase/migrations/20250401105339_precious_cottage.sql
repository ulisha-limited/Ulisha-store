/*
  # Add shipping location to products

  1. Changes
    - Add shipping_location column to products table
    - Add check constraint to validate location values
    - Update existing products to default to 'Nigeria'
*/

-- Add shipping_location column
ALTER TABLE products 
ADD COLUMN IF NOT EXISTS shipping_location text NOT NULL DEFAULT 'Nigeria';

-- Add check constraint to validate location values
ALTER TABLE products
ADD CONSTRAINT check_shipping_location
CHECK (shipping_location IN ('Nigeria', 'Abroad'));

-- Create index for better filtering performance
CREATE INDEX IF NOT EXISTS idx_products_shipping_location ON products(shipping_location);