/*
  # Complete Database Fix and Enhancement

  1. Policy Management
    - Safely drop and recreate conflicting policies
    - Ensure proper permissions for all tables

  2. Delivery Options Enhancement
    - Add delivery fee tracking
    - Add payment option tracking

  3. Payment System Fixes
    - Fix order creation issues
    - Improve error handling

  4. Performance Optimization
    - Add strategic indexes
    - Optimize queries
*/

-- =============================================
-- POLICY CONFLICT RESOLUTION
-- =============================================

-- Drop ALL existing policies that might conflict
DO $$
DECLARE
    r RECORD;
BEGIN
    -- Drop all policies on product_variants to avoid conflicts
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'product_variants') LOOP
        EXECUTE 'DROP POLICY IF EXISTS ' || quote_ident(r.policyname) || ' ON product_variants';
    END LOOP;
END $$;

-- Recreate product_variants policies with proper names
CREATE POLICY "product_variants_select_policy"
ON product_variants FOR SELECT
TO public
USING (true);

CREATE POLICY "product_variants_admin_policy"
ON product_variants FOR ALL
TO authenticated
USING (email() = ANY (ARRAY['paulelite606@gmail.com'::text, 'obajeufedo2@gmail.com'::text]))
WITH CHECK (email() = ANY (ARRAY['paulelite606@gmail.com'::text, 'obajeufedo2@gmail.com'::text]));

-- =============================================
-- DELIVERY OPTIONS ENHANCEMENT
-- =============================================

-- Add delivery fee tracking to orders table
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'orders' AND column_name = 'delivery_fee'
  ) THEN
    ALTER TABLE orders ADD COLUMN delivery_fee numeric DEFAULT 0;
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'orders' AND column_name = 'delivery_fee_paid'
  ) THEN
    ALTER TABLE orders ADD COLUMN delivery_fee_paid boolean DEFAULT true;
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'orders' AND column_name = 'payment_option'
  ) THEN
    ALTER TABLE orders ADD COLUMN payment_option text DEFAULT 'full';
  END IF;
END $$;

-- Add constraint for payment_option
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'check_payment_option' AND table_name = 'orders'
  ) THEN
    ALTER TABLE orders ADD CONSTRAINT check_payment_option 
    CHECK (payment_option IN ('full', 'partial'));
  END IF;
END $$;

-- =============================================
-- TRIGGER AND CONSTRAINT MANAGEMENT
-- =============================================

-- Drop existing triggers and constraints to avoid conflicts
DROP TRIGGER IF EXISTS validate_cart_variant_data ON cart_items_new CASCADE;
DROP TRIGGER IF EXISTS validate_order_variant_data ON order_items CASCADE;

-- Drop existing constraints
ALTER TABLE cart_items_new DROP CONSTRAINT IF EXISTS check_variant_data CASCADE;
ALTER TABLE order_items DROP CONSTRAINT IF EXISTS check_variant_data CASCADE;

-- Drop and recreate the validation function
DROP FUNCTION IF EXISTS validate_variant_data() CASCADE;

-- Create improved validation function with better error handling
CREATE OR REPLACE FUNCTION validate_variant_data()
RETURNS TRIGGER AS $$
BEGIN
  -- Skip validation if this is a system operation
  IF current_setting('app.skip_variant_validation', true) = 'true' THEN
    RETURN NEW;
  END IF;

  -- If variant_id is provided, validate consistency
  IF NEW.variant_id IS NOT NULL THEN
    -- Check that color and size are also provided
    IF NEW.selected_color IS NULL OR NEW.selected_size IS NULL THEN
      RAISE EXCEPTION 'Variant requires both color and size to be specified';
    END IF;
    
    -- Verify that the variant exists and matches
    IF NOT EXISTS (
      SELECT 1 FROM product_variants
      WHERE id = NEW.variant_id
      AND color = NEW.selected_color
      AND size = NEW.selected_size
    ) THEN
      -- Log the error for debugging
      RAISE WARNING 'Variant validation failed: variant_id=%, color=%, size=%', 
        NEW.variant_id, NEW.selected_color, NEW.selected_size;
      RAISE EXCEPTION 'Selected variant does not match color and size combination';
    END IF;
  ELSE
    -- If no variant_id, color and size should also be null
    IF NEW.selected_color IS NOT NULL OR NEW.selected_size IS NOT NULL THEN
      RAISE EXCEPTION 'Color and size can only be specified with a valid variant';
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add improved constraints
ALTER TABLE cart_items_new
ADD CONSTRAINT check_variant_data_consistency
CHECK (
  (variant_id IS NOT NULL AND selected_color IS NOT NULL AND selected_size IS NOT NULL) OR
  (variant_id IS NULL AND selected_color IS NULL AND selected_size IS NULL)
);

ALTER TABLE order_items
ADD CONSTRAINT check_variant_data_consistency
CHECK (
  (variant_id IS NOT NULL AND selected_color IS NOT NULL AND selected_size IS NOT NULL) OR
  (variant_id IS NULL AND selected_color IS NULL AND selected_size IS NULL)
);

-- Create triggers with better error handling
CREATE TRIGGER validate_cart_variant_data_trigger
BEFORE INSERT OR UPDATE ON cart_items_new
FOR EACH ROW
EXECUTE FUNCTION validate_variant_data();

CREATE TRIGGER validate_order_variant_data_trigger
BEFORE INSERT OR UPDATE ON order_items
FOR EACH ROW
EXECUTE FUNCTION validate_variant_data();

-- =============================================
-- ORDER CREATION FIX
-- =============================================

-- Create improved order creation function
CREATE OR REPLACE FUNCTION create_order_with_items(
  p_user_id uuid,
  p_total numeric,
  p_delivery_fee numeric DEFAULT 0,
  p_delivery_fee_paid boolean DEFAULT true,
  p_payment_option text DEFAULT 'full',
  p_delivery_name text DEFAULT NULL,
  p_delivery_phone text DEFAULT NULL,
  p_delivery_address text DEFAULT NULL,
  p_payment_method text DEFAULT NULL,
  p_payment_ref text DEFAULT NULL,
  p_cart_items jsonb DEFAULT '[]'::jsonb
)
RETURNS uuid AS $$
DECLARE
  v_order_id uuid;
  v_item jsonb;
BEGIN
  -- Create the order
  INSERT INTO orders (
    user_id,
    total,
    delivery_fee,
    delivery_fee_paid,
    payment_option,
    status,
    delivery_name,
    delivery_phone,
    delivery_address,
    payment_method,
    payment_ref
  ) VALUES (
    p_user_id,
    p_total,
    p_delivery_fee,
    p_delivery_fee_paid,
    p_payment_option,
    'pending',
    p_delivery_name,
    p_delivery_phone,
    p_delivery_address,
    p_payment_method,
    p_payment_ref
  ) RETURNING id INTO v_order_id;

  -- Insert order items if provided
  IF jsonb_array_length(p_cart_items) > 0 THEN
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_cart_items)
    LOOP
      INSERT INTO order_items (
        order_id,
        product_id,
        quantity,
        price,
        variant_id,
        selected_color,
        selected_size
      ) VALUES (
        v_order_id,
        (v_item->>'product_id')::uuid,
        (v_item->>'quantity')::integer,
        (v_item->>'price')::numeric,
        CASE WHEN v_item->>'variant_id' != 'null' THEN (v_item->>'variant_id')::uuid ELSE NULL END,
        CASE WHEN v_item->>'selected_color' != 'null' THEN v_item->>'selected_color' ELSE NULL END,
        CASE WHEN v_item->>'selected_size' != 'null' THEN v_item->>'selected_size' ELSE NULL END
      );
    END LOOP;
  END IF;

  RETURN v_order_id;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- PERFORMANCE OPTIMIZATION
-- =============================================

-- Add strategic indexes for better performance
CREATE INDEX IF NOT EXISTS idx_orders_user_status_created 
ON orders (user_id, status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_orders_payment_ref_status 
ON orders (payment_ref, status) WHERE payment_ref IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_cart_items_session_active 
ON cart_items_new (session_id, is_saved_for_later);

CREATE INDEX IF NOT EXISTS idx_product_variants_product_color_size 
ON product_variants (product_id, color, size);

CREATE INDEX IF NOT EXISTS idx_shopping_sessions_user_status 
ON shopping_sessions (user_id, status);

-- =============================================
-- DATA INTEGRITY IMPROVEMENTS
-- =============================================

-- Ensure RLS is enabled on all critical tables
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE cart_items_new ENABLE ROW LEVEL SECURITY;
ALTER TABLE shopping_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_variants ENABLE ROW LEVEL SECURITY;

-- Add missing foreign key constraints with proper error handling
DO $$
BEGIN
  -- Add variant foreign key to cart_items_new if not exists
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'cart_items_new_variant_id_fkey' 
    AND table_name = 'cart_items_new'
  ) THEN
    ALTER TABLE cart_items_new 
    ADD CONSTRAINT cart_items_new_variant_id_fkey 
    FOREIGN KEY (variant_id) REFERENCES product_variants(id) ON DELETE SET NULL;
  END IF;
  
  -- Add variant foreign key to order_items if not exists
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'order_items_variant_id_fkey' 
    AND table_name = 'order_items'
  ) THEN
    ALTER TABLE order_items 
    ADD CONSTRAINT order_items_variant_id_fkey 
    FOREIGN KEY (variant_id) REFERENCES product_variants(id) ON DELETE SET NULL;
  END IF;
END $$;

-- =============================================
-- ANALYTICS AND MONITORING
-- =============================================

-- Create function to safely update analytics
CREATE OR REPLACE FUNCTION safe_update_daily_stats()
RETURNS void AS $$
BEGIN
  -- Update today's stats with error handling
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
    COALESCE(COUNT(DISTINCT session_id), 0) as unique_visitors,
    COALESCE(COUNT(*), 0) as page_views,
    COALESCE(COUNT(DISTINCT user_id) FILTER (WHERE created_at::date = CURRENT_DATE), 0) as new_users,
    COALESCE((SELECT COUNT(*) FROM orders WHERE created_at::date = CURRENT_DATE), 0) as orders_count,
    COALESCE((SELECT SUM(total) FROM orders WHERE created_at::date = CURRENT_DATE AND status = 'completed'), 0) as revenue
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
EXCEPTION
  WHEN OTHERS THEN
    -- Log error but don't fail
    RAISE WARNING 'Failed to update daily stats: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- CLEANUP AND VALIDATION
-- =============================================

-- Clean up any orphaned data
DELETE FROM cart_items_new 
WHERE session_id NOT IN (SELECT id FROM shopping_sessions);

DELETE FROM order_items 
WHERE order_id NOT IN (SELECT id FROM orders);

-- Update any existing orders without delivery fee information
UPDATE orders 
SET delivery_fee = 0, delivery_fee_paid = true, payment_option = 'full'
WHERE delivery_fee IS NULL;

-- Ensure all products have proper shipping location
UPDATE products 
SET shipping_location = 'Nigeria' 
WHERE shipping_location IS NULL;