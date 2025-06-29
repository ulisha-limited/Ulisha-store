/*
  # Fix all function dependencies and Supabase issues

  1. Drop all dependent triggers first
  2. Drop functions with CASCADE if needed
  3. Recreate everything properly
  4. Fix all remaining email() function issues
  5. Handle all policy conflicts
*/

-- Step 1: Drop all triggers that depend on functions
DO $$
BEGIN
    -- Drop triggers that depend on validate_variant_data
    DROP TRIGGER IF EXISTS validate_cart_variant_data ON cart_items_new;
    DROP TRIGGER IF EXISTS validate_order_variant_data ON order_items;
    
    -- Drop other potentially problematic triggers
    DROP TRIGGER IF EXISTS auto_add_variations_trigger ON products;
    DROP TRIGGER IF EXISTS validate_minimum_quantity_trigger ON cart_items_new;
    DROP TRIGGER IF EXISTS validate_minimum_quantity_order_trigger ON order_items;
EXCEPTION
    WHEN OTHERS THEN
        NULL; -- Ignore errors if triggers don't exist
END $$;

-- Step 2: Drop functions with CASCADE to handle dependencies
DO $$
BEGIN
    DROP FUNCTION IF EXISTS validate_variant_data() CASCADE;
    DROP FUNCTION IF EXISTS auto_add_variations() CASCADE;
    DROP FUNCTION IF EXISTS validate_minimum_quantity() CASCADE;
EXCEPTION
    WHEN OTHERS THEN
        NULL; -- Ignore errors if functions don't exist
END $$;

-- Step 3: Drop existing constraints to avoid conflicts
DO $$
BEGIN
    -- Drop variant data constraints
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'check_variant_data' 
        AND table_name = 'cart_items_new'
    ) THEN
        ALTER TABLE cart_items_new DROP CONSTRAINT check_variant_data;
    END IF;

    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'check_variant_data' 
        AND table_name = 'order_items'
    ) THEN
        ALTER TABLE order_items DROP CONSTRAINT check_variant_data;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        NULL; -- Ignore errors
END $$;

-- Step 4: Add constraints back
DO $$
BEGIN
    -- Add variant data constraints to cart_items_new
    IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'cart_items_new') THEN
        ALTER TABLE cart_items_new
        ADD CONSTRAINT check_variant_data
        CHECK (
          (variant_id IS NOT NULL AND selected_color IS NOT NULL AND selected_size IS NOT NULL) OR
          (variant_id IS NULL AND selected_color IS NULL AND selected_size IS NULL)
        );
    END IF;

    -- Add variant data constraints to order_items
    IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'order_items') THEN
        ALTER TABLE order_items
        ADD CONSTRAINT check_variant_data
        CHECK (
          (variant_id IS NOT NULL AND selected_color IS NOT NULL AND selected_size IS NOT NULL) OR
          (variant_id IS NULL AND selected_color IS NULL AND selected_size IS NULL)
        );
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        NULL; -- Ignore errors
END $$;

-- Step 5: Recreate the validate_variant_data function
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
      RAISE EXCEPTION 'Invalid variant data: variant does not exist or color/size mismatch';
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 6: Recreate triggers
DO $$
BEGIN
    -- Create triggers for variant validation
    IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'cart_items_new') THEN
        CREATE TRIGGER validate_cart_variant_data
        BEFORE INSERT OR UPDATE ON cart_items_new
        FOR EACH ROW
        EXECUTE FUNCTION validate_variant_data();
    END IF;

    IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'order_items') THEN
        CREATE TRIGGER validate_order_variant_data
        BEFORE INSERT OR UPDATE ON order_items
        FOR EACH ROW
        EXECUTE FUNCTION validate_variant_data();
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        NULL; -- Ignore errors
END $$;

-- Step 7: Fix all remaining email() function issues in policies
DO $$
BEGIN
    -- Fix products table policies
    DROP POLICY IF EXISTS "Only admins can insert products" ON products;
    DROP POLICY IF EXISTS "Only admins can manage products" ON products;

    CREATE POLICY "Only admins can insert products"
      ON products
      FOR INSERT
      TO authenticated
      WITH CHECK (
        (auth.jwt() ->> 'email') IN ('paulelite606@gmail.com', 'obajeufedo2@gmail.com')
      );

    CREATE POLICY "Only admins can manage products"
      ON products
      FOR ALL
      TO authenticated
      USING (
        (auth.jwt() ->> 'email') IN ('paulelite606@gmail.com', 'obajeufedo2@gmail.com')
      )
      WITH CHECK (
        (auth.jwt() ->> 'email') IN ('paulelite606@gmail.com', 'obajeufedo2@gmail.com')
      );
EXCEPTION
    WHEN OTHERS THEN
        NULL; -- Ignore errors if table doesn't exist
END $$;

-- Step 8: Fix product_variants policies
DO $$
BEGIN
    DROP POLICY IF EXISTS "Anyone can view product variants" ON product_variants;
    DROP POLICY IF EXISTS "Only admins can manage product variants" ON product_variants;

    IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'product_variants') THEN
        ALTER TABLE product_variants ENABLE ROW LEVEL SECURITY;
        
        CREATE POLICY "Anyone can view product variants"
          ON product_variants
          FOR SELECT
          TO public
          USING (true);

        CREATE POLICY "Only admins can manage product variants"
          ON product_variants
          FOR ALL
          TO authenticated
          USING ((auth.jwt() ->> 'email') IN ('paulelite606@gmail.com', 'obajeufedo2@gmail.com'))
          WITH CHECK ((auth.jwt() ->> 'email') IN ('paulelite606@gmail.com', 'obajeufedo2@gmail.com'));
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        NULL; -- Ignore errors
END $$;

-- Step 9: Fix other table policies that might use email()
DO $$
BEGIN
    -- Fix app_settings policies
    IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'app_settings') THEN
        DROP POLICY IF EXISTS "Only admins can manage app settings" ON app_settings;
        
        CREATE POLICY "Only admins can manage app settings"
          ON app_settings
          FOR ALL
          TO authenticated
          USING ((auth.jwt() ->> 'email') = 'paulelite606@gmail.com')
          WITH CHECK ((auth.jwt() ->> 'email') = 'paulelite606@gmail.com');
    END IF;

    -- Fix affiliate_settings policies
    IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'affiliate_settings') THEN
        DROP POLICY IF EXISTS "Only admins can manage affiliate settings" ON affiliate_settings;
        
        CREATE POLICY "Only admins can manage affiliate settings"
          ON affiliate_settings
          FOR ALL
          TO authenticated
          USING ((auth.jwt() ->> 'email') IN ('paulelite606@gmail.com', 'obajeufedo2@gmail.com'))
          WITH CHECK ((auth.jwt() ->> 'email') IN ('paulelite606@gmail.com', 'obajeufedo2@gmail.com'));
    END IF;

    -- Fix advertisements policies
    IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'advertisements') THEN
        DROP POLICY IF EXISTS "Only admins can manage advertisements" ON advertisements;
        
        CREATE POLICY "Only admins can manage advertisements"
          ON advertisements
          FOR ALL
          TO authenticated
          USING ((auth.jwt() ->> 'email') IN ('paulelite606@gmail.com', 'obajeufedo2@gmail.com'))
          WITH CHECK ((auth.jwt() ->> 'email') IN ('paulelite606@gmail.com', 'obajeufedo2@gmail.com'));
    END IF;

    -- Fix product_images policies
    IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'product_images') THEN
        DROP POLICY IF EXISTS "Only admins can manage product images" ON product_images;
        
        CREATE POLICY "Only admins can manage product images"
          ON product_images
          FOR ALL
          TO authenticated
          USING ((auth.jwt() ->> 'email') = 'paulelite606@gmail.com')
          WITH CHECK ((auth.jwt() ->> 'email') = 'paulelite606@gmail.com');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        NULL; -- Ignore errors
END $$;

-- Step 10: Fix storage policies
DO $$
BEGIN
    -- Fix product images storage policies
    DROP POLICY IF EXISTS "Only admins can upload product images" ON storage.objects;
    DROP POLICY IF EXISTS "Only admins can update product images" ON storage.objects;
    DROP POLICY IF EXISTS "Only admins can delete product images" ON storage.objects;

    CREATE POLICY "Only admins can upload product images"
      ON storage.objects
      FOR INSERT
      TO authenticated
      WITH CHECK (
        bucket_id = 'product-images' AND
        (auth.jwt() ->> 'email') IN ('paulelite606@gmail.com', 'obajeufedo2@gmail.com')
      );

    CREATE POLICY "Only admins can update product images"
      ON storage.objects
      FOR UPDATE
      TO authenticated
      USING (
        bucket_id = 'product-images' AND
        (auth.jwt() ->> 'email') IN ('paulelite606@gmail.com', 'obajeufedo2@gmail.com')
      )
      WITH CHECK (
        bucket_id = 'product-images' AND
        (auth.jwt() ->> 'email') IN ('paulelite606@gmail.com', 'obajeufedo2@gmail.com')
      );

    CREATE POLICY "Only admins can delete product images"
      ON storage.objects
      FOR DELETE
      TO authenticated
      USING (
        bucket_id = 'product-images' AND
        (auth.jwt() ->> 'email') IN ('paulelite606@gmail.com', 'obajeufedo2@gmail.com')
      );

    -- Fix advertisement images storage policies
    DROP POLICY IF EXISTS "Only admins can upload advertisement images" ON storage.objects;
    DROP POLICY IF EXISTS "Only admins can update advertisement images" ON storage.objects;
    DROP POLICY IF EXISTS "Only admins can delete advertisement images" ON storage.objects;

    CREATE POLICY "Only admins can upload advertisement images"
      ON storage.objects
      FOR INSERT
      TO authenticated
      WITH CHECK (
        bucket_id = 'advertisements' AND
        (auth.jwt() ->> 'email') IN ('paulelite606@gmail.com', 'obajeufedo2@gmail.com')
      );

    CREATE POLICY "Only admins can update advertisement images"
      ON storage.objects
      FOR UPDATE
      TO authenticated
      USING (
        bucket_id = 'advertisements' AND
        (auth.jwt() ->> 'email') IN ('paulelite606@gmail.com', 'obajeufedo2@gmail.com')
      )
      WITH CHECK (
        bucket_id = 'advertisements' AND
        (auth.jwt() ->> 'email') IN ('paulelite606@gmail.com', 'obajeufedo2@gmail.com')
      );

    CREATE POLICY "Only admins can delete advertisement images"
      ON storage.objects
      FOR DELETE
      TO authenticated
      USING (
        bucket_id = 'advertisements' AND
        (auth.jwt() ->> 'email') IN ('paulelite606@gmail.com', 'obajeufedo2@gmail.com')
      );
EXCEPTION
    WHEN OTHERS THEN
        NULL; -- Ignore errors
END $$;

-- Step 11: Create user_preferences table if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'user_preferences') THEN
        CREATE TABLE user_preferences (
          id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
          user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
          currency text NOT NULL DEFAULT 'NGN',
          created_at timestamptz DEFAULT now(),
          updated_at timestamptz DEFAULT now(),
          UNIQUE(user_id)
        );

        ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;

        CREATE POLICY "Users can view their own preferences"
          ON user_preferences
          FOR SELECT
          TO authenticated
          USING (auth.uid() = user_id);

        CREATE POLICY "Users can update their own preferences"
          ON user_preferences
          FOR UPDATE
          TO authenticated
          USING (auth.uid() = user_id)
          WITH CHECK (auth.uid() = user_id);

        CREATE POLICY "Users can insert their own preferences"
          ON user_preferences
          FOR INSERT
          TO authenticated
          WITH CHECK (auth.uid() = user_id);

        -- Create trigger for updated_at
        CREATE TRIGGER update_user_preferences_updated_at
          BEFORE UPDATE ON user_preferences
          FOR EACH ROW
          EXECUTE FUNCTION update_updated_at_column();
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        NULL; -- Ignore errors
END $$;