/*
  # Fix policy conflicts for product_variants table

  1. Changes
    - Drop existing policies that might conflict
    - Recreate policies with proper syntax
    - Ensure no duplicate policies exist
    
  2. Security
    - Maintain existing security model
    - Use correct Supabase auth syntax
*/

-- Drop all existing policies for product_variants to avoid conflicts
DO $$
BEGIN
  DROP POLICY IF EXISTS "Anyone can view product variants" ON product_variants;
  DROP POLICY IF EXISTS "Only admins can manage product variants" ON product_variants;
EXCEPTION
  WHEN undefined_table THEN
    NULL; -- Table doesn't exist, ignore
  WHEN undefined_object THEN
    NULL; -- Policy doesn't exist, ignore
END $$;

-- Ensure the table exists and RLS is enabled
DO $$
BEGIN
  -- Enable RLS if table exists
  IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'product_variants') THEN
    ALTER TABLE product_variants ENABLE ROW LEVEL SECURITY;
  END IF;
END $$;

-- Create policies only if table exists
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'product_variants') THEN
    -- Create policy for public viewing
    CREATE POLICY "Anyone can view product variants"
      ON product_variants
      FOR SELECT
      TO public
      USING (true);

    -- Create policy for admin management
    CREATE POLICY "Only admins can manage product variants"
      ON product_variants
      FOR ALL
      TO authenticated
      USING ((auth.jwt() ->> 'email') IN ('paulelite606@gmail.com', 'obajeufedo2@gmail.com'))
      WITH CHECK ((auth.jwt() ->> 'email') IN ('paulelite606@gmail.com', 'obajeufedo2@gmail.com'));
  END IF;
END $$;

-- Also fix any remaining email() function issues in other tables
DO $$
BEGIN
  -- Fix delivery_fees policies if table exists
  IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'delivery_fees') THEN
    DROP POLICY IF EXISTS "Only admins can manage delivery fees" ON delivery_fees;
    
    CREATE POLICY "Only admins can manage delivery fees"
      ON delivery_fees
      FOR ALL
      TO authenticated
      USING ((auth.jwt() ->> 'email') IN ('paulelite606@gmail.com', 'obajeufedo2@gmail.com'))
      WITH CHECK ((auth.jwt() ->> 'email') IN ('paulelite606@gmail.com', 'obajeufedo2@gmail.com'));
  END IF;

  -- Fix product_variations policies if table exists
  IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'product_variations') THEN
    DROP POLICY IF EXISTS "Only admins can manage product variations" ON product_variations;
    
    CREATE POLICY "Only admins can manage product variations"
      ON product_variations
      FOR ALL
      TO authenticated
      USING ((auth.jwt() ->> 'email') IN ('paulelite606@gmail.com', 'obajeufedo2@gmail.com'))
      WITH CHECK ((auth.jwt() ->> 'email') IN ('paulelite606@gmail.com', 'obajeufedo2@gmail.com'));
  END IF;
END $$;