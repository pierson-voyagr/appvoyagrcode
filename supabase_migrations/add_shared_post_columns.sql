-- Add columns for shared posts to messages table
ALTER TABLE public.messages
ADD COLUMN IF NOT EXISTS shared_post_image TEXT,
ADD COLUMN IF NOT EXISTS shared_post_caption TEXT,
ADD COLUMN IF NOT EXISTS shared_post_likes INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS shared_post_comments INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS post_id UUID REFERENCES public.posts(id) ON DELETE SET NULL;

-- Create index for faster queries on post_id
CREATE INDEX IF NOT EXISTS idx_messages_post_id ON public.messages(post_id);

-- Add comment to explain the columns
COMMENT ON COLUMN public.messages.shared_post_image IS 'URL to the first image of a shared post';
COMMENT ON COLUMN public.messages.shared_post_caption IS 'Caption text of the shared post';
COMMENT ON COLUMN public.messages.shared_post_likes IS 'Number of likes on the shared post at time of sharing';
COMMENT ON COLUMN public.messages.shared_post_comments IS 'Number of comments on the shared post at time of sharing';
COMMENT ON COLUMN public.messages.post_id IS 'Reference to the actual post being shared (nullable)';
