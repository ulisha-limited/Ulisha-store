/*
  # Fix variant data validation triggers and constraints

  1. Clean up existing triggers and constraints safely
  2. Recreate function and triggers with proper error handling
  3. Add variant data validation constraints

  This migration safely handles existing database objects to prevent conflicts.
*/

-- Drop existing triggers if they exist
DROP TRIGGER IF EXISTS validate_cart_variant_data ON cart_items_new;
DROP TRIGGER IF EXISTS validate_order_variant_data ON order_items;

-- Drop existing constraints if they exist
ALTER TABLE cart_items_new DROP CONSTRAINT IF EXISTS check_variant_data;
ALTER TABLE order_items DROP CONSTRAINT IF EXISTS check_variant_data;

-- Drop and recreate the function to ensure it's up to date
DROP FUNCTION IF EXISTS validate_variant_data() CASCADE;

-- Create the validation function
CREATE OR REPLACE FUNCTION validate_variant_data()
RETURNS TRIGGER AS $$
BEGIN
  -- If variant_id is provided, validate that all variant fields are consistent
  IF NEW.variant_id IS NOT NULL THEN
    -- Check that color and size are also provided
    IF NEW.selected_color IS NULL OR NEW.selected_size IS NULL THEN
      RAISE EXCEPTION 'When variant_id is provided, selected_color and selected_size must also be provided';
    END IF;
    
    -- Verify that the variant exists and matches the selected color and size
    IF NOT EXISTS (
      SELECT 1 FROM product_variants
      WHERE id = NEW.variant_id
      AND color = NEW.selected_color
      AND size = NEW.selected_size
    ) THEN
      RAISE EXCEPTION 'Invalid variant data: variant does not match selected color and size';
    END IF;
  ELSE
    -- If no variant_id, ensure color and size are also null
    IF NEW.selected_color IS NOT NULL OR NEW.selected_size IS NOT NULL THEN
      RAISE EXCEPTION 'When variant_id is null, selected_color and selected_size must also be null';
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add constraints to ensure variant data consistency
ALTER TABLE cart_items_new
ADD CONSTRAINT check_variant_data
CHECK (
  (variant_id IS NOT NULL AND selected_color IS NOT NULL AND selected_size IS NOT NULL) OR
  (variant_id IS NULL AND selected_color IS NULL AND selected_size IS NULL)
);

ALTER TABLE order_items
ADD CONSTRAINT check_variant_data
CHECK (
  (variant_id IS NOT NULL AND selected_color IS NOT NULL AND selected_size IS NOT NULL) OR
  (variant_id IS NULL AND selected_color IS NULL AND selected_size IS NULL)
);

-- Create triggers to validate variant data
CREATE TRIGGER validate_cart_variant_data
BEFORE INSERT OR UPDATE ON cart_items_new
FOR EACH ROW
EXECUTE FUNCTION validate_variant_data();

CREATE TRIGGER validate_order_variant_data
BEFORE INSERT OR UPDATE ON order_items
FOR EACH ROW
EXECUTE FUNCTION validate_variant_data();

-- Add indexes for better performance on variant lookups
CREATE INDEX IF NOT EXISTS idx_cart_items_variant_lookup 
ON cart_items_new (variant_id, selected_color, selected_size);

CREATE INDEX IF NOT EXISTS idx_order_items_variant_lookup 
ON order_items (variant_id, selected_color, selected_size);

-- Add index on product_variants for validation queries
CREATE INDEX IF NOT EXISTS idx_product_variants_color_size 
ON product_variants (color, size);