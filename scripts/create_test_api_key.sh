#!/bin/bash
# Script to create a test API key manually

# First, let's create the table via SQL
SQL_CREATE_TABLE='
CREATE TABLE IF NOT EXISTS api_keys (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key_hash TEXT NOT NULL UNIQUE,
  key_prefix TEXT NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  user_id UUID,
  permissions TEXT[] DEFAULT ARRAY['"'"'patch:create'"'"', '"'"'patch:read'"'"'],
  status TEXT NOT NULL DEFAULT '"'"'active'"'"' CHECK (status IN ('"'"'active'"'"', '"'"'revoked'"'"', '"'"'expired'"'"')),
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
'

# Generate API key
API_KEY="quicui_$(openssl rand -hex 32)"
echo "Generated API Key: $API_KEY"
echo ""
echo "⚠️  SAVE THIS KEY SECURELY - IT WILL NOT BE SHOWN AGAIN!"
echo ""

# Hash the API key
KEY_HASH=$(echo -n "$API_KEY" | openssl dgst -sha256 -binary | xxd -p -c 256)
KEY_PREFIX=$(echo "$API_KEY" | cut -c 8-15)

echo "Key Prefix: $KEY_PREFIX..."
echo "Key Hash: $KEY_HASH"
echo ""

# Create SQL to insert the key
SQL_INSERT="
INSERT INTO api_keys (key_hash, key_prefix, name, description, permissions, status)
VALUES (
  '$KEY_HASH',
  '$KEY_PREFIX',
  'Test API Key',
  'Generated for testing patch uploads',
  ARRAY['patch:create', 'patch:read'],
  'active'
);
"

echo "SQL to insert API key:"
echo "$SQL_INSERT"
echo ""
echo "To use this key, update your quicui.yaml:"
echo "server:"
echo "  api_key: \"$API_KEY\""
