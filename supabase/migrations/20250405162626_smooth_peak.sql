/*
  # Add variant storage to cart and orders

  1. Changes
    - Add variant_id to cart_items_new table
    - Add selected_color and selected_size to cart_items_new table
    - Add variant_id to order_items table
    - Add selected_color and selected_size to order_items table
    
  2. Security
    - Maintain existing RLS policies
*/

-- Add variant columns to cart_items_new
ALTER TABLE cart_items_new
ADD COLUMN IF NOT EXISTS variant_id uuid REFERENCES product_variants(id),
ADD COLUMN IF NOT EXISTS selected_color text,
ADD COLUMN IF NOT EXISTS selected_size text;

-- Add variant columns to order_items
ALTER TABLE order_items
ADD COLUMN IF NOT EXISTS variant_id uuid REFERENCES product_variants(id),
ADD COLUMN IF NOT EXISTS selected_color text,
ADD COLUMN IF NOT EXISTS selected_size text;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_cart_items_new_variant_id ON cart_items_new(variant_id);
CREATE INDEX IF NOT EXISTS idx_order_items_variant_id ON order_items(variant_id);