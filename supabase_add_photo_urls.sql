-- Add photo_urls column to users table
-- Run this in your Supabase SQL Editor

ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS photo_urls TEXT[] DEFAULT '{}';

-- Create index for better query performance
CREATE INDEX IF NOT EXISTS idx_users_photo_urls ON public.users USING GIN(photo_urls);
