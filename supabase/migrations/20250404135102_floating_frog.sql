-- Create storage bucket for advertisements if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('advertisements', 'advertisements', true)
ON CONFLICT (id) DO NOTHING;

-- Create storage policies for advertisements
CREATE POLICY "Anyone can view advertisement images"
  ON storage.objects
  FOR SELECT
  TO public
  USING (bucket_id = 'advertisements');

CREATE POLICY "Only admins can upload advertisement images"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'advertisements' AND
    auth.email() IN ('paulelite606@gmail.com', 'obajeufedo2@gmail.com')
  );

CREATE POLICY "Only admins can update advertisement images"
  ON storage.objects
  FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'advertisements' AND
    auth.email() IN ('paulelite606@gmail.com', 'obajeufedo2@gmail.com')
  )
  WITH CHECK (
    bucket_id = 'advertisements' AND
    auth.email() IN ('paulelite606@gmail.com', 'obajeufedo2@gmail.com')
  );

CREATE POLICY "Only admins can delete advertisement images"
  ON storage.objects
  FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'advertisements' AND
    auth.email() IN ('paulelite606@gmail.com', 'obajeufedo2@gmail.com')
  );