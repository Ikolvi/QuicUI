-- Step 1: Create API keys table
CREATE TABLE IF NOT EXISTS api_keys (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key_hash TEXT NOT NULL UNIQUE,
  key_prefix TEXT NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  user_id UUID,
  permissions TEXT[] DEFAULT ARRAY['patch:create', 'patch:read'],
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'revoked', 'expired')),
  last_used_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_api_keys_key_hash ON api_keys(key_hash);
CREATE INDEX IF NOT EXISTS idx_api_keys_status ON api_keys(status);

ALTER TABLE api_keys ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION update_api_key_last_used(key_hash_input TEXT)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE api_keys SET last_used_at = NOW() WHERE key_hash = key_hash_input;
END;
$$;

-- Step 2: Insert test API key
INSERT INTO api_keys (key_hash, key_prefix, name, description, permissions, status)
VALUES (
  '9c68dd0d2efdc665d2c2358881969d355989e6abb4fd4e302a73b4c4a935c549',
  'b3cf8b4e',
  'Test API Key',
  'Generated for testing patch uploads',
  ARRAY['patch:create', 'patch:read'],
  'active'
);

-- Verify
SELECT id, key_prefix, name, status, permissions, created_at FROM api_keys;
