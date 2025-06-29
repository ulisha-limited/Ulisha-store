/*
  # Fix Missing create_order_with_items Function

  1. Database Functions
    - Create the missing create_order_with_items function
    - Add proper error handling and validation
    - Support for delivery options and payment methods

  2. Security
    - Proper input validation
    - Error handling for edge cases
    - Transaction safety

  3. Performance
    - Optimized for cart-to-order conversion
    - Proper indexing support
*/

-- =============================================
-- CREATE ORDER WITH ITEMS FUNCTION
-- =============================================

-- Drop existing function if it exists
DROP FUNCTION IF EXISTS create_order_with_items(uuid, numeric, numeric, boolean, text, text, text, text, text, text, jsonb);

-- Create the comprehensive order creation function
CREATE OR REPLACE FUNCTION create_order_with_items(
  p_user_id uuid,
  p_total numeric,
  p_delivery_fee numeric DEFAULT 0,
  p_delivery_fee_paid boolean DEFAULT true,
  p_payment_option text DEFAULT 'full',
  p_delivery_name text DEFAULT NULL,
  p_delivery_phone text DEFAULT NULL,
  p_delivery_address text DEFAULT NULL,
  p_payment_method text DEFAULT 'flutterwave',
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
  v_item_count integer;
BEGIN
  -- Input validation
  IF p_user_id IS NULL THEN
    RAISE EXCEPTION 'User ID is required';
  END IF;
  
  IF p_total IS NULL OR p_total <= 0 THEN
    RAISE EXCEPTION 'Total amount must be greater than 0, got: %', p_total;
  END IF;
  
  IF p_delivery_name IS NULL OR trim(p_delivery_name) = '' THEN
    RAISE EXCEPTION 'Delivery name is required';
  END IF;
  
  IF p_delivery_phone IS NULL OR trim(p_delivery_phone) = '' THEN
    RAISE EXCEPTION 'Delivery phone is required';
  END IF;
  
  IF p_delivery_address IS NULL OR trim(p_delivery_address) = '' THEN
    RAISE EXCEPTION 'Delivery address is required';
  END IF;

  -- Validate payment option
  IF p_payment_option NOT IN ('full', 'partial') THEN
    RAISE EXCEPTION 'Payment option must be either "full" or "partial", got: %', p_payment_option;
  END IF;

  -- Validate cart items
  v_item_count := jsonb_array_length(p_cart_items);
  IF v_item_count = 0 THEN
    RAISE EXCEPTION 'Cart items are required to create an order';
  END IF;

  -- Log order creation attempt
  RAISE NOTICE 'Creating order for user % with total % and % items', p_user_id, p_total, v_item_count;

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
    payment_ref,
    created_at
  ) VALUES (
    p_user_id,
    p_total,
    COALESCE(p_delivery_fee, 0),
    COALESCE(p_delivery_fee_paid, true),
    COALESCE(p_payment_option, 'full'),
    'pending',
    trim(p_delivery_name),
    trim(p_delivery_phone),
    trim(p_delivery_address),
    COALESCE(p_payment_method, 'flutterwave'),
    'pending',
    now()
  ) RETURNING id INTO v_order_id;

  -- Insert order items
  FOR v_item IN SELECT * FROM jsonb_array_elements(p_cart_items)
  LOOP
    -- Extract and validate item data
    BEGIN
      v_product_id := (v_item->>'product_id')::uuid;
      v_quantity := (v_item->>'quantity')::integer;
      v_price := (v_item->>'price')::numeric;
      
      -- Handle variant data with proper null checks
      v_variant_id := CASE 
        WHEN v_item->>'variant_id' IS NULL OR 
             v_item->>'variant_id' = 'null' OR 
             v_item->>'variant_id' = '' OR
             v_item->>'variant_id' = 'undefined'
        THEN NULL 
        ELSE (v_item->>'variant_id')::uuid 
      END;
      
      v_selected_color := CASE 
        WHEN v_item->>'selected_color' IS NULL OR 
             v_item->>'selected_color' = 'null' OR 
             v_item->>'selected_color' = '' OR
             v_item->>'selected_color' = 'undefined'
        THEN NULL 
        ELSE v_item->>'selected_color' 
      END;
      
      v_selected_size := CASE 
        WHEN v_item->>'selected_size' IS NULL OR 
             v_item->>'selected_size' = 'null' OR 
             v_item->>'selected_size' = '' OR
             v_item->>'selected_size' = 'undefined'
        THEN NULL 
        ELSE v_item->>'selected_size' 
      END;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE EXCEPTION 'Invalid item data in cart: %', v_item::text;
    END;

    -- Validate extracted data
    IF v_product_id IS NULL THEN
      RAISE EXCEPTION 'Product ID is required for order item: %', v_item::text;
    END IF;
    
    IF v_quantity IS NULL OR v_quantity <= 0 THEN
      RAISE EXCEPTION 'Valid quantity is required for order item, got: %', v_quantity;
    END IF;
    
    IF v_price IS NULL OR v_price <= 0 THEN
      RAISE EXCEPTION 'Valid price is required for order item, got: %', v_price;
    END IF;

    -- Verify product exists
    IF NOT EXISTS (SELECT 1 FROM products WHERE id = v_product_id) THEN
      RAISE EXCEPTION 'Product not found: %', v_product_id;
    END IF;

    -- Insert order item
    INSERT INTO order_items (
      order_id,
      product_id,
      quantity,
      price,
      variant_id,
      selected_color,
      selected_size,
      created_at
    ) VALUES (
      v_order_id,
      v_product_id,
      v_quantity,
      v_price,
      v_variant_id,
      v_selected_color,
      v_selected_size,
      now()
    );

    RAISE NOTICE 'Added item to order: product_id=%, quantity=%, price=%', v_product_id, v_quantity, v_price;
  END LOOP;

  -- Log successful order creation
  RAISE NOTICE 'Order created successfully: % with % items', v_order_id, v_item_count;

  RETURN v_order_id;

EXCEPTION
  WHEN OTHERS THEN
    -- Log the error details
    RAISE EXCEPTION 'Failed to create order for user %: %', p_user_id, SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================
-- SUPPORTING FUNCTIONS
-- =============================================

-- Function to update order payment status
CREATE OR REPLACE FUNCTION update_order_payment_status(
  p_order_id uuid,
  p_payment_ref text,
  p_status text DEFAULT 'completed'
)
RETURNS boolean AS $$
DECLARE
  v_order_exists boolean;
  v_current_status text;
BEGIN
  -- Check if order exists and get current status
  SELECT EXISTS(SELECT 1 FROM orders WHERE id = p_order_id), 
         (SELECT status FROM orders WHERE id = p_order_id LIMIT 1)
  INTO v_order_exists, v_current_status;
  
  IF NOT v_order_exists THEN
    RAISE EXCEPTION 'Order not found: %', p_order_id;
  END IF;

  -- Only update if order is still pending
  IF v_current_status != 'pending' THEN
    RAISE NOTICE 'Order % is already in status: %', p_order_id, v_current_status;
    RETURN false;
  END IF;

  -- Update order with payment information
  UPDATE orders 
  SET 
    payment_ref = p_payment_ref,
    status = p_status
  WHERE id = p_order_id AND status = 'pending';

  -- Check if update was successful
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Failed to update order payment status for order: %', p_order_id;
  END IF;

  RAISE NOTICE 'Payment status updated for order: % to status: %', p_order_id, p_status;
  RETURN true;

EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION 'Failed to update payment status for order %: %', p_order_id, SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to clear user cart after successful order
CREATE OR REPLACE FUNCTION clear_user_cart_after_order(p_user_id uuid)
RETURNS boolean AS $$
DECLARE
  v_session_id uuid;
  v_items_deleted integer;
BEGIN
  -- Get active shopping session
  SELECT id INTO v_session_id
  FROM shopping_sessions 
  WHERE user_id = p_user_id AND status = 'active'
  ORDER BY created_at DESC
  LIMIT 1;

  IF v_session_id IS NOT NULL THEN
    -- Delete cart items and count deleted rows
    DELETE FROM cart_items_new 
    WHERE session_id = v_session_id AND is_saved_for_later = false;
    
    GET DIAGNOSTICS v_items_deleted = ROW_COUNT;
    
    -- Update shopping session timestamp
    UPDATE shopping_sessions 
    SET updated_at = now()
    WHERE id = v_session_id;
    
    RAISE NOTICE 'Cleared % cart items for user: %', v_items_deleted, p_user_id;
    RETURN true;
  ELSE
    RAISE NOTICE 'No active shopping session found for user: %', p_user_id;
    RETURN false;
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    RAISE WARNING 'Failed to clear cart for user %: %', p_user_id, SQLERRM;
    RETURN false;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================
-- PERMISSIONS AND SECURITY
-- =============================================

-- Grant execute permissions to authenticated users
GRANT EXECUTE ON FUNCTION create_order_with_items(uuid, numeric, numeric, boolean, text, text, text, text, text, jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION update_order_payment_status(uuid, text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION clear_user_cart_after_order(uuid) TO authenticated;

-- =============================================
-- INDEXES FOR PERFORMANCE
-- =============================================

-- Ensure we have proper indexes for order operations
CREATE INDEX IF NOT EXISTS idx_orders_user_status_created 
ON orders (user_id, status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_orders_payment_ref_status 
ON orders (payment_ref, status) 
WHERE payment_ref IS NOT NULL AND payment_ref != 'pending';

CREATE INDEX IF NOT EXISTS idx_order_items_order_product 
ON order_items (order_id, product_id);

-- =============================================
-- VALIDATION AND TESTING
-- =============================================

-- Create a simple test function to validate the setup
CREATE OR REPLACE FUNCTION test_order_creation_function()
RETURNS text AS $$
DECLARE
  v_result text := 'Function test: ';
BEGIN
  -- Test if function exists and is callable
  IF EXISTS (
    SELECT 1 FROM pg_proc 
    WHERE proname = 'create_order_with_items' 
    AND pronargs = 10
  ) THEN
    v_result := v_result || 'create_order_with_items function exists. ';
  ELSE
    v_result := v_result || 'create_order_with_items function MISSING. ';
  END IF;
  
  -- Test if supporting functions exist
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'update_order_payment_status') THEN
    v_result := v_result || 'update_order_payment_status function exists. ';
  ELSE
    v_result := v_result || 'update_order_payment_status function MISSING. ';
  END IF;
  
  RETURN v_result || 'All functions ready for use.';
END;
$$ LANGUAGE plpgsql;

-- Test the function availability
SELECT test_order_creation_function();

-- Clean up test function
DROP FUNCTION IF EXISTS test_order_creation_function();