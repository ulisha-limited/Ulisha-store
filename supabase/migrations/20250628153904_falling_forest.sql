/*
  # Fix variant data validation constraints and triggers

  1. Drop existing triggers first (to remove dependencies)
  2. Drop existing function
  3. Drop and recreate constraints
  4. Create new function and triggers

  This ensures proper order of operations to avoid dependency errors.
*/

-- Drop existing triggers first (to remove dependencies on the function)
DROP TRIGGER IF EXISTS validate_cart_variant_data ON cart_items_new;
DROP TRIGGER IF EXISTS validate_order_variant_data ON order_items;

-- Now we can safely drop the function
DROP FUNCTION IF EXISTS validate_variant_data();

-- Drop existing constraints if they exist
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'check_variant_data' AND table_name = 'cart_items_new'
  ) THEN
    ALTER TABLE cart_items_new DROP CONSTRAINT check_variant_data;
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'check_variant_data' AND table_name = 'order_items'
  ) THEN
    ALTER TABLE order_items DROP CONSTRAINT check_variant_data;
  END IF;
END $$;

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

-- Create function to validate variant data
CREATE OR REPLACE FUNCTION validate_variant_data()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.variant_id IS NOT NULL THEN
    -- Verify that the variant exists and matches the selected color and size
    IF NOT EXISTS (
      SELECT 1 FROM product_variants
      WHERE id = NEW.variant_id
      AND color = NEW.selected_color
      AND size = NEW.selected_size
    ) THEN
      RAISE EXCEPTION 'Invalid variant data: variant_id % does not match color % and size %', 
        NEW.variant_id, NEW.selected_color, NEW.selected_size;
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers to validate variant data
CREATE TRIGGER validate_cart_variant_data
BEFORE INSERT OR UPDATE ON cart_items_new
FOR EACH ROW
EXECUTE FUNCTION validate_variant_data();

CREATE TRIGGER validate_order_variant_data
BEFORE INSERT OR UPDATE ON order_items
FOR EACH ROW
EXECUTE FUNCTION validate_variant_data();