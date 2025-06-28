/*
  # Fix analytics permissions and create update_daily_stats function

  1. New Functions
    - `update_daily_stats()` - Updates daily analytics statistics with proper permissions
    
  2. Security
    - Function runs with SECURITY DEFINER to access auth.users table
    - Grant EXECUTE permission to authenticated users
    
  3. Changes
    - Creates the missing RPC function that the admin dashboard calls
    - Ensures proper access to auth.users table for analytics calculations
*/

-- Create or replace the update_daily_stats function with proper security
CREATE OR REPLACE FUNCTION public.update_daily_stats()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  today_date date := CURRENT_DATE;
  unique_visitors_count integer := 0;
  page_views_count integer := 0;
  new_users_count integer := 0;
  orders_count integer := 0;
  revenue_amount numeric := 0;
BEGIN
  -- Calculate unique visitors for today
  SELECT COUNT(DISTINCT session_id)
  INTO unique_visitors_count
  FROM analytics_page_views
  WHERE DATE(created_at) = today_date;

  -- Calculate total page views for today
  SELECT COUNT(*)
  INTO page_views_count
  FROM analytics_page_views
  WHERE DATE(created_at) = today_date;

  -- Calculate new users for today (users who signed up today)
  SELECT COUNT(*)
  INTO new_users_count
  FROM auth.users
  WHERE DATE(created_at) = today_date;

  -- Calculate orders count for today
  SELECT COUNT(*)
  INTO orders_count
  FROM orders
  WHERE DATE(created_at) = today_date;

  -- Calculate revenue for today
  SELECT COALESCE(SUM(total), 0)
  INTO revenue_amount
  FROM orders
  WHERE DATE(created_at) = today_date
    AND status != 'cancelled';

  -- Insert or update the daily stats
  INSERT INTO analytics_daily_stats (
    date,
    unique_visitors,
    page_views,
    new_users,
    orders_count,
    revenue
  )
  VALUES (
    today_date,
    unique_visitors_count,
    page_views_count,
    new_users_count,
    orders_count,
    revenue_amount
  )
  ON CONFLICT (date)
  DO UPDATE SET
    unique_visitors = EXCLUDED.unique_visitors,
    page_views = EXCLUDED.page_views,
    new_users = EXCLUDED.new_users,
    orders_count = EXCLUDED.orders_count,
    revenue = EXCLUDED.revenue,
    updated_at = now();
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.update_daily_stats() TO authenticated;

-- Also grant to anon role in case it's needed
GRANT EXECUTE ON FUNCTION public.update_daily_stats() TO anon;