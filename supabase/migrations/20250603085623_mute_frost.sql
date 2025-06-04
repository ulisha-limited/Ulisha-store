/*
  # Product Variations and Delivery Fees Update

  1. New Tables
    - `delivery_fees`: Store state-specific delivery fees
    - `product_variations`: Store product variations configuration
    
  2. Functions
    - `auto_add_variations`: Automatically add variations based on product category
    - `validate_minimum_quantity`: Enforce minimum order quantities
    
  3. Triggers
    - Add triggers to automatically handle variations for new products
*/

-- Create delivery fees table
CREATE TABLE IF NOT EXISTS delivery_fees (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  state text NOT NULL UNIQUE,
  fee numeric NOT NULL DEFAULT 4000,
  created_at timestamptz DEFAULT now()
);

-- Insert default delivery fees
INSERT INTO delivery_fees (state, fee) VALUES
  ('Anambra', 2000),
  ('Delta', 2000),
  ('Enugu', 2000);

-- Create product variations configuration
CREATE TABLE IF NOT EXISTS product_variations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  category text NOT NULL UNIQUE,
  variations jsonb NOT NULL,
  min_order_quantity integer NOT NULL DEFAULT 2,
  created_at timestamptz DEFAULT now()
);

-- Insert default variation configurations
INSERT INTO product_variations (category, variations, min_order_quantity) VALUES
  ('Clothes', '{"size": ["S", "M", "L", "XL"], "color": ["Black", "White", "Blue", "Red", "Green"]}', 1),
  ('Shoes', '{"size": ["38", "39", "40", "41", "42", "43", "44", "45"], "color": ["Black", "White", "Brown"]}', 2),
  ('Gym Wear', '{"size": ["S", "M", "L", "XL"], "color": ["Black", "Gray", "Blue", "Red"]}', 2),
  ('Phones', '{"color": ["Black", "Silver", "Gold"], "memory": ["64GB", "128GB", "256GB"]}', 2),
  ('Jewelries', '{"size": ["Small", "Medium", "Large"], "color": ["Gold", "Silver", "Rose Gold"]}', 1);

-- Function to automatically add variations
CREATE OR REPLACE FUNCTION auto_add_variations()
RETURNS TRIGGER AS $$
BEGIN
  -- Get variations for the product category
  IF EXISTS (
    SELECT 1 FROM product_variations 
    WHERE category = NEW.category
  ) THEN
    -- Add default variations
    INSERT INTO product_variants (
      product_id,
      variations
    )
    SELECT 
      NEW.id,
      variations
    FROM product_variations
    WHERE category = NEW.category;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-add variations for new products
CREATE TRIGGER auto_add_variations_trigger
AFTER INSERT ON products
FOR EACH ROW
EXECUTE FUNCTION auto_add_variations();

-- Function to validate minimum quantity
CREATE OR REPLACE FUNCTION validate_minimum_quantity()
RETURNS TRIGGER AS $$
DECLARE
  min_qty integer;
  product_category text;
BEGIN
  -- Get product category and minimum quantity
  SELECT 
    p.category,
    COALESCE(pv.min_order_quantity, 2)
  INTO 
    product_category,
    min_qty
  FROM products p
  LEFT JOIN product_variations pv ON p.category = pv.category
  WHERE p.id = NEW.product_id;
  
  -- Check if quantity meets minimum requirement
  IF NEW.quantity < min_qty THEN
    RAISE EXCEPTION 'Minimum order quantity for % is %', product_category, min_qty;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add trigger for cart items
CREATE TRIGGER validate_minimum_quantity_trigger
BEFORE INSERT OR UPDATE ON cart_items_new
FOR EACH ROW
EXECUTE FUNCTION validate_minimum_quantity();

-- Add trigger for order items
CREATE TRIGGER validate_minimum_quantity_order_trigger
BEFORE INSERT OR UPDATE ON order_items
FOR EACH ROW
EXECUTE FUNCTION validate_minimum_quantity();

-- Enable RLS
ALTER TABLE delivery_fees ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_variations ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Public can view delivery fees"
  ON delivery_fees
  FOR SELECT
  TO public
  USING (true);

CREATE POLICY "Public can view product variations"
  ON product_variations
  FOR SELECT
  TO public
  USING (true);

CREATE POLICY "Only admins can manage delivery fees"
  ON delivery_fees
  USING (email() = ANY(ARRAY['paulelite606@gmail.com', 'obajeufedo2@gmail.com']))
  WITH CHECK (email() = ANY(ARRAY['paulelite606@gmail.com', 'obajeufedo2@gmail.com']));

CREATE POLICY "Only admins can manage product variations"
  ON product_variations
  USING (email() = ANY(ARRAY['paulelite606@gmail.com', 'obajeufedo2@gmail.com']))
  WITH CHECK (email() = ANY(ARRAY['paulelite606@gmail.com', 'obajeufedo2@gmail.com']));