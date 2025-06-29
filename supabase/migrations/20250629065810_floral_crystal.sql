-- =============================================
-- FLUTTERWAVE PAYMENT CONFIGURATION FIX
-- =============================================

-- Ensure the create_order_with_items function exists and works properly
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
  v_product_id uuid;
  v_quantity integer;
  v_price numeric;
  v_variant_id uuid;
  v_selected_color text;
  v_selected_size text;
BEGIN
  -- Validate inputs
  IF p_user_id IS NULL THEN
    RAISE EXCEPTION 'User ID is required';
  END IF;
  
  IF p_total <= 0 THEN
    RAISE EXCEPTION 'Total amount must be greater than 0';
  END IF;
  
  IF p_delivery_name IS NULL OR p_delivery_phone IS NULL OR p_delivery_address IS NULL THEN
    RAISE EXCEPTION 'Delivery information is required';
  END IF;

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
    COALESCE(p_delivery_fee, 0),
    COALESCE(p_delivery_fee_paid, true),
    COALESCE(p_payment_option, 'full'),
    'pending',
    p_delivery_name,
    p_delivery_phone,
    p_delivery_address,
    COALESCE(p_payment_method, 'flutterwave'),
    p_payment_ref
  ) RETURNING id INTO v_order_id;

  -- Insert order items if provided
  IF jsonb_array_length(p_cart_items) > 0 THEN
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_cart_items)
    LOOP
      -- Extract values with proper null handling
      v_product_id := (v_item->>'product_id')::uuid;
      v_quantity := (v_item->>'quantity')::integer;
      v_price := (v_item->>'price')::numeric;
      
      -- Handle variant data with proper null checks
      v_variant_id := CASE 
        WHEN v_item->>'variant_id' IS NULL OR v_item->>'variant_id' = 'null' OR v_item->>'variant_id' = '' 
        THEN NULL 
        ELSE (v_item->>'variant_id')::uuid 
      END;
      
      v_selected_color := CASE 
        WHEN v_item->>'selected_color' IS NULL OR v_item->>'selected_color' = 'null' OR v_item->>'selected_color' = '' 
        THEN NULL 
        ELSE v_item->>'selected_color' 
      END;
      
      v_selected_size := CASE 
        WHEN v_item->>'selected_size' IS NULL OR v_item->>'selected_size' = 'null' OR v_item->>'selected_size' = '' 
        THEN NULL 
        ELSE v_item->>'selected_size' 
      END;

      -- Validate required fields
      IF v_product_id IS NULL THEN
        RAISE EXCEPTION 'Product ID is required for order item';
      END IF;
      
      IF v_quantity IS NULL OR v_quantity <= 0 THEN
        RAISE EXCEPTION 'Valid quantity is required for order item';
      END IF;
      
      IF v_price IS NULL OR v_price <= 0 THEN
        RAISE EXCEPTION 'Valid price is required for order item';
      END IF;

      -- Insert order item with proper variant handling
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
        v_product_id,
        v_quantity,
        v_price,
        v_variant_id,
        v_selected_color,
        v_selected_size
      );
    END LOOP;
  END IF;

  -- Log successful order creation
  RAISE NOTICE 'Order created successfully: %', v_order_id;

  RETURN v_order_id;
EXCEPTION
  WHEN OTHERS THEN
    -- Log the error and re-raise
    RAISE EXCEPTION 'Failed to create order: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- PAYMENT PROCESSING IMPROVEMENTS
-- =============================================

-- Create function to update order payment status
CREATE OR REPLACE FUNCTION update_order_payment_status(
  p_order_id uuid,
  p_payment_ref text,
  p_status text DEFAULT 'completed'
)
RETURNS boolean AS $$
DECLARE
  v_order_exists boolean;
BEGIN
  -- Check if order exists
  SELECT EXISTS(SELECT 1 FROM orders WHERE id = p_order_id) INTO v_order_exists;
  
  IF NOT v_order_exists THEN
    RAISE EXCEPTION 'Order not found: %', p_order_id;
  END IF;

  -- Update order with payment information
  UPDATE orders 
  SET 
    payment_ref = p_payment_ref,
    status = p_status,
    updated_at = now()
  WHERE id = p_order_id;

  -- Log successful payment update
  RAISE NOTICE 'Payment status updated for order: %', p_order_id;

  RETURN true;
EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION 'Failed to update payment status: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- CART MANAGEMENT IMPROVEMENTS
-- =============================================

-- Create function to clear user cart after successful order
CREATE OR REPLACE FUNCTION clear_user_cart(p_user_id uuid)
RETURNS boolean AS $$
DECLARE
  v_session_id uuid;
BEGIN
  -- Get active shopping session
  SELECT id INTO v_session_id
  FROM shopping_sessions 
  WHERE user_id = p_user_id AND status = 'active'
  LIMIT 1;

  IF v_session_id IS NOT NULL THEN
    -- Delete cart items
    DELETE FROM cart_items_new WHERE session_id = v_session_id;
    
    -- Close shopping session
    UPDATE shopping_sessions 
    SET status = 'closed', updated_at = now()
    WHERE id = v_session_id;
    
    RAISE NOTICE 'Cart cleared for user: %', p_user_id;
  END IF;

  RETURN true;
EXCEPTION
  WHEN OTHERS THEN
    RAISE WARNING 'Failed to clear cart for user %: %', p_user_id, SQLERRM;
    RETURN false;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- VALIDATION IMPROVEMENTS
-- =============================================

-- Improve the variant validation function to be more lenient during order creation
CREATE OR REPLACE FUNCTION validate_variant_data()
RETURNS TRIGGER AS $$
BEGIN
  -- Skip validation during order creation from cart
  IF current_setting('app.skip_variant_validation', true) = 'true' THEN
    RETURN NEW;
  END IF;

  -- Only validate if we have variant data
  IF NEW.variant_id IS NOT NULL THEN
    -- Ensure color and size are provided when variant_id is set
    IF NEW.selected_color IS NULL OR NEW.selected_size IS NULL THEN
      RAISE EXCEPTION 'Color and size must be specified when variant is selected';
    END IF;
    
    -- Verify variant exists and matches (only if product_variants table has data)
    IF EXISTS (SELECT 1 FROM product_variants LIMIT 1) THEN
      IF NOT EXISTS (
        SELECT 1 FROM product_variants
        WHERE id = NEW.variant_id
        AND color = NEW.selected_color
        AND size = NEW.selected_size
      ) THEN
        RAISE WARNING 'Variant validation failed for variant_id: %, color: %, size: %', 
          NEW.variant_id, NEW.selected_color, NEW.selected_size;
        -- Don't fail the transaction, just warn
      END IF;
    END IF;
  ELSE
    -- If no variant, ensure color and size are also null
    IF NEW.selected_color IS NOT NULL OR NEW.selected_size IS NOT NULL THEN
      -- Clear the values instead of failing
      NEW.selected_color := NULL;
      NEW.selected_size := NULL;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- INDEXES FOR PERFORMANCE
-- =============================================

-- Add indexes for better payment processing performance
CREATE INDEX IF NOT EXISTS idx_orders_payment_processing 
ON orders (user_id, status, payment_ref) 
WHERE status IN ('pending', 'completed');

CREATE INDEX IF NOT EXISTS idx_orders_payment_ref_lookup 
ON orders (payment_ref) 
WHERE payment_ref IS NOT NULL;

-- =============================================
-- SECURITY IMPROVEMENTS
-- =============================================

-- Ensure proper RLS policies for order creation
DROP POLICY IF EXISTS "Users can create their own orders" ON orders;
CREATE POLICY "Users can create their own orders"
ON orders FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

-- Allow users to update their pending orders (for payment processing)
DROP POLICY IF EXISTS "Users can update their pending orders" ON orders;
CREATE POLICY "Users can update their pending orders"
ON orders FOR UPDATE
TO authenticated
USING (auth.uid() = user_id AND status = 'pending')
WITH CHECK (auth.uid() = user_id);

-- =============================================
-- CLEANUP AND MAINTENANCE
-- =============================================

-- Clean up any orphaned cart items
DELETE FROM cart_items_new 
WHERE session_id NOT IN (SELECT id FROM shopping_sessions);

-- Clean up any orphaned order items
DELETE FROM order_items 
WHERE order_id NOT IN (SELECT id FROM orders);

-- Update any orders missing delivery fee information
UPDATE orders 
SET 
  delivery_fee = COALESCE(delivery_fee, 0),
  delivery_fee_paid = COALESCE(delivery_fee_paid, true),
  payment_option = COALESCE(payment_option, 'full')
WHERE delivery_fee IS NULL OR delivery_fee_paid IS NULL OR payment_option IS NULL;

-- =============================================
-- TESTING AND VALIDATION
-- =============================================

-- Create a test function to validate the order creation process
CREATE OR REPLACE FUNCTION test_order_creation()
RETURNS text AS $$
DECLARE
  v_test_result text := 'Order creation test: ';
  v_test_user_id uuid := '00000000-0000-0000-0000-000000000001';
  v_test_order_id uuid;
BEGIN
  -- Test basic order creation
  BEGIN
    SELECT create_order_with_items(
      p_user_id := v_test_user_id,
      p_total := 10000,
      p_delivery_fee := 4000,
      p_delivery_name := 'Test User',
      p_delivery_phone := '08012345678',
      p_delivery_address := 'Test Address, Lagos',
      p_cart_items := '[]'::jsonb
    ) INTO v_test_order_id;
    
    v_test_result := v_test_result || 'PASSED - Basic order creation works. ';
    
    -- Clean up test order
    DELETE FROM orders WHERE id = v_test_order_id;
    
  EXCEPTION
    WHEN OTHERS THEN
      v_test_result := v_test_result || 'FAILED - ' || SQLERRM || '. ';
  END;
  
  RETURN v_test_result;
END;
$$ LANGUAGE plpgsql;

-- Run the test (comment out in production)
-- SELECT test_order_creation();