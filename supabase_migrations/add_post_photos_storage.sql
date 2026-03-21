-- Create storage bucket for post photos
INSERT INTO storage.buckets (id, name, public)
VALUES ('post-photos', 'post-photos', true)
ON CONFLICT (id) DO NOTHING;

-- Policy: Allow authenticated users to upload their own photos
CREATE POLICY "Users can upload their own post photos"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'post-photos' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy: Allow anyone to view photos (public bucket)
CREATE POLICY "Anyone can view post photos"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'post-photos');

-- Policy: Allow users to update their own photos
CREATE POLICY "Users can update their own post photos"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'post-photos' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy: Allow users to delete their own photos
CREATE POLICY "Users can delete their own post photos"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'post-photos' AND
  (storage.foldername(name))[1] = auth.uid()::text
);
