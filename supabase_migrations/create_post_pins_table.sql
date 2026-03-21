-- Create post_pins table for users to pin posts
CREATE TABLE IF NOT EXISTS public.post_pins (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  post_id UUID NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(post_id, user_id) -- Prevent duplicate pins
);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_post_pins_post_id ON public.post_pins(post_id);
CREATE INDEX IF NOT EXISTS idx_post_pins_user_id ON public.post_pins(user_id);

-- Enable Row Level Security
ALTER TABLE public.post_pins ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view all pins
CREATE POLICY "Users can view all pins"
  ON public.post_pins
  FOR SELECT
  USING (true);

-- Policy: Users can insert their own pins
CREATE POLICY "Users can insert their own pins"
  ON public.post_pins
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can delete their own pins
CREATE POLICY "Users can delete their own pins"
  ON public.post_pins
  FOR DELETE
  USING (auth.uid() = user_id);

-- Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_post_pins_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_post_pins_updated_at_trigger
  BEFORE UPDATE ON public.post_pins
  FOR EACH ROW
  EXECUTE FUNCTION update_post_pins_updated_at();
