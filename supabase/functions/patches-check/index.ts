// QuicUI Patch Check Function
// Checks if patches are available for a specific app version
// 
// Security Features:
// - Rate limiting (100 requests/minute per IP)
// - Input validation and sanitization
// - CORS with origin whitelisting
// - Security headers (CSP, X-Frame-Options, etc.)
// - Audit logging
// - Authentication support (optional)

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4";
import {
  getCorsHeaders,
  getSecurityHeaders,
  checkRateLimit,
  getRateLimitHeaders,
  validateRequest,
  createRequestContext,
  extractClientId,
  createErrorResponse,
  createSuccessResponse,
  logSecurityEvent,
  SecurityError,
  authenticateRequest,
  requirePermission,
} from '../_shared/security.ts';

interface PatchCheckRequest {
  appId: string;
  currentVersion: string;
  platform?: string;
  architecture?: string;
  acceptCompression?: string[];
}

serve(async (req) => {
  const origin = req.headers.get('origin');
  const corsHeaders = getCorsHeaders(origin);
  const requestContext = createRequestContext(req);

  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      status: 204,
      headers: {
        ...corsHeaders,
        ...getSecurityHeaders(),
      },
    });
  }

  try {
    console.log(`📥 Request: ${requestContext.method} ${requestContext.path}`);
    console.log(`   Request ID: ${requestContext.requestId}`);
    console.log(`   Client IP: ${requestContext.clientIp}`);

    // Rate limiting
    const clientId = extractClientId(req);
    const rateLimit = checkRateLimit(clientId, 'public');
    
    if (!rateLimit.allowed) {
      console.log(`⚠️ Rate limit exceeded for ${clientId}`);
      throw new SecurityError(
        'Rate limit exceeded. Please try again later.',
        429,
        'RATE_LIMIT_EXCEEDED'
      );
    }

    const rateLimitHeaders = getRateLimitHeaders(rateLimit);
    console.log(`✅ Rate limit check passed: ${rateLimit.remaining} remaining`);

    // Initialize Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    // Parse request body
    const body: PatchCheckRequest & { apiKey?: string } = await req.json();
    const { appId, currentVersion, platform, architecture, acceptCompression, apiKey } = body;

    // Authenticate request - require API key (from body or headers)
    console.log('🔐 Authenticating request');
    const authContext = await authenticateRequest(req, supabase, apiKey);
    requirePermission(authContext, 'patch:read');
    console.log('✅ Authentication successful');

    // Validate request
    console.log('🔍 Validating request parameters');
    const validationErrors = validateRequest(body, {
      appId: {
        required: true,
        type: 'string',
        minLength: 3,
        maxLength: 255,
        pattern: /^[a-zA-Z0-9._-]+$/,
      },
      currentVersion: {
        required: true,
        type: 'string',
        minLength: 1,
        maxLength: 50,
        pattern: /^[0-9]+\.[0-9]+\.[0-9]+$/,
      },
      architecture: {
        type: 'string',
        enum: ['arm64-v8a', 'armeabi-v7a', 'x86', 'x86_64', 'arm64', 'armv7', 'x86_64_sim'],
      },
      platform: {
        type: 'string',
        enum: ['android', 'ios'],
      },
    });

    if (validationErrors.length > 0) {
      console.log('❌ Validation failed:', validationErrors);
      throw new SecurityError(
        `Validation failed: ${validationErrors.map(e => e.message).join(', ')}`,
        400,
        'VALIDATION_ERROR'
      );
    }

    console.log(`✅ Validation passed`);
    console.log(`   App: ${appId}`);
    console.log(`   Current Version: ${currentVersion}`);
    console.log(`   Platform: ${platform || 'android'}`);
    
    // Default architecture based on platform
    const defaultArch = platform === 'ios' ? 'arm64' : 'arm64-v8a';
    const targetArch = architecture || defaultArch;
    console.log(`   Architecture: ${targetArch}`);

    // Log security event
    await logSecurityEvent(supabase, {
      userId: requestContext.clientIp,
      eventType: 'PATCH_CHECK',
      action: 'check_updates',
      resource: `app:${appId}`,
      status: 'success',
      details: `Platform: ${platform || 'android'}, Version: ${currentVersion}`,
      clientIp: requestContext.clientIp,
    });

    // Query patches table for available updates
    // Note: We fetch all active patches and filter by semantic versioning in code
    // because PostgreSQL string comparison doesn't work correctly for versions
    console.log('🔍 Querying database for patches');
    const { data: patches, error } = await supabase
      .from('patches')
      .select('*')
      .eq('app_id', appId)
      .eq('platform', platform || 'android')
      .eq('architecture', targetArch)
      .eq('status', 'active')
      .order('created_at', { ascending: false });

    if (error) {
      console.error('❌ Database error:', error);
      throw new SecurityError('Database query failed', 500, 'DATABASE_ERROR');
    }

    // Helper function to compare semantic versions
    const compareVersions = (v1: string, v2: string): number => {
      const parts1 = v1.split('.').map(Number);
      const parts2 = v2.split('.').map(Number);
      
      for (let i = 0; i < Math.max(parts1.length, parts2.length); i++) {
        const part1 = parts1[i] || 0;
        const part2 = parts2[i] || 0;
        
        if (part1 > part2) return 1;
        if (part1 < part2) return -1;
      }
      
      return 0;
    };

    // Filter patches with version greater than current version
    const availablePatches = patches?.filter((p: any) => 
      compareVersions(p.version, currentVersion) > 0
    ) || [];

    // Sort by version (highest first)
    availablePatches.sort((a: any, b: any) => compareVersions(b.version, a.version));

    // Check if patch available
    if (availablePatches.length === 0) {
      console.log('ℹ️ No updates available');
      
      const responseData = {
        updateAvailable: false,
        message: 'No updates available',
        currentVersion,
      };

      return createSuccessResponse(responseData, corsHeaders, rateLimitHeaders);
    }

    const patch = availablePatches[0];
    console.log(`✅ Update found: ${patch.version}`);

    // Determine best compression format
    let downloadUrl = patch.uncompressed_path;
    let compression = 'none';
    let size = patch.uncompressed_size;

    if (acceptCompression && acceptCompression.length > 0) {
      // Check for xz (best compression)
      if (acceptCompression.includes('xz') && patch.compressed_paths?.xz) {
        downloadUrl = patch.compressed_paths.xz;
        compression = 'xz';
        size = patch.compressed_sizes?.xz || size;
        console.log('   Using xz compression');
      }
      // Check for gzip
      else if (acceptCompression.includes('gzip') && patch.compressed_paths?.gz) {
        downloadUrl = patch.compressed_paths.gz;
        compression = 'gzip';
        size = patch.compressed_sizes?.gz || size;
        console.log('   Using gzip compression');
      }
    }

    // Return patch information
    const responseData = {
      updateAvailable: true,
      patchId: patch.patch_id,
      version: patch.version,
      downloadUrl: `/patches-download?patchId=${patch.patch_id}&compression=${compression}`,
      size,
      hash: patch.hash,
      compression,
      critical: patch.critical || false,
      releaseNotes: patch.release_notes || '',
    };

    console.log('✅ Request completed successfully');
    return createSuccessResponse(responseData, corsHeaders, rateLimitHeaders);

  } catch (error) {
    console.error('❌ Error:', error);

    // Log failed security event
    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
    
    if (supabaseUrl && supabaseKey) {
      const supabase = createClient(supabaseUrl, supabaseKey);
      await logSecurityEvent(supabase, {
        userId: requestContext.clientIp,
        eventType: 'PATCH_CHECK',
        action: 'check_updates',
        resource: 'unknown',
        status: 'failure',
        details: error instanceof Error ? error.message : String(error),
        clientIp: requestContext.clientIp,
      });
    }

    return createErrorResponse(error as Error, corsHeaders);
  }
});
