-- Add store_url column to stores table
ALTER TABLE stores 
ADD COLUMN IF NOT EXISTS store_url text;

-- Create unique index on store_url
CREATE UNIQUE INDEX IF NOT EXISTS idx_stores_url 
ON stores(store_url);

-- Add constraint to ensure store_url is unique
ALTER TABLE stores
ADD CONSTRAINT unique_store_url UNIQUE USING INDEX idx_stores_url;

-- Update existing stores with default URLs
UPDATE stores
SET store_url = 'https://ulishastore.com/store/' || 
  LOWER(REGEXP_REPLACE(name, '[^a-zA-Z0-9]+', '-', 'g'))
WHERE store_url IS NULL;

-- Make store_url required for new stores
ALTER TABLE stores
ALTER COLUMN store_url SET NOT NULL;