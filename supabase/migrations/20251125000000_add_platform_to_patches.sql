-- Add platform field to patches table to support iOS and Android
-- Migration: 20251125000000_add_platform_to_patches.sql

-- Add platform column (default to 'android' for existing records)
ALTER TABLE patches 
ADD COLUMN IF NOT EXISTS platform VARCHAR(20) DEFAULT 'android' NOT NULL;

-- Add check constraint to ensure valid platform values
ALTER TABLE patches
ADD CONSTRAINT patches_platform_check 
CHECK (platform IN ('android', 'ios'));

-- Update the unique constraint to include platform
-- Drop old constraint
ALTER TABLE patches
DROP CONSTRAINT IF EXISTS patches_app_id_version_arch_unique;

-- Add new constraint with platform
ALTER TABLE patches
ADD CONSTRAINT patches_app_id_version_arch_platform_unique 
UNIQUE (app_id, version, architecture, platform);

-- Add index for platform queries
CREATE INDEX IF NOT EXISTS idx_patches_platform ON patches(platform);

-- Add composite index for platform-specific lookups
CREATE INDEX IF NOT EXISTS idx_patches_platform_lookup 
ON patches(app_id, platform, architecture, version DESC);

-- Update comment
COMMENT ON COLUMN patches.platform IS 'Target platform: android or ios';
COMMENT ON COLUMN patches.architecture IS 'CPU architecture: arm64-v8a, armeabi-v7a, x86, x86_64 (Android) or arm64, armv7, x86_64_sim (iOS)';

-- Example: Update existing records if needed
-- UPDATE patches SET platform = 'android' WHERE platform IS NULL;
