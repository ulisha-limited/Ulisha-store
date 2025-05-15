/*
  # Add Affiliate System

  1. New Tables
    - `affiliate_settings`
      - `id` (uuid, primary key)
      - `commission_rate` (numeric, percentage)
      - `min_payout` (numeric)
      - `created_at` (timestamp)
      - `updated_at` (timestamp)
    
    - `affiliate_accounts`
      - `id` (uuid, primary key)
      - `user_id` (uuid, references auth.users)
      - `referral_code` (text, unique)
      - `earnings` (numeric)
      - `paid_earnings` (numeric)
      - `status` (text)
      - `payment_details` (jsonb)
      - `created_at` (timestamp)
      - `updated_at` (timestamp)
    
    - `affiliate_referrals`
      - `id` (uuid, primary key)
      - `referrer_id` (uuid, references affiliate_accounts)
      - `referred_user_id` (uuid, references auth.users)
      - `status` (text)
      - `created_at` (timestamp)
    
    - `affiliate_commissions`
      - `id` (uuid, primary key)
      - `affiliate_id` (uuid, references affiliate_accounts)
      - `order_id` (uuid, references orders)
      - `amount` (numeric)
      - `status` (text)
      - `created_at` (timestamp)

  2. Changes
    - Add referral_code column to users table
    - Add referred_by column to users table
    
  3. Security
    - Enable RLS
    - Add appropriate policies
*/

-- Create affiliate_settings table
CREATE TABLE affiliate_settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  commission_rate numeric NOT NULL DEFAULT 10.0,
  min_payout numeric NOT NULL DEFAULT 5000.0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create affiliate_accounts table
CREATE TABLE affiliate_accounts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users NOT NULL,
  referral_code text UNIQUE NOT NULL,
  earnings numeric DEFAULT 0,
  paid_earnings numeric DEFAULT 0,
  status text DEFAULT 'pending',
  payment_details jsonb DEFAULT '{}',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(user_id)
);

-- Create affiliate_referrals table
CREATE TABLE affiliate_referrals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  referrer_id uuid REFERENCES affiliate_accounts NOT NULL,
  referred_user_id uuid REFERENCES auth.users NOT NULL,
  status text DEFAULT 'active',
  created_at timestamptz DEFAULT now(),
  UNIQUE(referred_user_id)
);

-- Create affiliate_commissions table
CREATE TABLE affiliate_commissions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  affiliate_id uuid REFERENCES affiliate_accounts NOT NULL,
  order_id uuid REFERENCES orders NOT NULL,
  amount numeric NOT NULL,
  status text DEFAULT 'pending',
  created_at timestamptz DEFAULT now()
);

-- Add referral tracking to users
ALTER TABLE auth.users 
ADD COLUMN IF NOT EXISTS referral_code text,
ADD COLUMN IF NOT EXISTS referred_by uuid REFERENCES affiliate_accounts(id);

-- Enable RLS
ALTER TABLE affiliate_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE affiliate_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE affiliate_referrals ENABLE ROW LEVEL SECURITY;
ALTER TABLE affiliate_commissions ENABLE ROW LEVEL SECURITY;

-- Create policies for affiliate_settings
CREATE POLICY "Anyone can view affiliate settings"
  ON affiliate_settings
  FOR SELECT
  TO public
  USING (true);

CREATE POLICY "Only admins can manage affiliate settings"
  ON affiliate_settings
  FOR ALL
  TO authenticated
  USING (auth.email() IN ('paulelite606@gmail.com', 'obajeufedo2@gmail.com'))
  WITH CHECK (auth.email() IN ('paulelite606@gmail.com', 'obajeufedo2@gmail.com'));

-- Create policies for affiliate_accounts
CREATE POLICY "Users can view their own affiliate account"
  ON affiliate_accounts
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own affiliate account"
  ON affiliate_accounts
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own affiliate account"
  ON affiliate_accounts
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Create policies for affiliate_referrals
CREATE POLICY "Users can view their referrals"
  ON affiliate_referrals
  FOR SELECT
  TO authenticated
  USING (
    referrer_id IN (
      SELECT id FROM affiliate_accounts WHERE user_id = auth.uid()
    )
  );

-- Create policies for affiliate_commissions
CREATE POLICY "Users can view their commissions"
  ON affiliate_commissions
  FOR SELECT
  TO authenticated
  USING (
    affiliate_id IN (
      SELECT id FROM affiliate_accounts WHERE user_id = auth.uid()
    )
  );

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_affiliate_accounts_user_id ON affiliate_accounts(user_id);
CREATE INDEX IF NOT EXISTS idx_affiliate_accounts_referral_code ON affiliate_accounts(referral_code);
CREATE INDEX IF NOT EXISTS idx_affiliate_referrals_referrer_id ON affiliate_referrals(referrer_id);
CREATE INDEX IF NOT EXISTS idx_affiliate_commissions_affiliate_id ON affiliate_commissions(affiliate_id);

-- Insert default affiliate settings
INSERT INTO affiliate_settings (commission_rate, min_payout)
VALUES (10.0, 5000.0)
ON CONFLICT DO NOTHING;

-- Create function to generate unique referral code
CREATE OR REPLACE FUNCTION generate_unique_referral_code(user_id uuid)
RETURNS text AS $$
DECLARE
  base_code text;
  final_code text;
  counter integer := 0;
BEGIN
  -- Generate base code from user_id
  base_code := substr(replace(user_id::text, '-', ''), 1, 8);
  final_code := upper(base_code);
  
  -- Keep trying until we find a unique code
  WHILE EXISTS (
    SELECT 1 FROM affiliate_accounts WHERE referral_code = final_code
  ) LOOP
    counter := counter + 1;
    final_code := upper(base_code || counter::text);
  END LOOP;
  
  RETURN final_code;
END;
$$ LANGUAGE plpgsql;

-- Create function to calculate commission
CREATE OR REPLACE FUNCTION calculate_affiliate_commission()
RETURNS TRIGGER AS $$
DECLARE
  commission_rate numeric;
  referrer_account_id uuid;
  commission_amount numeric;
BEGIN
  -- Get commission rate from settings
  SELECT commission_rate INTO commission_rate
  FROM affiliate_settings
  LIMIT 1;

  -- Get referrer's affiliate account
  SELECT aa.id INTO referrer_account_id
  FROM affiliate_accounts aa
  JOIN auth.users u ON u.referred_by = aa.id
  WHERE u.id = NEW.user_id;

  IF referrer_account_id IS NOT NULL THEN
    -- Calculate commission
    commission_amount := (NEW.total * commission_rate) / 100;

    -- Insert commission record
    INSERT INTO affiliate_commissions (
      affiliate_id,
      order_id,
      amount,
      status
    ) VALUES (
      referrer_account_id,
      NEW.id,
      commission_amount,
      'pending'
    );

    -- Update affiliate earnings
    UPDATE affiliate_accounts
    SET earnings = earnings + commission_amount
    WHERE id = referrer_account_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for commission calculation
CREATE TRIGGER calculate_commission_trigger
AFTER INSERT ON orders
FOR EACH ROW
EXECUTE FUNCTION calculate_affiliate_commission();