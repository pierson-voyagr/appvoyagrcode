-- First, drop any existing policies on storage.objects for post-photos bucket
DROP POLICY IF EXISTS "Users can upload their own post photos" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can view post photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own post photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own post photos" ON storage.objects;

-- Make sure bucket exists and is public
INSERT INTO storage.buckets (id, name, public)
VALUES ('post-photos', 'post-photos', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- Policy 1: Allow authenticated users to upload photos
CREATE POLICY "Users can upload their own post photos"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'post-photos'
);

-- Policy 2: Allow anyone to view photos (public bucket)
CREATE POLICY "Anyone can view post photos"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'post-photos');

-- Policy 3: Allow users to update their own photos
CREATE POLICY "Users can update their own post photos"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'post-photos' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy 4: Allow users to delete their own photos
CREATE POLICY "Users can delete their own post photos"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'post-photos' AND
  (storage.foldername(name))[1] = auth.uid()::text
);
