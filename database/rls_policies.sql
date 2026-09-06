-- Enable RLS on user_info table if not already enabled
ALTER TABLE user_info ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Allow insert for authenticated users" ON user_info;
DROP POLICY IF EXISTS "Allow select for authenticated users" ON user_info;
DROP POLICY IF EXISTS "Allow update for authenticated users" ON user_info;
DROP POLICY IF EXISTS "Allow delete for authenticated users" ON user_info;

-- Policy to allow authenticated users to insert into user_info
CREATE POLICY "Allow insert for authenticated users"
ON user_info
FOR INSERT
TO authenticated
WITH CHECK (true);

-- Policy to allow authenticated users to select from user_info
CREATE POLICY "Allow select for authenticated users"
ON user_info
FOR SELECT
TO authenticated
USING (true);

-- Policy to allow authenticated users to update user_info
CREATE POLICY "Allow update for authenticated users"
ON user_info
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- Policy to allow authenticated users to delete from user_info
CREATE POLICY "Allow delete for authenticated users"
ON user_info
FOR DELETE
TO authenticated
USING (true);

-- Notifications are visible to authenticated dashboard users. Inserts should
-- be performed by trusted database functions/server-side code.
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated users can read notifications" ON public.notifications;
CREATE POLICY "Authenticated users can read notifications"
ON public.notifications
FOR SELECT
TO authenticated
USING (true);

DROP POLICY IF EXISTS "Authenticated users can mark notifications as read" ON public.notifications;
CREATE POLICY "Authenticated users can mark notifications as read"
ON public.notifications
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- Required for Supabase Realtime subscriptions used by the dashboard bell.
ALTER TABLE public.notifications REPLICA IDENTITY FULL;
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'notifications'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
  END IF;
END
$$;
