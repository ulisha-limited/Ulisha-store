-- Create analytics_daily_stats table
CREATE TABLE IF NOT EXISTS analytics_daily_stats (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  date date UNIQUE NOT NULL,
  unique_visitors integer DEFAULT 0,
  page_views integer DEFAULT 0,
  new_users integer DEFAULT 0,
  orders_count integer DEFAULT 0,
  revenue numeric DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create analytics_page_views table
CREATE TABLE IF NOT EXISTS analytics_page_views (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id text NOT NULL,
  user_id uuid REFERENCES auth.users(id),
  page_path text NOT NULL,
  user_agent text,
  ip_address text,
  referrer text,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE analytics_daily_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE analytics_page_views ENABLE ROW LEVEL SECURITY;

-- Create policies for admin access only
CREATE POLICY "Only admins can view daily stats"
  ON analytics_daily_stats
  FOR SELECT
  TO authenticated
  USING (
    auth.uid() IN (
      SELECT id FROM auth.users 
      WHERE email = ANY (ARRAY['paulelite606@gmail.com'::text, 'obajeufedo2@gmail.com'::text])
    )
  );

CREATE POLICY "Only admins can manage daily stats"
  ON analytics_daily_stats
  FOR ALL
  TO authenticated
  USING (
    auth.uid() IN (
      SELECT id FROM auth.users 
      WHERE email = ANY (ARRAY['paulelite606@gmail.com'::text, 'obajeufedo2@gmail.com'::text])
    )
  )
  WITH CHECK (
    auth.uid() IN (
      SELECT id FROM auth.users 
      WHERE email = ANY (ARRAY['paulelite606@gmail.com'::text, 'obajeufedo2@gmail.com'::text])
    )
  );

CREATE POLICY "Only admins can view page views"
  ON analytics_page_views
  FOR SELECT
  TO authenticated
  USING (
    auth.uid() IN (
      SELECT id FROM auth.users 
      WHERE email = ANY (ARRAY['paulelite606@gmail.com'::text, 'obajeufedo2@gmail.com'::text])
    )
  );

CREATE POLICY "Anyone can insert page views"
  ON analytics_page_views
  FOR INSERT
  TO public
  WITH CHECK (true);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_analytics_daily_stats_date ON analytics_daily_stats(date DESC);
CREATE INDEX IF NOT EXISTS idx_analytics_page_views_created_at ON analytics_page_views(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_analytics_page_views_session_id ON analytics_page_views(session_id);
CREATE INDEX IF NOT EXISTS idx_analytics_page_views_user_id ON analytics_page_views(user_id);

-- Function to update daily stats (with SECURITY DEFINER to access auth.users)
CREATE OR REPLACE FUNCTION update_daily_stats()
RETURNS void 
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  today_date date := CURRENT_DATE;
  unique_visitors_count integer;
  page_views_count integer;
  new_users_count integer;
  orders_count integer;
  revenue_total numeric;
BEGIN
  -- Calculate unique visitors (unique session_ids for today)
  SELECT COUNT(DISTINCT session_id)
  INTO unique_visitors_count
  FROM analytics_page_views
  WHERE DATE(created_at) = today_date;

  -- Calculate total page views for today
  SELECT COUNT(*)
  INTO page_views_count
  FROM analytics_page_views
  WHERE DATE(created_at) = today_date;

  -- Calculate new users registered today (using auth schema)
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
  INTO revenue_total
  FROM orders
  WHERE DATE(created_at) = today_date
  AND status = 'completed';

  -- Insert or update daily stats
  INSERT INTO analytics_daily_stats (
    date, unique_visitors, page_views, new_users, orders_count, revenue, updated_at
  )
  VALUES (
    today_date, unique_visitors_count, page_views_count, new_users_count, orders_count, revenue_total, now()
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

-- Function to track page view
CREATE OR REPLACE FUNCTION track_page_view(
  p_session_id text,
  p_user_id uuid DEFAULT NULL,
  p_page_path text DEFAULT '/',
  p_user_agent text DEFAULT '',
  p_ip_address text DEFAULT '',
  p_referrer text DEFAULT NULL
)
RETURNS void 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO analytics_page_views (
    session_id, user_id, page_path, user_agent, ip_address, referrer
  )
  VALUES (
    p_session_id, p_user_id, p_page_path, p_user_agent, p_ip_address, p_referrer
  );
END;
$$;

-- Insert initial data for the last 30 days
DO $$
DECLARE
  i integer;
  current_date_iter date;
BEGIN
  FOR i IN 0..29 LOOP
    current_date_iter := CURRENT_DATE - i;
    
    INSERT INTO analytics_daily_stats (date, unique_visitors, page_views, new_users, orders_count, revenue)
    VALUES (
      current_date_iter,
      FLOOR(RANDOM() * 100) + 10, -- Random visitors between 10-110
      FLOOR(RANDOM() * 300) + 50, -- Random page views between 50-350
      FLOOR(RANDOM() * 10) + 1,   -- Random new users between 1-11
      FLOOR(RANDOM() * 20) + 1,   -- Random orders between 1-21
      FLOOR(RANDOM() * 500000) + 10000 -- Random revenue between 10k-510k
    )
    ON CONFLICT (date) DO NOTHING;
  END LOOP;
END $$;