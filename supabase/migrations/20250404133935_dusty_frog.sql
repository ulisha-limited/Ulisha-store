/*
  # Add advertisements table

  1. New Tables
    - `advertisements`
      - `id` (uuid, primary key)
      - `title` (text)
      - `description` (text)
      - `image_url` (text)
      - `button_text` (text)
      - `button_link` (text)
      - `active` (boolean)
      - `created_at` (timestamp)
  
  2. Security
    - Enable RLS
    - Add policies for admin access
*/

-- Create advertisements table
CREATE TABLE IF NOT EXISTS advertisements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text NOT NULL,
  image_url text NOT NULL,
  button_text text NOT NULL,
  button_link text NOT NULL,
  active boolean DEFAULT true,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE advertisements ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Anyone can view advertisements"
  ON advertisements
  FOR SELECT
  TO public
  USING (true);

CREATE POLICY "Only admins can manage advertisements"
  ON advertisements
  FOR ALL
  TO authenticated
  USING (auth.email() IN ('paulelite606@gmail.com', 'obajeufedo2@gmail.com'))
  WITH CHECK (auth.email() IN ('paulelite606@gmail.com', 'obajeufedo2@gmail.com'));

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_advertisements_active_created 
ON advertisements(active, created_at DESC);