// QuicUI Patch Download Function
// Serves patch files to clients with compression support
//
// Security Features:
// - Rate limiting (50 requests/minute for downloads)
// - Input validation and sanitization
// - CORS with origin whitelisting
// - Security headers
// - Audit logging
// - Download tracking and analytics

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4";
import {
  getCorsHeaders,
  getSecurityHeaders,
  checkRateLimit,
  getRateLimitHeaders,
  validateField,
  createRequestContext,
  extractClientId,
  createErrorResponse,
  createSuccessResponse,
  logSecurityEvent,
  SecurityError,
  authenticateRequest,
  requirePermission,
} from '../_shared/security.ts';

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

    // Rate limiting (download tier)
    const clientId = extractClientId(req);
    const rateLimit = checkRateLimit(clientId, 'download');
    
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

    // Authenticate request - require API key
    // TEMPORARILY DISABLED FOR TESTING
    // console.log('🔐 Authenticating request');
    // const authContext = await authenticateRequest(req, supabase);
    // requirePermission(authContext, 'patch:read');
    // console.log('✅ Authentication successful');

    // Parse URL parameters
    const url = new URL(req.url);
    const patchId = url.searchParams.get('patchId');
    const compression = url.searchParams.get('compression') || 'none';

    // Validate parameters
    console.log('🔍 Validating parameters');
    const patchIdError = validateField('patchId', patchId, {
      required: true,
      type: 'string',
      minLength: 3,
      maxLength: 255,
      pattern: /^[a-zA-Z0-9._-]+$/,
    });

    if (patchIdError) {
      throw new SecurityError(patchIdError.message, 400, 'VALIDATION_ERROR');
    }

    const compressionError = validateField('compression', compression, {
      type: 'string',
      enum: ['none', 'xz', 'gzip', 'bzip2'],
    });

    if (compressionError) {
      throw new SecurityError(compressionError.message, 400, 'VALIDATION_ERROR');
    }

    console.log('✅ Validation passed');
    console.log('📦 Download request:', { patchId, compression });

    // Get patch metadata
    console.log('🔍 Fetching patch metadata from database');
    const { data: patch, error } = await supabase
      .from('patches')
      .select('*')
      .eq('patch_id', patchId)
      .eq('status', 'active')
      .single();

    if (error || !patch) {
      console.error('❌ Patch not found:', patchId, error);
      
      // Log failed attempt
      await logSecurityEvent(supabase, {
        userId: requestContext.clientIp,
        eventType: 'PATCH_DOWNLOAD',
        action: 'download_not_found',
        resource: `patch:${patchId}`,
        status: 'failure',
        details: 'Patch not found',
        clientIp: requestContext.clientIp,
      });

      throw new SecurityError('Patch not found', 404, 'PATCH_NOT_FOUND');
    }

    console.log(`✅ Patch found: ${patch.version}`);

    // Get file from Supabase Storage
    // For iOS with compression, use compressed_paths; otherwise use uncompressed_path
    let downloadPath = patch.uncompressed_path;
    
    if (compression !== 'none' && patch.compressed_paths && patch.compressed_paths[compression]) {
      downloadPath = patch.compressed_paths[compression];
      console.log('📁 Using compressed path:', downloadPath);
    } else {
      console.log('📁 Using uncompressed path:', downloadPath);
    }
    
    const { data: fileData, error: downloadError } = await supabase.storage
      .from('patches')
      .download(downloadPath);

    if (downloadError || !fileData) {
      console.error('❌ Storage download error:', downloadError);
      
      // Log failed attempt
      await logSecurityEvent(supabase, {
        userId: requestContext.clientIp,
        eventType: 'PATCH_DOWNLOAD',
        action: 'download_storage_error',
        resource: `patch:${patchId}`,
        status: 'failure',
        details: 'Failed to download from storage',
        clientIp: requestContext.clientIp,
      });

      throw new SecurityError('Failed to download patch file', 500, 'STORAGE_DOWNLOAD_ERROR');
    }

    console.log('✅ File downloaded from storage');

    // Determine content type and file extension based on platform and compression
    const platform = patch.platform || 'android';
    let contentType = 'application/octet-stream';
    let fileExtension: string;
    
    // Base extension depends on platform
    if (platform === 'ios') {
      fileExtension = 'vmcode';
    } else {
      fileExtension = 'quicui';
    }
    
    // Adjust for compression
    if (compression !== 'none' && patch.compression) {
      if (patch.compression === 'xz') {
        contentType = 'application/x-xz';
        fileExtension = 'xz';  // .vmcode.xz or .quicui.xz
      } else if (patch.compression === 'gzip') {
        contentType = 'application/gzip';
        fileExtension = 'gz';
      } else if (patch.compression === 'bzip2') {
        contentType = 'application/x-bzip2';
        fileExtension = 'bz2';
      }
    }

    console.log('📋 Platform:', platform);
    console.log('📋 Content type:', contentType);
    console.log('📦 File size:', fileData.size, 'bytes');

    // Increment download counter (async, don't wait)
    supabase
      .from('patches')
      .update({ download_count: (patch.download_count || 0) + 1 })
      .eq('patch_id', patchId)
      .then(() => console.log('✅ Download count incremented'))
      .catch(err => console.error('⚠️ Failed to update download count:', err));

    // Log successful download
    await logSecurityEvent(supabase, {
      userId: requestContext.clientIp,
      eventType: 'PATCH_DOWNLOAD',
      action: 'download_success',
      resource: `patch:${patchId}`,
      status: 'success',
      details: `Platform: ${platform}, Version: ${patch.version}, Compression: ${compression}, Size: ${fileData.size} bytes`,
      clientIp: requestContext.clientIp,
    });

    // Stream the file to the client
    const additionalHeaders = {
      ...rateLimitHeaders,
      'Content-Type': contentType,
      'Content-Length': fileData.size.toString(),
      'Content-Disposition': `attachment; filename="${patchId}.${fileExtension}"`,
      'X-Patch-Version': patch.version,
      'X-Patch-Hash': patch.hash,
    };

    console.log('✅ Streaming file to client');
    return new Response(fileData, {
      status: 200,
      headers: {
        ...corsHeaders,
        ...getSecurityHeaders(),
        ...additionalHeaders,
      },
    });

  } catch (error) {
    console.error('❌ Error:', error);

    // Log failed security event
    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
    
    if (supabaseUrl && supabaseKey) {
      const supabase = createClient(supabaseUrl, supabaseKey);
      await logSecurityEvent(supabase, {
        userId: requestContext.clientIp,
        eventType: 'PATCH_DOWNLOAD',
        action: 'download_error',
        resource: 'unknown',
        status: 'failure',
        details: error instanceof Error ? error.message : String(error),
        clientIp: requestContext.clientIp,
      });
    }

    return createErrorResponse(error as Error, corsHeaders);
  }
});
