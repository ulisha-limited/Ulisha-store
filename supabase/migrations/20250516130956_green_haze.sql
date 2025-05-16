/*
  # Add product variants support

  1. New Tables
    - `product_variants`
      - `id` (uuid, primary key)
      - `product_id` (uuid, references products)
      - `color` (text)
      - `size` (text)
      - `stock` (integer)
      - `created_at` (timestamp)
  
  2. Security
    - Enable RLS
    - Add policies for admin access and public viewing
*/

-- Drop existing policies if they exist
DO $$
BEGIN
  DROP POLICY IF EXISTS "Anyone can view product variants" ON product_variants;
  DROP POLICY IF EXISTS "Only admins can manage product variants" ON product_variants;
EXCEPTION
  WHEN undefined_table THEN
    NULL;
END $$;

-- Create product_variants table if it doesn't exist
CREATE TABLE IF NOT EXISTS product_variants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id uuid REFERENCES products(id) ON DELETE CASCADE,
  color text NOT NULL,
  size text NOT NULL,
  stock integer NOT NULL DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  UNIQUE(product_id, color, size)
);

-- Enable RLS
ALTER TABLE product_variants ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Anyone can view product variants"
  ON product_variants
  FOR SELECT
  TO public
  USING (true);

CREATE POLICY "Only admins can manage product variants"
  ON product_variants
  FOR ALL
  TO authenticated
  USING (auth.email() IN ('paulelite606@gmail.com', 'obajeufedo2@gmail.com'))
  WITH CHECK (auth.email() IN ('paulelite606@gmail.com', 'obajeufedo2@gmail.com'));

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_product_variants_product_id ON product_variants(product_id);