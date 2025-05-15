/*
  # Fix ambiguous commission_rate reference

  1. Changes
    - Update calculate_affiliate_commission() function to explicitly reference affiliate_settings.commission_rate
    - Ensures unambiguous column references in the trigger function
    
  2. Security
    - No changes to security policies
    - Maintains existing RLS settings
*/

CREATE OR REPLACE FUNCTION calculate_affiliate_commission()
RETURNS TRIGGER AS $$
DECLARE
    referrer_id uuid;
    commission numeric;
BEGIN
    -- Get the referrer's affiliate account ID for the order's user
    SELECT ar.referrer_id INTO referrer_id
    FROM affiliate_referrals ar
    WHERE ar.referred_user_id = NEW.user_id
    AND ar.status = 'active'
    LIMIT 1;

    -- If there's a referrer, calculate and record commission
    IF referrer_id IS NOT NULL THEN
        -- Calculate commission using the current commission rate
        SELECT (NEW.total * affiliate_settings.commission_rate / 100) INTO commission
        FROM affiliate_settings
        LIMIT 1;

        -- Insert the commission record
        INSERT INTO affiliate_commissions (
            affiliate_id,
            order_id,
            amount,
            status
        ) VALUES (
            referrer_id,
            NEW.id,
            commission,
            'pending'
        );

        -- Update the affiliate's total earnings
        UPDATE affiliate_accounts
        SET earnings = earnings + commission
        WHERE id = referrer_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;