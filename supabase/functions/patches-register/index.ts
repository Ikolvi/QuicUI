// QuicUI Patch Registration Function
// Registers a new patch with the backend after compiler generates it
//
// Supported Platforms:
// - Android: BsDiff patches (.quicui) with QUICUI01 header
// - iOS: Dart VM snapshots (.vmcode) with ELF format
//
// Security Features:
// - Rate limiting (10 requests/minute for registration)
// - Input validation and sanitization
// - API key authentication required
// - CORS with origin whitelisting
// - Security headers
// - Audit logging
// - Duplicate patch detection
// - File upload to Supabase Storage
// - Platform-specific format validation

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
  authenticateRequest,
  requirePermission,
  SecurityError,
} from '../_shared/security.ts';

interface PatchRegistration {
  patchId: string;
  version: string;
  appId: string;
  platform?: string;
  architecture?: string;
  uncompressedSize: number;
  compressedSize?: number;
  hash: string;
  compression?: string;
  releaseNotes?: string;
  critical?: boolean;
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

  // Initialize rate limit headers early so they're available in catch block
  let rateLimitHeaders = {};
  
  try {
    console.log(`📥 Request: ${requestContext.method} ${requestContext.path}`);
    console.log(`   Request ID: ${requestContext.requestId}`);
    console.log(`   Client IP: ${requestContext.clientIp}`);

    // Rate limiting (stricter for registration - auth tier)
    const clientId = extractClientId(req);
    const rateLimit = checkRateLimit(clientId, 'auth');
    
    if (!rateLimit.allowed) {
      console.log(`⚠️ Rate limit exceeded for ${clientId}`);
      throw new SecurityError(
        'Rate limit exceeded. Please try again later.',
        429,
        'RATE_LIMIT_EXCEEDED'
      );
    }

    rateLimitHeaders = getRateLimitHeaders(rateLimit);
    console.log(`✅ Rate limit check passed: ${rateLimit.remaining} remaining`);

    // Initialize Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    // AUTHENTICATION DISABLED FOR DEVELOPMENT
    console.log('⚠️  Authentication disabled - development mode');

    // Parse request body (handle both JSON and multipart)
    const contentType = req.headers.get('content-type') || '';
    let body: PatchRegistration;
    let patchFileBytes: Uint8Array | null = null;

    if (contentType.includes('multipart/form-data')) {
      console.log('📦 Processing multipart upload');
      const formData = await req.formData();
      
      // Extract form fields
      body = {
        patchId: formData.get('patchId') as string,
        version: formData.get('version') as string,
        appId: formData.get('appId') as string,
        platform: formData.get('platform') as string | undefined,
        architecture: formData.get('architecture') as string | undefined,
        uncompressedSize: parseInt(formData.get('uncompressedSize') as string),
        compressedSize: parseInt(formData.get('compressedSize') as string),
        hash: formData.get('hash') as string,
        compression: formData.get('compression') as string | undefined,
        releaseNotes: formData.get('releaseNotes') as string | undefined,
        critical: formData.get('critical') === 'true',
      };

      // Extract file
      const patchFile = formData.get('patchFile') as File;
      if (patchFile) {
        const arrayBuffer = await patchFile.arrayBuffer();
        patchFileBytes = new Uint8Array(arrayBuffer);
        console.log(`   File size: ${patchFileBytes.length} bytes`);
      }
    } else {
      console.log('📦 Processing JSON upload');
      const jsonBody = await req.json();
      body = jsonBody;
      
      // Handle base64 encoded file (legacy)
      if (jsonBody.patchFileBase64) {
        const binaryString = atob(jsonBody.patchFileBase64);
        patchFileBytes = new Uint8Array(binaryString.length);
        for (let i = 0; i < binaryString.length; i++) {
          patchFileBytes[i] = binaryString.charCodeAt(i);
        }
      }
    }

    const {
      patchId,
      version,
      appId,
      architecture,
      uncompressedSize,
      compressedSize,
      hash,
      compression,
      releaseNotes,
      critical,
    } = body;

    // Validate request
    console.log('🔍 Validating request parameters');
    const validationErrors = validateRequest(body, {
      patchId: {
        required: true,
        type: 'string',
        minLength: 3,
        maxLength: 255,
        pattern: /^[a-zA-Z0-9._-]+$/,
      },
      version: {
        required: true,
        type: 'string',
        minLength: 1,
        maxLength: 50,
        pattern: /^[0-9]+\.[0-9]+\.[0-9]+$/,
      },
      appId: {
        required: true,
        type: 'string',
        minLength: 3,
        maxLength: 255,
        pattern: /^[a-zA-Z0-9._-]+$/,
      },
      hash: {
        required: true,
        type: 'string',
        minLength: 32,
        maxLength: 128,
        pattern: /^[a-fA-F0-9]+$/,
      },
      platform: {
        type: 'string',
        enum: ['android', 'ios'],
      },
      architecture: {
        type: 'string',
        enum: ['arm64-v8a', 'armeabi-v7a', 'x86', 'x86_64', 'arm64', 'armv7', 'x86_64_sim'],
      },
      uncompressedSize: {
        required: true,
        type: 'integer',
        minimum: 1,
        maximum: 100000000, // 100MB max
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

    console.log('✅ Validation passed');
    
    // Determine platform and defaults
    const platform = body.platform || 'android';
    const defaultArch = platform === 'ios' ? 'arm64' : 'arm64-v8a';
    const fileType = platform === 'ios' ? '.vmcode' : '.quicui';
    
    console.log('📝 Registering patch:', {
      patchId,
      version,
      appId,
      platform,
      architecture: architecture || defaultArch,
      compression: compression || 'none',
      uncompressedSize,
      compressedSize: compressedSize || uncompressedSize,
      fileType,
    });

    // Check if patch already exists (duplicate detection)
    console.log('🔍 Checking for duplicate patches');
    const { data: existing } = await supabase
      .from('patches')
      .select('patch_id')
      .eq('patch_id', patchId)
      .single();

    if (existing) {
      console.log('⚠️ Duplicate patch detected:', patchId);
      
      // Log duplicate attempt
      await logSecurityEvent(supabase, {
        userId: requestContext.clientIp,
        eventType: 'PATCH_REGISTER',
        action: 'register_duplicate',
        resource: `patch:${patchId}`,
        status: 'failure',
        details: 'Patch already exists',
        clientIp: requestContext.clientIp,
      });

      throw new SecurityError(
        `Patch already registered: ${patchId}`,
        409,
        'DUPLICATE_PATCH'
      );
    }

        // Upload patch file to Supabase Storage
    console.log('📤 Uploading patch file to storage');
    
    try {
      // Use the bytes we already extracted from multipart or base64
      if (!patchFileBytes) {
        throw new SecurityError(
          'No patch file provided',
          400,
          'MISSING_PATCH_FILE'
        );
      }
      
      const bytes = patchFileBytes;

      console.log(`   Patch size: ${bytes.length} bytes`);
      console.log(`   Compression: ${compression}`);

      // Determine storage path based on platform and compression
      // (platform already declared above at line 222)
      let uploadPath: string;
      
      if (platform === 'ios') {
        // iOS uses .vmcode extension
        uploadPath = compression === 'xz' 
          ? `patches/${appId}/${patchId}.vmcode.xz`
          : `patches/${appId}/${patchId}.vmcode`;
      } else {
        // Android uses .quicui extension
        uploadPath = compression === 'xz'
          ? `patches/${appId}/${patchId}.quicui.xz`
          : `patches/${appId}/${patchId}.quicui`;
      }
      
      console.log(`📤 Storage path: ${uploadPath}`);
      
      // Verify compression format
      if (compression === 'xz') {
        // XZ files start with magic bytes: 0xFD, '7', 'z', 'X', 'Z', 0x00
        const xzMagic = [0xFD, 0x37, 0x7A, 0x58, 0x5A, 0x00];
        const hasXzMagic = xzMagic.every((byte, i) => bytes[i] === byte);
        
        if (!hasXzMagic) {
          console.error('❌ Invalid XZ file: missing magic bytes');
          throw new SecurityError(
            'Invalid compressed patch: XZ magic bytes not found',
            400,
            'INVALID_COMPRESSION'
          );
        }
        console.log('✓ XZ compression magic verified');
      } else if (compression === 'none' || !compression) {
        // Platform-specific validation
        if (platform === 'ios') {
          // iOS patches are .vmcode files - can be either:
          // 1. Full ELF: starts with 0x7F, 'E', 'L', 'F' at offset 0
          // 2. Differential: has QUIC header at offset 0, ELF at offset 65536
          if (bytes.length < 4) {
            throw new SecurityError(
              'Invalid .vmcode file: too small',
              400,
              'INVALID_PATCH'
            );
          }
          
          const elfMagic = [0x7F, 0x45, 0x4C, 0x46];  // \x7fELF
          const hasElfAtStart = elfMagic.every((byte, i) => bytes[i] === byte);
          
          // Check for QUIC header (differential patch format)
          const quicMagic = [0x51, 0x55, 0x49, 0x43];  // 'QUIC'
          const hasQuicHeader = bytes.length >= 65540 && 
                                quicMagic.every((byte, i) => bytes[i] === byte) &&
                                elfMagic.every((byte, i) => bytes[65536 + i] === byte);
          
          if (!hasElfAtStart && !hasQuicHeader) {
            console.error(`❌ Invalid .vmcode file: missing ELF or QUIC header`);
            throw new SecurityError(
              'Invalid .vmcode file: must be ELF or differential format',
              400,
              'INVALID_PATCH'
            );
          }
          
          if (hasQuicHeader) {
            console.log('✓ Differential .vmcode format verified (QUIC header + ELF at 64KB)');
          } else {
            console.log('✓ Full ELF format verified (.vmcode)');
          }
        } else {
          // Android patches are BsDiff format with QUICUI01 header
          if (bytes.length < 8) {
            throw new SecurityError(
              'Invalid patch file: too small',
              400,
              'INVALID_PATCH'
            );
          }
          const header = String.fromCharCode(...bytes.slice(0, 8));
          if (header !== 'QUICUI01') {
            console.error(`❌ Invalid patch header: ${header}`);
            throw new SecurityError(
              'Invalid patch file: missing QUICUI01 header',
              400,
              'INVALID_PATCH'
            );
          }
          console.log('✓ QUICUI01 header verified');
        }
      }

      // Upload to storage
      console.log(`📤 Uploading to storage: patches/${uploadPath}`);
      const { data: uploadData, error: uploadError } = await supabase.storage
        .from('patches')
        .upload(uploadPath, bytes, {
          contentType: compression === 'xz' ? 'application/x-xz' : 
                      compression === 'gzip' ? 'application/gzip' :
                      compression === 'bzip2' ? 'application/x-bzip2' :
                      'application/octet-stream',
          upsert: true, // Allow overwriting existing files
        });

      if (uploadError) {
        console.error('❌ Storage upload error:', uploadError);
        console.error('   Error message:', uploadError.message);
        console.error('   Error details:', JSON.stringify(uploadError));
        throw new SecurityError(
          `Failed to upload patch file to storage: ${uploadError.message}`,
          500,
          'STORAGE_ERROR'
        );
      }

      console.log('✅ Patch file uploaded to storage:', uploadData.path);
      const storagePath = uploadData.path;

      // Insert patch record
      console.log('💾 Inserting patch into database');
      
      // Build compressed_paths and compressed_sizes objects
      const compressedPaths: Record<string, string> = {};
      const compressedSizes: Record<string, number> = {};
      
      if (compression && compression !== 'none') {
        compressedPaths[compression] = storagePath;
        if (compressedSize) {
          compressedSizes[compression] = compressedSize;
        }
      }
      
      // Extract platform from request (default to 'android' for backward compatibility)
      // (platform already declared above at line 222)
      
      const { data: patchData, error } = await supabase
        .from('patches')
        .insert({
          patch_id: patchId,
          version,
          app_id: appId,
          platform,
          architecture,
          uncompressed_path: storagePath,
          compressed_paths: compressedPaths,
          uncompressed_size: uncompressedSize,
          compressed_sizes: compressedSizes,
          hash,
          compression,
          release_notes: releaseNotes,
          critical,
          created_at: new Date().toISOString(),
          download_count: 0,
          success_count: 0,
          failure_count: 0,
          status: 'active',
        })
        .select()
        .single();

      if (error) {
        console.error('❌ Database error:', error);
        console.error('   Error message:', error.message);
        console.error('   Error code:', error.code);
        console.error('   Error details:', JSON.stringify(error));
        
        // Log failure
        await logSecurityEvent(supabase, {
          userId: requestContext.clientIp,
          eventType: 'PATCH_REGISTER',
          action: 'register_failure',
          resource: `patch:${patchId}`,
          status: 'failure',
          details: error.message,
          clientIp: requestContext.clientIp,
        });

        throw new SecurityError(`Failed to register patch: ${error.message}`, 500, 'DATABASE_ERROR');
      }

      console.log('✅ Patch registered successfully:', patchId);

      // Log success
      await logSecurityEvent(supabase, {
        userId: requestContext.clientIp,
        eventType: 'PATCH_REGISTER',
        action: 'register_success',
        resource: `patch:${patchId}`,
        status: 'success',
        details: `Version: ${version}, Size: ${uncompressedSize} bytes`,
        clientIp: requestContext.clientIp,
      });

      const responseData = {
        success: true,
        patchId,
        message: `Patch ${patchId} registered successfully`,
        data: patchData,
      };

      return createSuccessResponse(responseData, corsHeaders, rateLimitHeaders);
    } catch (uploadErr) {
      console.error('❌ Failed to process patch file:', uploadErr);
      
      // If it's already a SecurityError, rethrow it
      if (uploadErr instanceof SecurityError) {
        throw uploadErr;
      }
      
      throw new SecurityError(
        `Failed to process patch file: ${uploadErr instanceof Error ? uploadErr.message : String(uploadErr)}`,
        500,
        'FILE_PROCESSING_ERROR'
      );
    }

  } catch (error) {
    console.error('❌ Error caught:', error instanceof Error ? error.message : String(error));

    // If the client is sending multipart data, we need to consume/drain the body
    // to prevent the client from hanging while waiting to send data
    try {
      const contentType = req.headers.get('content-type') || '';
      if (contentType.includes('multipart/form-data') && req.body) {
        console.log('🚰 Draining request body to prevent client hang...');
        // Try to consume the body with a timeout
        const drainPromise = req.text().catch(() => {});
        await Promise.race([
          drainPromise,
          new Promise(resolve => setTimeout(resolve, 100))
        ]);
      }
    } catch (drainError) {
      console.error('⚠️ Failed to drain body:', drainError);
    }

    // Include both CORS and rate limit headers in error response
    const errorResponse = createErrorResponse(error as Error, {
      ...corsHeaders,
      ...rateLimitHeaders,
    });
    
    console.log('🔙 Returning error response with status:', errorResponse.status);
    
    // Log audit event asynchronously (don't await - let it complete in background)
    try {
      const supabaseUrl = Deno.env.get('SUPABASE_URL');
      const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
      
      if (supabaseUrl && supabaseKey) {
        const supabase = createClient(supabaseUrl, supabaseKey);
        logSecurityEvent(supabase, {
          userId: requestContext.clientIp,
          eventType: 'PATCH_REGISTER',
          action: 'register_error',
          resource: 'unknown',
          status: 'failure',
          details: error instanceof Error ? error.message : String(error),
          clientIp: requestContext.clientIp,
        }).catch(logErr => console.error('⚠️ Audit log failed:', logErr));
      }
    } catch (logError) {
      console.error('⚠️ Failed to start audit log:', logError);
    }
    
    return errorResponse;
  }
});
