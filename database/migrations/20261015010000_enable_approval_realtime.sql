-- Enable Realtime events for admin account approval updates.
ALTER PUBLICATION supabase_realtime ADD TABLE public.user_info;
