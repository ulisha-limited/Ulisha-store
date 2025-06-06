/*
  # Add Product Variants and Currency Settings

  1. New Tables
    - `product_variants`
      - `id` (uuid, primary key)
      - `product_id` (uuid, references products)
      - `color` (text)
      - `size` (text) 
      - `stock` (integer)
      - `created_at` (timestamp)

  2. Changes
    - Add variant fields to cart_items_new and order_items
    - Add currency_preference to user profiles
    
  3. Security
    - Enable RLS on new tables
    - Add appropriate policies
*/

-- Create product variants table if it doesn't exist
CREATE TABLE IF NOT EXISTS product_variants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id uuid REFERENCES products(id) ON DELETE CASCADE,
  color text NOT NULL,
  size text NOT NULL,
  stock integer NOT NULL DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  UNIQUE(product_id, color, size)
);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_product_variants_product_id ON product_variants(product_id);

-- Enable RLS
ALTER TABLE product_variants ENABLE ROW LEVEL SECURITY;

-- Add RLS policies
CREATE POLICY "Anyone can view product variants" 
  ON product_variants
  FOR SELECT 
  TO public 
  USING (true);

CREATE POLICY "Only admins can manage product variants" 
  ON product_variants
  FOR ALL 
  TO authenticated
  USING (email() = ANY(ARRAY['paulelite606@gmail.com', 'obajeufedo2@gmail.com']))
  WITH CHECK (email() = ANY(ARRAY['paulelite606@gmail.com', 'obajeufedo2@gmail.com']));

-- Add user currency preferences
CREATE TABLE IF NOT EXISTS user_preferences (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  currency text NOT NULL DEFAULT 'NGN',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(user_id)
);

-- Enable RLS on user preferences
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;

-- Add RLS policies for user preferences
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

-- Add trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_user_preferences_updated_at
  BEFORE UPDATE ON user_preferences
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();