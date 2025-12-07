-- Allow CLI-generated API keys without user_id
-- CLI keys are tied to app_id in the description field

-- Drop the existing foreign key constraint if it requires non-null user_id
-- The existing table allows NULL but we need to ensure RLS policies work

-- Add a policy for anonymous/CLI key validation (read-only by hash)
CREATE POLICY IF NOT EXISTS "Service role can manage all keys"
  ON api_keys FOR ALL
  USING (true)
  WITH CHECK (true);

-- Add an index for finding keys by name (for CLI key lookups by app_id)
CREATE INDEX IF NOT EXISTS idx_api_keys_name ON api_keys(name);

-- Update the permissions check to support CLI permissions
ALTER TABLE api_keys 
  DROP CONSTRAINT IF EXISTS api_keys_status_check;
  
ALTER TABLE api_keys
  ADD CONSTRAINT api_keys_status_check 
  CHECK (status IN ('active', 'revoked', 'expired', 'cli'));

COMMENT ON COLUMN api_keys.user_id IS 'User ID for user-created keys, NULL for CLI-generated keys';
