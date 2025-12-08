// QuicUI API Key Creation Function
// Allows authenticated users to generate API keys for CLI/compiler access

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4";
import {
  getCorsHeaders,
  getSecurityHeaders,
  checkRateLimit,
  getRateLimitHeaders,
  extractClientId,
  createErrorResponse,
  createSuccessResponse,
  createRequestContext,
  SecurityError,
} from '../_shared/security.ts';

interface CreateKeyRequest {
  name: string;
  description?: string;
  permissions?: string[];
  expiresInDays?: number;
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

  let rateLimitHeaders = {};
  
  try {
    console.log(`📥 Request: ${requestContext.method} ${requestContext.path}`);

    // Rate limiting
    const clientId = extractClientId(req);
    const rateLimit = checkRateLimit(clientId, 'auth');
    
    if (!rateLimit.allowed) {
      throw new SecurityError(
        'Rate limit exceeded. Please try again later.',
        429,
        'RATE_LIMIT_EXCEEDED'
      );
    }

    rateLimitHeaders = getRateLimitHeaders(rateLimit);

    // Initialize Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    // Authenticate user (require JWT token)
    const authHeader = req.headers.get('authorization');
    if (!authHeader?.startsWith('Bearer ')) {
      throw new SecurityError('Authentication required', 401, 'AUTHENTICATION_REQUIRED');
    }

    const token = authHeader.substring(7);
    const { data: userData, error: authError } = await supabase.auth.getUser(token);
    
    if (authError || !userData?.user) {
      throw new SecurityError('Invalid authentication token', 401, 'INVALID_TOKEN');
    }

    const userId = userData.user.id;
    console.log(`✅ Authenticated user: ${userId}`);

    // Parse request body
    const body: CreateKeyRequest = await req.json();
    const { name, description, permissions, expiresInDays } = body;

    // Validate input
    if (!name || name.trim().length === 0) {
      throw new SecurityError('API key name is required', 400, 'INVALID_INPUT');
    }

    // Generate API key (32 bytes = 256 bits)
    const keyBytes = new Uint8Array(32);
    crypto.getRandomValues(keyBytes);
    const apiKey = `quicui_${Array.from(keyBytes)
      .map(b => b.toString(16).padStart(2, '0'))
      .join('')}`;

    // Hash the API key for storage
    const encoder = new TextEncoder();
    const data = encoder.encode(apiKey);
    const hashBuffer = await crypto.subtle.digest('SHA-256', data);
    const hashArray = Array.from(new Uint8Array(hashBuffer));
    const keyHash = hashArray.map(b => b.toString(16).padStart(2, '0')).join('');

    // Get key prefix (first 8 chars after 'quicui_')
    const keyPrefix = apiKey.substring(7, 15);

    // Calculate expiration date
    const expiresAt = expiresInDays 
      ? new Date(Date.now() + expiresInDays * 24 * 60 * 60 * 1000).toISOString()
      : null;

    // Insert API key into database
    const { data: apiKeyData, error: insertError } = await supabase
      .from('api_keys')
      .insert({
        key_hash: keyHash,
        key_prefix: keyPrefix,
        name: name.trim(),
        description: description?.trim() || null,
        user_id: userId,
        permissions: permissions || ['patch:create', 'patch:read'],
        status: 'active',
        expires_at: expiresAt,
      })
      .select()
      .single();

    if (insertError) {
      console.error('❌ Database error:', insertError);
      throw new SecurityError('Failed to create API key', 500, 'DATABASE_ERROR');
    }

    console.log(`✅ API key created: ${keyPrefix}...`);

    // Return response with the actual API key (ONLY shown once)
    return createSuccessResponse(
      {
        success: true,
        message: 'API key created successfully',
        apiKey: apiKey, // ONLY SHOWN ONCE!
        keyInfo: {
          id: apiKeyData.id,
          name: apiKeyData.name,
          description: apiKeyData.description,
          keyPrefix: apiKeyData.key_prefix,
          permissions: apiKeyData.permissions,
          status: apiKeyData.status,
          expiresAt: apiKeyData.expires_at,
          createdAt: apiKeyData.created_at,
        },
        warning: 'Save this API key securely. It will not be shown again.',
      },
      corsHeaders,
      rateLimitHeaders
    );

  } catch (error) {
    console.error('❌ Error:', error);

    // Try to drain request body if needed
    try {
      if (req.body) {
        await Promise.race([
          req.text().catch(() => {}),
          new Promise(resolve => setTimeout(resolve, 100))
        ]);
      }
    } catch (_) {}

    return createErrorResponse(error as Error, {
      ...corsHeaders,
      ...rateLimitHeaders,
    });
  }
});
