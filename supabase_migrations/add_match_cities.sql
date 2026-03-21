-- Add matched_city tracking for re-matching in different cities
-- This allows the same user pair to match multiple times in different cities

-- Create match_cities table to track each city match
CREATE TABLE IF NOT EXISTS public.match_cities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id UUID NOT NULL REFERENCES public.matches(id) ON DELETE CASCADE,
  city TEXT NOT NULL,
  matched_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,

  -- Prevent duplicate city matches for the same match
  UNIQUE(match_id, city)
);

-- Create index for better query performance
CREATE INDEX IF NOT EXISTS idx_match_cities_match_id ON public.match_cities(match_id);
CREATE INDEX IF NOT EXISTS idx_match_cities_city ON public.match_cities(city);

-- Enable RLS
ALTER TABLE public.match_cities ENABLE ROW LEVEL SECURITY;

-- Users can view match cities for their matches
CREATE POLICY "Users can view own match cities"
  ON public.match_cities
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.matches
      WHERE matches.id = match_cities.match_id
      AND (matches.user1_id = auth.uid() OR matches.user2_id = auth.uid())
    )
  );

-- Users can insert match cities for their matches
CREATE POLICY "Users can insert own match cities"
  ON public.match_cities
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.matches
      WHERE matches.id = match_cities.match_id
      AND (matches.user1_id = auth.uid() OR matches.user2_id = auth.uid())
    )
  );

-- Add message_type column to messages table to support system messages
ALTER TABLE public.messages
ADD COLUMN IF NOT EXISTS message_type TEXT DEFAULT 'text' CHECK (message_type IN ('text', 'shared_post', 'match_notification', 'city_divider'));

-- Add city column to messages table for city dividers
ALTER TABLE public.messages
ADD COLUMN IF NOT EXISTS city TEXT;
