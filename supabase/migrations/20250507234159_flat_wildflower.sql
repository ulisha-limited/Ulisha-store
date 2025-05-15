/*
  # Add users table with Firebase integration

  1. New Tables
    - `users`
      - `id` (uuid, primary key)
      - `firebase_uid` (text, unique)
      - `email` (text, unique)
      - `full_name` (text)
      - `avatar_url` (text)
      - `created_at` (timestamp)
      - `updated_at` (timestamp)
  
  2. Security
    - Enable RLS
    - Add policies for user data access
*/

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
  TO authenticated
  USING (firebase_uid = current_setting('request.jwt.claims')::json->>'sub');

CREATE POLICY "Users can update their own data"
  ON users
  FOR UPDATE
  TO authenticated
  USING (firebase_uid = current_setting('request.jwt.claims')::json->>'sub')
  WITH CHECK (firebase_uid = current_setting('request.jwt.claims')::json->>'sub');

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_users_firebase_uid ON users(firebase_uid);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);