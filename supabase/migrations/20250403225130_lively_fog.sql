/*
  # Fix affiliate referrals relationship with auth.users

  1. Changes
    - Add proper foreign key relationship between affiliate_referrals and auth.users
    - Update existing queries to use the correct relationship
    
  2. Security
    - Maintain existing RLS policies
*/

-- Drop existing foreign key if it exists
ALTER TABLE affiliate_referrals
DROP CONSTRAINT IF EXISTS affiliate_referrals_referred_user_id_fkey;

-- Add new foreign key relationship to auth.users
ALTER TABLE affiliate_referrals
ADD CONSTRAINT affiliate_referrals_referred_user_id_fkey
FOREIGN KEY (referred_user_id)
REFERENCES auth.users(id)
ON DELETE CASCADE;

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_affiliate_referrals_referred_user_id 
ON affiliate_referrals(referred_user_id);

-- Update RLS policies to handle the relationship
DROP POLICY IF EXISTS "Users can view their referrals" ON affiliate_referrals;
CREATE POLICY "Users can view their referrals"
  ON affiliate_referrals
  FOR SELECT
  TO authenticated
  USING (
    referrer_id IN (
      SELECT id FROM affiliate_accounts WHERE user_id = auth.uid()
    )
  );