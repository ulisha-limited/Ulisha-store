/*
  # Complete Database Migration Fix

  1. Policy Management
    - Safely drop and recreate policies to avoid conflicts
    - Ensure proper RLS policies for all tables
    
  2. Trigger Management
    - Handle existing triggers and constraints
    - Recreate validation functions
    
  3. Index Optimization
    - Add missing indexes for performance
    - Optimize variant lookups
*/

-- =============================================
-- POLICY MANAGEMENT
-- =============================================

-- Drop existing policies if they exist to avoid conflicts
DROP POLICY IF EXISTS "Anyone can view product variants" ON product_variants;
DROP POLICY IF EXISTS "Only admins can manage product variants" ON product_variants;

-- Recreate product_variants policies
CREATE POLICY "Anyone can view product variants"
ON product_variants FOR SELECT
TO public
USING (true);

CREATE POLICY "Only admins can manage product variants"
ON product_variants FOR ALL
TO authenticated
USING (email() = ANY (ARRAY['paulelite606@gmail.com'::text, 'obajeufedo2@gmail.com'::text]))
WITH CHECK (email() = ANY (ARRAY['paulelite606@gmail.com'::text, 'obajeufedo2@gmail.com'::text]));

-- =============================================
-- TRIGGER AND CONSTRAINT MANAGEMENT
-- =============================================

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

-- =============================================
-- INDEX OPTIMIZATION
-- =============================================

-- Add indexes for better performance on variant lookups
CREATE INDEX IF NOT EXISTS idx_cart_items_variant_lookup 
ON cart_items_new (variant_id, selected_color, selected_size);

CREATE INDEX IF NOT EXISTS idx_order_items_variant_lookup 
ON order_items (variant_id, selected_color, selected_size);

-- Add index on product_variants for validation queries
CREATE INDEX IF NOT EXISTS idx_product_variants_color_size 
ON product_variants (color, size);

-- Add missing indexes for better performance
CREATE INDEX IF NOT EXISTS idx_products_discount_active 
ON products (discount_active) WHERE discount_active = true;

CREATE INDEX IF NOT EXISTS idx_orders_status_created 
ON orders (status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_cart_items_session_product 
ON cart_items_new (session_id, product_id);

-- =============================================
-- ADDITIONAL SAFETY CHECKS
-- =============================================

-- Ensure RLS is enabled on all tables
ALTER TABLE product_variants ENABLE ROW LEVEL SECURITY;
ALTER TABLE cart_items_new ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

-- Add any missing foreign key constraints
DO $$
BEGIN
  -- Check if foreign key exists before adding
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'fk_cart_items_variant' 
    AND table_name = 'cart_items_new'
  ) THEN
    ALTER TABLE cart_items_new 
    ADD CONSTRAINT fk_cart_items_variant 
    FOREIGN KEY (variant_id) REFERENCES product_variants(id);
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'fk_order_items_variant' 
    AND table_name = 'order_items'
  ) THEN
    ALTER TABLE order_items 
    ADD CONSTRAINT fk_order_items_variant 
    FOREIGN KEY (variant_id) REFERENCES product_variants(id);
  END IF;
END $$;

-- =============================================
-- ANALYTICS FUNCTIONS
-- =============================================

-- Create or replace analytics functions
CREATE OR REPLACE FUNCTION update_daily_stats()
RETURNS void AS $$
BEGIN
  -- Update today's stats
  INSERT INTO analytics_daily_stats (
    date,
    unique_visitors,
    page_views,
    new_users,
    orders_count,
    revenue
  )
  SELECT 
    CURRENT_DATE,
    COUNT(DISTINCT session_id) as unique_visitors,
    COUNT(*) as page_views,
    COUNT(DISTINCT user_id) FILTER (WHERE created_at::date = CURRENT_DATE) as new_users,
    (SELECT COUNT(*) FROM orders WHERE created_at::date = CURRENT_DATE) as orders_count,
    (SELECT COALESCE(SUM(total), 0) FROM orders WHERE created_at::date = CURRENT_DATE AND status = 'completed') as revenue
  FROM analytics_page_views 
  WHERE created_at::date = CURRENT_DATE
  ON CONFLICT (date) 
  DO UPDATE SET
    unique_visitors = EXCLUDED.unique_visitors,
    page_views = EXCLUDED.page_views,
    new_users = EXCLUDED.new_users,
    orders_count = EXCLUDED.orders_count,
    revenue = EXCLUDED.revenue,
    updated_at = now();
END;
$$ LANGUAGE plpgsql;

-- Create function to track page views
CREATE OR REPLACE FUNCTION track_page_view(
  p_session_id text,
  p_user_id uuid DEFAULT NULL,
  p_page_path text DEFAULT '/',
  p_user_agent text DEFAULT NULL,
  p_ip_address text DEFAULT NULL,
  p_referrer text DEFAULT NULL
)
RETURNS void AS $$
BEGIN
  INSERT INTO analytics_page_views (
    session_id,
    user_id,
    page_path,
    user_agent,
    ip_address,
    referrer
  ) VALUES (
    p_session_id,
    p_user_id,
    p_page_path,
    p_user_agent,
    p_ip_address,
    p_referrer
  );
END;
$$ LANGUAGE plpgsql;