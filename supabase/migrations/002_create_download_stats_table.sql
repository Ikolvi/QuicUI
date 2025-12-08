-- QuicUI Download Statistics Table
-- Tracks individual patch downloads and application results

CREATE TABLE IF NOT EXISTS download_stats (
  id BIGSERIAL PRIMARY KEY,
  patch_id VARCHAR(255) NOT NULL,
  device_id VARCHAR(255),
  app_version VARCHAR(50),
  device_model VARCHAR(255),
  os_version VARCHAR(50),
  
  -- Download details
  downloaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  download_size BIGINT,
  compression VARCHAR(20),
  
  -- Application result
  applied BOOLEAN,
  applied_at TIMESTAMP WITH TIME ZONE,
  success BOOLEAN,
  error_message TEXT,
  
  -- Network info
  ip_address INET,
  country VARCHAR(2),
  
  -- Performance metrics
  download_duration_ms INTEGER,
  apply_duration_ms INTEGER,
  
  CONSTRAINT fk_patch
    FOREIGN KEY (patch_id)
    REFERENCES patches(patch_id)
    ON DELETE CASCADE
);

-- Indexes
CREATE INDEX idx_download_stats_patch_id ON download_stats(patch_id);
CREATE INDEX idx_download_stats_device_id ON download_stats(device_id);
CREATE INDEX idx_download_stats_downloaded_at ON download_stats(downloaded_at DESC);
CREATE INDEX idx_download_stats_success ON download_stats(success);

-- Comments
COMMENT ON TABLE download_stats IS 'Tracks individual patch downloads and application results';
COMMENT ON COLUMN download_stats.applied IS 'Whether the patch was applied (NULL if not yet applied)';
COMMENT ON COLUMN download_stats.success IS 'Whether the patch application succeeded (NULL if not yet applied)';
