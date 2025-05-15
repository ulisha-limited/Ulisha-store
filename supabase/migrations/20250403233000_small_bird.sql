/*
  # Fix storage permissions for product uploads

  1. Changes
    - Update storage policies to allow both admins to upload images
    - Add proper bucket configuration
    
  2. Security
    - Maintain public read access
    - Restrict write access to admins only
*/

-- Ensure product-images bucket exists
INSERT INTO storage.buckets (id, name, public)
VALUES ('product-images', 'product-images', true)
ON CONFLICT (id) DO NOTHING;

-- Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Anyone can view product images" ON storage.objects;
DROP POLICY IF EXISTS "Only admins can upload product images" ON storage.objects;

-- Create policy for public viewing of product images
CREATE POLICY "Anyone can view product images"
  ON storage.objects
  FOR SELECT
  TO public
  USING (bucket_id = 'product-images');

-- Create policy for admin uploads
CREATE POLICY "Only admins can upload product images"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'product-images' AND
    auth.email() IN ('paulelite606@gmail.com', 'obajeufedo2@gmail.com')
  );

-- Create policy for admin updates
CREATE POLICY "Only admins can update product images"
  ON storage.objects
  FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'product-images' AND
    auth.email() IN ('paulelite606@gmail.com', 'obajeufedo2@gmail.com')
  )
  WITH CHECK (
    bucket_id = 'product-images' AND
    auth.email() IN ('paulelite606@gmail.com', 'obajeufedo2@gmail.com')
  );

-- Create policy for admin deletions
CREATE POLICY "Only admins can delete product images"
  ON storage.objects
  FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'product-images' AND
    auth.email() IN ('paulelite606@gmail.com', 'obajeufedo2@gmail.com')
  );