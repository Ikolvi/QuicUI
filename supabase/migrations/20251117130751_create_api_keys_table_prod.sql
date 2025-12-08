-- Create API keys table for authenticated patch uploads
CREATE TABLE IF NOT EXISTS api_keys (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key_hash TEXT NOT NULL UNIQUE,
  key_prefix TEXT NOT NULL, -- First 8 chars for identification
  name TEXT NOT NULL,
  description TEXT,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  permissions TEXT[] DEFAULT ARRAY['patch:create', 'patch:read'],
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'revoked', 'expired')),
  last_used_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create index for fast lookups
CREATE INDEX idx_api_keys_key_hash ON api_keys(key_hash);
CREATE INDEX idx_api_keys_user_id ON api_keys(user_id);
CREATE INDEX idx_api_keys_status ON api_keys(status);

-- Enable RLS
ALTER TABLE api_keys ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own API keys
CREATE POLICY "Users can view own API keys"
  ON api_keys FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Users can create their own API keys
CREATE POLICY "Users can create own API keys"
  ON api_keys FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own API keys
CREATE POLICY "Users can update own API keys"
  ON api_keys FOR UPDATE
  USING (auth.uid() = user_id);

-- Policy: Users can delete their own API keys
CREATE POLICY "Users can delete own API keys"
  ON api_keys FOR DELETE
  USING (auth.uid() = user_id);

-- Function to update last_used_at
CREATE OR REPLACE FUNCTION update_api_key_last_used(key_hash_input TEXT)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE api_keys
  SET last_used_at = NOW()
  WHERE key_hash = key_hash_input;
END;
$$;

COMMENT ON TABLE api_keys IS 'API keys for authenticated access to QuicUI services';
COMMENT ON COLUMN api_keys.key_hash IS 'SHA-256 hash of the API key';
COMMENT ON COLUMN api_keys.key_prefix IS 'First 8 characters for display purposes';
COMMENT ON COLUMN api_keys.permissions IS 'Array of permission strings (e.g., patch:create, patch:read)';
