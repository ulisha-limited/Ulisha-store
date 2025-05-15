-- Add delivery_type to order_items table
ALTER TABLE order_items
ADD COLUMN IF NOT EXISTS delivery_type text DEFAULT 'standard';

-- Add constraint to validate delivery type
ALTER TABLE order_items
ADD CONSTRAINT check_delivery_type
CHECK (delivery_type IN ('standard', 'express'));

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_order_items_delivery_type ON order_items(delivery_type);