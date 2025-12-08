-- QuicUI Patches Table
-- Stores metadata about code push patches

CREATE TABLE IF NOT EXISTS patches (
  id BIGSERIAL PRIMARY KEY,
  patch_id VARCHAR(255) UNIQUE NOT NULL,
  version VARCHAR(50) NOT NULL,
  app_id VARCHAR(255) NOT NULL,
  architecture VARCHAR(50) DEFAULT 'arm64-v8a',
  
  -- File paths (relative or absolute)
  uncompressed_path TEXT NOT NULL,
  compressed_paths JSONB DEFAULT '{}',
  
  -- File sizes in bytes
  uncompressed_size BIGINT NOT NULL,
  compressed_sizes JSONB DEFAULT '{}',
  
  -- Integrity
  hash VARCHAR(64) NOT NULL,
  
  -- Metadata
  compression VARCHAR(20) DEFAULT 'none',
  release_notes TEXT DEFAULT '',
  critical BOOLEAN DEFAULT false,
  
  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Statistics
  download_count INTEGER DEFAULT 0,
  success_count INTEGER DEFAULT 0,
  failure_count INTEGER DEFAULT 0,
  
  -- Rollout configuration
  rollout_percentage DECIMAL(5,2) DEFAULT 100.00,
  target_devices JSONB DEFAULT '[]',
  
  -- Status
  status VARCHAR(20) DEFAULT 'active',
  
  -- Indexes
  CONSTRAINT patches_app_id_version_arch_unique UNIQUE (app_id, version, architecture)
);

-- Indexes for performance
CREATE INDEX idx_patches_app_id ON patches(app_id);
CREATE INDEX idx_patches_version ON patches(version);
CREATE INDEX idx_patches_architecture ON patches(architecture);
CREATE INDEX idx_patches_status ON patches(status);
CREATE INDEX idx_patches_created_at ON patches(created_at DESC);

-- Composite index for common query
CREATE INDEX idx_patches_lookup ON patches(app_id, architecture, version DESC);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically update updated_at
CREATE TRIGGER update_patches_updated_at
BEFORE UPDATE ON patches
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Comments
COMMENT ON TABLE patches IS 'Stores QuicUI code push patch metadata';
COMMENT ON COLUMN patches.patch_id IS 'Unique identifier for the patch (e.g., com.example.app_v1.0.1_arm64-v8a)';
COMMENT ON COLUMN patches.compressed_paths IS 'JSON object with compression type as key and file path as value';
COMMENT ON COLUMN patches.compressed_sizes IS 'JSON object with compression type as key and file size as value';
COMMENT ON COLUMN patches.rollout_percentage IS 'Percentage of users to roll out to (0-100)';
COMMENT ON COLUMN patches.target_devices IS 'JSON array of specific device IDs to target (empty = all devices)';

-- Sample data (optional, for testing)
-- INSERT INTO patches (patch_id, version, app_id, architecture, uncompressed_path, uncompressed_size, hash)
-- VALUES ('com.example.app_v1.0.1_arm64-v8a', '1.0.1', 'com.example.app', 'arm64-v8a', 'patches/patch_1.0.1.quicui', 3611081, 'abc123...');
