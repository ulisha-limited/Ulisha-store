/*
  # Fix admin permissions for products table

  1. Changes
    - Update RLS policies to allow both admins to manage products
    - Add both admin emails to the policy check
    
  2. Security
    - Maintain existing RLS policies
    - Only allow specific admin emails
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Only admins can insert products" ON products;

-- Create new policy for product management
CREATE POLICY "Only admins can insert products"
  ON products
  FOR INSERT
  TO authenticated
  WITH CHECK (
    auth.email() IN ('paulelite606@gmail.com', 'obajeufedo2@gmail.com')
  );

-- Update existing policy for all operations
CREATE POLICY "Only admins can manage products"
  ON products
  FOR ALL
  TO authenticated
  USING (
    auth.email() IN ('paulelite606@gmail.com', 'obajeufedo2@gmail.com')
  )
  WITH CHECK (
    auth.email() IN ('paulelite606@gmail.com', 'obajeufedo2@gmail.com')
  );

-- Add index for better performance
CREATE INDEX IF NOT EXISTS idx_products_created_at ON products(created_at DESC);