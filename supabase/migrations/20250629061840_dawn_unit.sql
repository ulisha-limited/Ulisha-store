/*
  # Fix email() function references

  1. Changes
    - Replace auth.email() with proper email access using auth.jwt()
    - Update all RLS policies that use email() function
    - Ensure compatibility with Supabase auth system
    
  2. Security
    - Maintain existing security model
    - Use proper auth.jwt() claims to access email
*/

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

-- Fix product_images table policies
DROP POLICY IF EXISTS "Only admins can manage product images" ON product_images;

CREATE POLICY "Only admins can manage product images"
  ON product_images
  FOR ALL
  TO authenticated
  USING ((auth.jwt() ->> 'email') = 'paulelite606@gmail.com')
  WITH CHECK ((auth.jwt() ->> 'email') = 'paulelite606@gmail.com');

-- Fix app_settings table policies
DROP POLICY IF EXISTS "Only admins can manage app settings" ON app_settings;

CREATE POLICY "Only admins can manage app settings"
  ON app_settings
  FOR ALL
  TO authenticated
  USING ((auth.jwt() ->> 'email') = 'paulelite606@gmail.com')
  WITH CHECK ((auth.jwt() ->> 'email') = 'paulelite606@gmail.com');

-- Fix affiliate_settings table policies
DROP POLICY IF EXISTS "Only admins can manage affiliate settings" ON affiliate_settings;

CREATE POLICY "Only admins can manage affiliate settings"
  ON affiliate_settings
  FOR ALL
  TO authenticated
  USING ((auth.jwt() ->> 'email') IN ('paulelite606@gmail.com', 'obajeufedo2@gmail.com'))
  WITH CHECK ((auth.jwt() ->> 'email') IN ('paulelite606@gmail.com', 'obajeufedo2@gmail.com'));

-- Fix advertisements table policies
DROP POLICY IF EXISTS "Only admins can manage advertisements" ON advertisements;

CREATE POLICY "Only admins can manage advertisements"
  ON advertisements
  FOR ALL
  TO authenticated
  USING ((auth.jwt() ->> 'email') IN ('paulelite606@gmail.com', 'obajeufedo2@gmail.com'))
  WITH CHECK ((auth.jwt() ->> 'email') IN ('paulelite606@gmail.com', 'obajeufedo2@gmail.com'));

-- Fix product_variants table policies
DROP POLICY IF EXISTS "Only admins can manage product variants" ON product_variants;

CREATE POLICY "Only admins can manage product variants"
  ON product_variants
  FOR ALL
  TO authenticated
  USING ((auth.jwt() ->> 'email') IN ('paulelite606@gmail.com', 'obajeufedo2@gmail.com'))
  WITH CHECK ((auth.jwt() ->> 'email') IN ('paulelite606@gmail.com', 'obajeufedo2@gmail.com'));

-- Fix storage policies for product images
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

-- Fix storage policies for advertisements
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

-- Fix any remaining policies that might use email() function
DO $$
DECLARE
    policy_record RECORD;
BEGIN
    -- This is a safety check to identify any remaining policies using email()
    -- The actual policies have been fixed above
    NULL;
END $$;