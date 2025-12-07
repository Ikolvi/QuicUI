// QuicUI CLI API Key Generation Function
// Allows CLI to auto-generate API keys for app projects (no auth required)
// Keys are tied to app_id for tracking/revocation

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4";

// ==================== Inline Security Utilities ====================

const defaultCorsConfig = {
  allowedOrigins: ['*'],  // Allow CLI from any origin
  allowedMethods: ['GET', 'POST', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-API-Key', 'apikey', 'Accept'],
  exposedHeaders: ['Content-Length', 'X-RateLimit-Remaining', 'X-RateLimit-Reset'],
  maxAge: 86400,
};

function getCorsHeaders(origin: string | null): Record<string, string> {
  return {
    'Access-Control-Allow-Origin': origin || '*',
    'Access-Control-Allow-Methods': defaultCorsConfig.allowedMethods.join(', '),
    'Access-Control-Allow-Headers': defaultCorsConfig.allowedHeaders.join(', '),
    'Access-Control-Max-Age': defaultCorsConfig.maxAge.toString(),
  };
}

function getSecurityHeaders(): Record<string, string> {
  return {
    'X-Frame-Options': 'DENY',
    'X-Content-Type-Options': 'nosniff',
    'X-Powered-By': 'QuicUI/Supabase',
  };
}

// Simple in-memory rate limiting
const rateLimitBuckets = new Map<string, { tokens: number; lastRefill: number }>();

function checkRateLimit(clientId: string): { allowed: boolean; remaining: number } {
  const config = { capacity: 10, refillInterval: 60000 };  // 10 requests per minute
  const bucketKey = `cli:${clientId}`;
  
  let bucket = rateLimitBuckets.get(bucketKey);
  if (!bucket) {
    bucket = { tokens: config.capacity, lastRefill: Date.now() };
    rateLimitBuckets.set(bucketKey, bucket);
  }

  const now = Date.now();
  const elapsed = now - bucket.lastRefill;
  
  if (elapsed >= config.refillInterval) {
    bucket.tokens = config.capacity;
    bucket.lastRefill = now;
  }

  const allowed = bucket.tokens >= 1;
  if (allowed) bucket.tokens -= 1;

  return { allowed, remaining: Math.floor(bucket.tokens) };
}

function extractClientId(request: Request): string {
  const xForwardedFor = request.headers.get('x-forwarded-for');
  if (xForwardedFor) return xForwardedFor.split(',')[0].trim();
  const xRealIp = request.headers.get('x-real-ip');
  if (xRealIp) return xRealIp;
  return 'client_unknown';
}

class SecurityError extends Error {
  constructor(
    message: string,
    public statusCode: number = 500,
    public code?: string
  ) {
    super(message);
    this.name = 'SecurityError';
  }
}

function createErrorResponse(error: Error, corsHeaders: Record<string, string>): Response {
  const statusCode = error instanceof SecurityError ? error.statusCode : 500;
  const code = error instanceof SecurityError ? error.code : 'INTERNAL_ERROR';
  const body = JSON.stringify({ error: { code, message: error.message, status: statusCode } });
  return new Response(body, {
    status: statusCode,
    headers: { 'Content-Type': 'application/json', ...corsHeaders, ...getSecurityHeaders() },
  });
}

function createSuccessResponse(data: any, corsHeaders: Record<string, string>): Response {
  return new Response(JSON.stringify(data), {
    status: 200,
    headers: { 'Content-Type': 'application/json', ...corsHeaders, ...getSecurityHeaders() },
  });
}

// ==================== Main Handler ====================

interface CliKeyRequest {
  app_id: string;
  app_name?: string;
  device_id?: string;
}

serve(async (req) => {
  const origin = req.headers.get('origin');
  const corsHeaders = getCorsHeaders(origin);

  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { status: 204, headers: { ...corsHeaders, ...getSecurityHeaders() } });
  }

  try {
    console.log(`📥 CLI Key Request: ${req.method} ${new URL(req.url).pathname}`);

    // Rate limiting
    const clientId = extractClientId(req);
    const rateLimit = checkRateLimit(clientId);
    
    if (!rateLimit.allowed) {
      throw new SecurityError('Rate limit exceeded. Please try again later.', 429, 'RATE_LIMIT_EXCEEDED');
    }

    // Only allow POST
    if (req.method !== 'POST') {
      throw new SecurityError('Method not allowed', 405, 'METHOD_NOT_ALLOWED');
    }

    // Initialize Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    // Parse request body
    const body: CliKeyRequest = await req.json();
    const { app_id, app_name, device_id } = body;

    // Validate app_id format (should be like com.example.app)
    if (!app_id || !/^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$/.test(app_id)) {
      throw new SecurityError('Invalid app_id format. Expected: com.example.app', 400, 'INVALID_APP_ID');
    }

    console.log(`📦 Generating CLI key for app: ${app_id}`);

    // Generate API key (32 bytes = 256 bits)
    const keyBytes = new Uint8Array(32);
    crypto.getRandomValues(keyBytes);
    const apiKey = `quicui_${Array.from(keyBytes).map(b => b.toString(16).padStart(2, '0')).join('')}`;

    // Hash the API key for storage
    const encoder = new TextEncoder();
    const hashBuffer = await crypto.subtle.digest('SHA-256', encoder.encode(apiKey));
    const keyHash = Array.from(new Uint8Array(hashBuffer)).map(b => b.toString(16).padStart(2, '0')).join('');

    // Get key prefix (first 8 chars after 'quicui_')
    const keyPrefix = apiKey.substring(7, 15);
    const keyName = `CLI: ${app_name || app_id}`;

    // Insert API key into database
    const { data: apiKeyData, error: insertError } = await supabase
      .from('api_keys')
      .insert({
        key_hash: keyHash,
        key_prefix: keyPrefix,
        name: keyName,
        description: `Auto-generated by QuicUI CLI for ${app_id}${device_id ? ` (device: ${device_id})` : ''}`,
        user_id: null,  // CLI keys are not tied to users
        permissions: ['patch:create', 'patch:read', 'baseline:upload'],
        status: 'active',
        expires_at: null,
      })
      .select()
      .single();

    if (insertError) {
      console.error('❌ Database error:', insertError);
      if (insertError.code === '23502') {
        throw new SecurityError('CLI key generation requires database migration.', 500, 'MIGRATION_REQUIRED');
      }
      throw new SecurityError('Failed to create API key', 500, 'DATABASE_ERROR');
    }

    console.log(`✅ CLI API key created: ${keyPrefix}...`);

    return createSuccessResponse({
      success: true,
      message: 'API key generated successfully',
      api_key: apiKey,
      key_prefix: keyPrefix,
      app_id: app_id,
      warning: 'This API key is stored in quicui.yaml. Keep it secure.',
    }, corsHeaders);

  } catch (error) {
    console.error('❌ Error:', error);
    return createErrorResponse(error as Error, corsHeaders);
  }
});
