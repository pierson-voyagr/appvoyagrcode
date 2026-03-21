-- Migration: Add swipes and matches tables for mutual matching system
-- Created: 2025-11-15

-- Table to track all swipes/likes
CREATE TABLE IF NOT EXISTS public.swipes (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  swiped_user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  is_like BOOLEAN NOT NULL, -- true for right swipe (like), false for left swipe (pass)
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,

  -- Prevent duplicate swipes from same user on same profile
  UNIQUE(user_id, swiped_user_id)
);

-- Table to track mutual matches
CREATE TABLE IF NOT EXISTS public.matches (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user1_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  user2_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  matched_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,

  -- Ensure user1_id is always less than user2_id to prevent duplicates
  -- This constraint ensures we only have one match record per pair
  CONSTRAINT ordered_user_ids CHECK (user1_id < user2_id),
  UNIQUE(user1_id, user2_id)
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_swipes_user_id ON public.swipes(user_id);
CREATE INDEX IF NOT EXISTS idx_swipes_swiped_user_id ON public.swipes(swiped_user_id);
CREATE INDEX IF NOT EXISTS idx_matches_user1_id ON public.matches(user1_id);
CREATE INDEX IF NOT EXISTS idx_matches_user2_id ON public.matches(user2_id);

-- Row Level Security Policies

-- Enable RLS on swipes table
ALTER TABLE public.swipes ENABLE ROW LEVEL SECURITY;

-- Users can insert their own swipes
CREATE POLICY "Users can insert own swipes"
  ON public.swipes
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- Users can view swipes they made
CREATE POLICY "Users can view own swipes"
  ON public.swipes
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- Users can view swipes made ON them (to detect mutual likes)
CREATE POLICY "Users can view swipes on them"
  ON public.swipes
  FOR SELECT
  TO authenticated
  USING (auth.uid() = swiped_user_id);

-- Enable RLS on matches table
ALTER TABLE public.matches ENABLE ROW LEVEL SECURITY;

-- Users can insert matches they're part of
CREATE POLICY "Users can insert own matches"
  ON public.matches
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user1_id OR auth.uid() = user2_id);

-- Users can view matches they're part of
CREATE POLICY "Users can view own matches"
  ON public.matches
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user1_id OR auth.uid() = user2_id);

-- Function to automatically create match when mutual like is detected
CREATE OR REPLACE FUNCTION public.check_and_create_match()
RETURNS TRIGGER AS $$
DECLARE
  other_user_liked BOOLEAN;
  smaller_id UUID;
  larger_id UUID;
BEGIN
  -- Only proceed if this is a like (right swipe)
  IF NEW.is_like = true THEN
    -- Check if the other user has also liked this user
    SELECT EXISTS (
      SELECT 1 FROM public.swipes
      WHERE user_id = NEW.swiped_user_id
        AND swiped_user_id = NEW.user_id
        AND is_like = true
    ) INTO other_user_liked;

    -- If mutual like, create a match
    IF other_user_liked THEN
      -- Ensure user1_id < user2_id for the constraint
      IF NEW.user_id < NEW.swiped_user_id THEN
        smaller_id := NEW.user_id;
        larger_id := NEW.swiped_user_id;
      ELSE
        smaller_id := NEW.swiped_user_id;
        larger_id := NEW.user_id;
      END IF;

      -- Insert match (ON CONFLICT DO NOTHING in case it already exists)
      INSERT INTO public.matches (user1_id, user2_id)
      VALUES (smaller_id, larger_id)
      ON CONFLICT (user1_id, user2_id) DO NOTHING;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to automatically create matches
DROP TRIGGER IF EXISTS trigger_check_match ON public.swipes;
CREATE TRIGGER trigger_check_match
  AFTER INSERT ON public.swipes
  FOR EACH ROW
  EXECUTE FUNCTION public.check_and_create_match();
