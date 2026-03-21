-- Create tables for available interests and tags
-- Run this in your Supabase SQL Editor

-- Available Interests table
CREATE TABLE IF NOT EXISTS public.available_interests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Available Tags table
CREATE TABLE IF NOT EXISTS public.available_tags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert default interests
INSERT INTO public.available_interests (name) VALUES
  ('Sport'),
  ('Coffee'),
  ('Photography'),
  ('Travel'),
  ('Music'),
  ('Art'),
  ('Reading'),
  ('Cooking'),
  ('Gaming'),
  ('Fitness'),
  ('Movies'),
  ('Dancing'),
  ('Hiking'),
  ('Yoga'),
  ('Technology')
ON CONFLICT (name) DO NOTHING;

-- Insert default tags
INSERT INTO public.available_tags (name) VALUES
  ('Adventure'),
  ('Foodie'),
  ('Nightlife'),
  ('Culture'),
  ('Nature'),
  ('Beach'),
  ('Mountains'),
  ('City'),
  ('Budget'),
  ('Luxury'),
  ('Backpacking'),
  ('Road Trip'),
  ('Solo Travel'),
  ('Group Travel'),
  ('Family Friendly'),
  ('Romantic'),
  ('Party'),
  ('Relaxation'),
  ('Wellness'),
  ('Spiritual')
ON CONFLICT (name) DO NOTHING;

-- Enable Row Level Security
ALTER TABLE public.available_interests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.available_tags ENABLE ROW LEVEL SECURITY;

-- Allow public read access (anyone can see available interests/tags)
CREATE POLICY "Public read access for interests"
ON public.available_interests
FOR SELECT
TO public
USING (true);

CREATE POLICY "Public read access for tags"
ON public.available_tags
FOR SELECT
TO public
USING (true);

-- Optional: Allow authenticated users to suggest new interests/tags
-- (You can review and approve them manually in Supabase dashboard)
CREATE POLICY "Authenticated users can suggest interests"
ON public.available_interests
FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY "Authenticated users can suggest tags"
ON public.available_tags
FOR INSERT
TO authenticated
WITH CHECK (true);
