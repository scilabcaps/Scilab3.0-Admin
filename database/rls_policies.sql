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
