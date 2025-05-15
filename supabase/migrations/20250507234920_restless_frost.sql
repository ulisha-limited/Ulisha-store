-- Drop existing policies if they exist
DO $$ 
BEGIN
  DROP POLICY IF EXISTS "Users can view their own data" ON users;
  DROP POLICY IF EXISTS "Users can update their own data" ON users;
EXCEPTION
  WHEN undefined_table THEN NULL;
END $$;

-- Create users table if it doesn't exist
CREATE TABLE IF NOT EXISTS users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  firebase_uid text UNIQUE NOT NULL,
  email text UNIQUE NOT NULL,
  full_name text,
  avatar_url text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view their own data"
  ON users
  FOR SELECT
  TO public
  USING (true);

CREATE POLICY "Users can update their own data"
  ON users
  FOR UPDATE
  TO authenticated
  USING (firebase_uid = current_setting('request.jwt.claims')::json->>'sub')
  WITH CHECK (firebase_uid = current_setting('request.jwt.claims')::json->>'sub');

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_users_firebase_uid ON users(firebase_uid);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger for updated_at
DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();