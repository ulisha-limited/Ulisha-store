/*
  # Add referral count to affiliate accounts

  1. Changes
    - Add referral_count column to affiliate_accounts table
    - Create function to update referral count
    - Add trigger to maintain referral count
    
  2. Security
    - Maintains existing RLS policies
*/

-- Add referral_count column to affiliate_accounts
ALTER TABLE affiliate_accounts
ADD COLUMN IF NOT EXISTS referral_count integer DEFAULT 0;

-- Create function to update referral count
CREATE OR REPLACE FUNCTION update_affiliate_referral_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    -- Increment referral count
    UPDATE affiliate_accounts
    SET referral_count = referral_count + 1
    WHERE id = NEW.referrer_id;
  ELSIF TG_OP = 'DELETE' THEN
    -- Decrement referral count
    UPDATE affiliate_accounts
    SET referral_count = GREATEST(0, referral_count - 1)
    WHERE id = OLD.referrer_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to maintain referral count
DROP TRIGGER IF EXISTS update_referral_count_trigger ON affiliate_referrals;
CREATE TRIGGER update_referral_count_trigger
AFTER INSERT OR DELETE ON affiliate_referrals
FOR EACH ROW
EXECUTE FUNCTION update_affiliate_referral_count();

-- Update existing referral counts
UPDATE affiliate_accounts aa
SET referral_count = (
  SELECT COUNT(*)
  FROM affiliate_referrals ar
  WHERE ar.referrer_id = aa.id
  AND ar.status = 'active'
);