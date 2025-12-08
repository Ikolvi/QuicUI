// Shared Security Utilities for QuicUI Supabase Edge Functions
// Implements comprehensive security measures from old backend

import { createClient, SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2.38.4';

// ==================== CORS Configuration ====================

export interface CorsConfig {
  allowedOrigins: string[];
  allowedMethods: string[];
  allowedHeaders: string[];
  exposedHeaders: string[];
  maxAge: number;
  allowCredentials: boolean;
}

export const defaultCorsConfig: CorsConfig = {
  allowedOrigins: [
    'https://pcaxvanjhtfaeimflgfk.supabase.co',
    'http://localhost:3000',
    'http://localhost:8080',
  ],
  allowedMethods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'HEAD', 'OPTIONS'],
  allowedHeaders: [
    'Content-Type',
    'Authorization',
    'X-API-Key',
    'X-Client-Info',
    'apikey',
    'Accept',
    'X-Requested-With',
  ],
  exposedHeaders: [
    'Content-Length',
    'X-RateLimit-Remaining',
    'X-RateLimit-Reset',
    'X-RateLimit-Limit',
  ],
  maxAge: 86400, // 24 hours
  allowCredentials: false,
};

export function getCorsHeaders(origin: string | null, config: CorsConfig = defaultCorsConfig): Record<string, string> {
  const headers: Record<string, string> = {};

  // Check if origin is allowed
  const isOriginAllowed = origin && (
    config.allowedOrigins.includes(origin) ||
    config.allowedOrigins.includes('*')
  );

  if (isOriginAllowed) {
    headers['Access-Control-Allow-Origin'] = origin;
    headers['Access-Control-Allow-Methods'] = config.allowedMethods.join(', ');
    headers['Access-Control-Allow-Headers'] = config.allowedHeaders.join(', ');
    headers['Access-Control-Expose-Headers'] = config.exposedHeaders.join(', ');
    headers['Access-Control-Max-Age'] = config.maxAge.toString();
    
    if (config.allowCredentials) {
      headers['Access-Control-Allow-Credentials'] = 'true';
    }
  }

  return headers;
}

// ==================== Security Headers ====================

export interface SecurityHeadersConfig {
  frameOptions: string;
  contentTypeOptions: string;
  contentSecurityPolicy: string;
  strictTransportSecurity: string;
  xssProtection: string;
  referrerPolicy: string;
  permissionsPolicy: string;
}

export const defaultSecurityHeaders: SecurityHeadersConfig = {
  frameOptions: 'DENY',
  contentTypeOptions: 'nosniff',
  contentSecurityPolicy: "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self'",
  strictTransportSecurity: 'max-age=31536000; includeSubDomains; preload',
  xssProtection: '1; mode=block',
  referrerPolicy: 'strict-origin-when-cross-origin',
  permissionsPolicy: 'accelerometer=(), camera=(), geolocation=(), gyroscope=(), magnetometer=(), microphone=(), payment=(), usb=()',
};

export function getSecurityHeaders(config: SecurityHeadersConfig = defaultSecurityHeaders): Record<string, string> {
  return {
    'X-Frame-Options': config.frameOptions,
    'X-Content-Type-Options': config.contentTypeOptions,
    'Content-Security-Policy': config.contentSecurityPolicy,
    'Strict-Transport-Security': config.strictTransportSecurity,
    'X-XSS-Protection': config.xssProtection,
    'Referrer-Policy': config.referrerPolicy,
    'Permissions-Policy': config.permissionsPolicy,
    'X-Powered-By': 'QuicUI/Supabase',
    'Server': 'QuicUI',
  };
}

// ==================== Rate Limiting ====================

interface RateLimitBucket {
  tokens: number;
  lastRefill: number;
}

interface RateLimitConfig {
  requestsPerMinute: number;
  capacity: number;
  refillInterval: number;
}

const rateLimitBuckets = new Map<string, RateLimitBucket>();

export const rateLimitTiers: Record<string, RateLimitConfig> = {
  public: { requestsPerMinute: 100, capacity: 10, refillInterval: 60000 },
  auth: { requestsPerMinute: 10, capacity: 5, refillInterval: 60000 },
  download: { requestsPerMinute: 50, capacity: 10, refillInterval: 60000 },
  admin: { requestsPerMinute: 500, capacity: 20, refillInterval: 60000 },
};

export interface RateLimitStatus {
  allowed: boolean;
  remaining: number;
  resetAfterSeconds: number;
  retryAfter: string;
}

export function checkRateLimit(clientId: string, tier: string = 'public'): RateLimitStatus {
  const config = rateLimitTiers[tier] || rateLimitTiers.public;
  const bucketKey = `${clientId}:${tier}`;
  
  // Get or create bucket
  let bucket = rateLimitBuckets.get(bucketKey);
  if (!bucket) {
    bucket = {
      tokens: config.capacity,
      lastRefill: Date.now(),
    };
    rateLimitBuckets.set(bucketKey, bucket);
  }

  // Refill tokens based on elapsed time
  const now = Date.now();
  const elapsed = now - bucket.lastRefill;
  const intervalsElapsed = elapsed / config.refillInterval;

  if (intervalsElapsed >= 1) {
    const refillAmount = Math.floor((config.requestsPerMinute / 60) * intervalsElapsed);
    bucket.tokens = Math.min(bucket.tokens + refillAmount, config.capacity);
    bucket.lastRefill = now;
  }

  // Check if tokens available
  const allowed = bucket.tokens >= 1;
  if (allowed) {
    bucket.tokens -= 1;
  }

  const resetAfterSeconds = Math.ceil((config.refillInterval - (now - bucket.lastRefill)) / 1000);

  return {
    allowed,
    remaining: Math.floor(bucket.tokens),
    resetAfterSeconds,
    retryAfter: resetAfterSeconds.toString(),
  };
}

export function getRateLimitHeaders(status: RateLimitStatus): Record<string, string> {
  return {
    'X-RateLimit-Remaining': status.remaining.toString(),
    'X-RateLimit-Reset': new Date(Date.now() + status.resetAfterSeconds * 1000).toISOString(),
    'Retry-After': status.retryAfter,
  };
}

// ==================== Input Validation & Sanitization ====================

export interface ValidationRule {
  required?: boolean;
  type?: 'string' | 'number' | 'integer' | 'boolean' | 'array' | 'object';
  minLength?: number;
  maxLength?: number;
  minimum?: number;
  maximum?: number;
  pattern?: RegExp;
  enum?: string[];
}

export interface ValidationError {
  field: string;
  message: string;
}

export function validateField(
  fieldName: string,
  value: any,
  rule: ValidationRule
): ValidationError | null {
  // Check required
  if (rule.required && (value === null || value === undefined || value === '')) {
    return { field: fieldName, message: `${fieldName} is required` };
  }

  if (value === null || value === undefined || value === '') {
    return null; // Field not required and not provided
  }

  // Check type
  if (rule.type) {
    const actualType = Array.isArray(value) ? 'array' : typeof value;
    const expectedType = rule.type === 'integer' ? 'number' : rule.type;
    
    if (actualType !== expectedType) {
      return { field: fieldName, message: `${fieldName} must be of type ${rule.type}` };
    }

    // Additional integer check
    if (rule.type === 'integer' && !Number.isInteger(value)) {
      return { field: fieldName, message: `${fieldName} must be an integer` };
    }
  }

  // String validations
  if (typeof value === 'string') {
    if (rule.minLength && value.length < rule.minLength) {
      return { field: fieldName, message: `${fieldName} must be at least ${rule.minLength} characters` };
    }
    if (rule.maxLength && value.length > rule.maxLength) {
      return { field: fieldName, message: `${fieldName} must be at most ${rule.maxLength} characters` };
    }
    if (rule.pattern && !rule.pattern.test(value)) {
      return { field: fieldName, message: `${fieldName} format is invalid` };
    }
    if (rule.enum && !rule.enum.includes(value)) {
      return { field: fieldName, message: `${fieldName} must be one of: ${rule.enum.join(', ')}` };
    }

    // Check for dangerous patterns
    if (containsDangerousPattern(value)) {
      return { field: fieldName, message: `${fieldName} contains invalid characters` };
    }
  }

  // Number validations
  if (typeof value === 'number') {
    if (rule.minimum !== undefined && value < rule.minimum) {
      return { field: fieldName, message: `${fieldName} must be >= ${rule.minimum}` };
    }
    if (rule.maximum !== undefined && value > rule.maximum) {
      return { field: fieldName, message: `${fieldName} must be <= ${rule.maximum}` };
    }
  }

  return null;
}

export function validateRequest(
  data: Record<string, any>,
  rules: Record<string, ValidationRule>
): ValidationError[] {
  const errors: ValidationError[] = [];

  for (const [fieldName, rule] of Object.entries(rules)) {
    const error = validateField(fieldName, data[fieldName], rule);
    if (error) {
      errors.push(error);
    }
  }

  return errors;
}

// ==================== Sanitization ====================

export function sanitizeString(input: string): string {
  // Remove dangerous characters
  let sanitized = input;

  // Remove HTML/JS special characters
  sanitized = sanitized.replace(/[<>"'`]/g, '');

  // Remove control characters except newline and tab
  sanitized = sanitized.replace(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/g, '');

  return sanitized;
}

export function containsDangerousPattern(value: string): boolean {
  // Check for SQL injection keywords
  const sqlKeywords = /(\bunion\b|\bselect\b|\binsert\b|\bupdate\b|\bdelete\b|\bdrop\b|\bcreate\b|\balter\b|\bexec\b)/i;
  if (sqlKeywords.test(value)) return true;

  // Check for command injection characters
  const dangerousChars = ['|', '&', ';', '`', '$', '\n', '\r'];
  for (const char of dangerousChars) {
    if (value.includes(char)) return true;
  }

  // Check for SQL comment patterns
  if (value.includes('--') || value.includes('/*') || value.includes('*/')) {
    return true;
  }

  return false;
}

// ==================== Authentication ====================

export interface AuthContext {
  userId?: string;
  email?: string;
  roles: string[];
  apiKeyId?: string;
  isAuthenticated: boolean;
}

export async function authenticateRequest(
  request: Request,
  supabase: SupabaseClient,
  bodyApiKey?: string
): Promise<AuthContext> {
  const authHeader = request.headers.get('authorization');
  const headerApiKey = request.headers.get('x-api-key') || request.headers.get('apikey');
  
  // Use API key from body if provided, otherwise check headers
  const apiKey = bodyApiKey || headerApiKey;

  // Check API key first (for server-to-server)
  if (apiKey) {
    // Hash the provided API key
    const encoder = new TextEncoder();
    const data = encoder.encode(apiKey);
    const hashBuffer = await crypto.subtle.digest('SHA-256', data);
    const hashArray = Array.from(new Uint8Array(hashBuffer));
    const keyHash = hashArray.map(b => b.toString(16).padStart(2, '0')).join('');

    // Look up API key in database
    const { data: apiKeyData, error } = await supabase
      .from('api_keys')
      .select('id, key_prefix, permissions, status, expires_at, user_id')
      .eq('key_hash', keyHash)
      .single();

    if (!error && apiKeyData) {
      // Check if key is active
      if (apiKeyData.status !== 'active') {
        throw new SecurityError('API key is not active', 401, 'INVALID_API_KEY');
      }

      // Check if key is expired
      if (apiKeyData.expires_at && new Date(apiKeyData.expires_at) < new Date()) {
        throw new SecurityError('API key has expired', 401, 'EXPIRED_API_KEY');
      }

      // Update last_used_at asynchronously (don't await)
      supabase.rpc('update_api_key_last_used', { key_hash_input: keyHash })
        .then(() => {})
        .catch((err: any) => console.error('Failed to update last_used_at:', err));

      console.log(`✅ Valid API key: ${apiKeyData.key_prefix}...`);

      return {
        apiKeyId: apiKeyData.id,
        userId: apiKeyData.user_id,
        roles: ['service'],
        isAuthenticated: true,
      };
    }
  }

  // Check JWT token in Authorization header
  if (authHeader?.startsWith('Bearer ')) {
    const token = authHeader.substring(7);
    
    // Try to validate as JWT
    const { data, error } = await supabase.auth.getUser(token);
    
    if (!error && data?.user) {
      return {
        userId: data.user.id,
        email: data.user.email,
        roles: ['user'], // Default role
        isAuthenticated: true,
      };
    }
  }

  // Anonymous access
  return {
    roles: [],
    isAuthenticated: false,
  };
}

// ==================== Authorization ====================

const rolePermissions: Record<string, string[]> = {
  admin: ['*'],
  developer: ['patch:*', 'app:*', 'metrics:read'],
  user: ['patch:read', 'patch:download', 'app:read'],
  service: ['patch:*', 'metrics:*'],
};

export function hasPermission(roles: string[], permission: string): boolean {
  for (const role of roles) {
    const permissions = rolePermissions[role] || [];
    
    // Admin has all permissions
    if (permissions.includes('*')) return true;
    
    // Exact match
    if (permissions.includes(permission)) return true;
    
    // Wildcard match
    for (const perm of permissions) {
      if (perm.endsWith(':*')) {
        const prefix = perm.substring(0, perm.length - 2);
        if (permission.startsWith(`${prefix}:`)) return true;
      }
    }
  }
  
  return false;
}

export function requirePermission(authContext: AuthContext, permission: string): void {
  if (!authContext.isAuthenticated) {
    throw new SecurityError('Authentication required', 401, 'AUTHENTICATION_REQUIRED');
  }

  if (!hasPermission(authContext.roles, permission)) {
    throw new SecurityError('Insufficient permissions', 403, 'INSUFFICIENT_PERMISSIONS');
  }
}

// ==================== Audit Logging ====================

export interface AuditLog {
  userId?: string;
  eventType: string;
  action: string;
  resource: string;
  status: 'success' | 'failure';
  details?: string;
  timestamp: string;
  clientIp?: string;
}

export async function logSecurityEvent(
  supabase: SupabaseClient,
  log: Omit<AuditLog, 'timestamp'>
): Promise<void> {
  try {
    const auditLog: AuditLog = {
      ...log,
      timestamp: new Date().toISOString(),
    };

    // In production, store in audit_logs table
    console.log('📝 Audit Log:', JSON.stringify(auditLog));

    // TODO: Uncomment when audit_logs table is created
    // await supabase
    //   .from('audit_logs')
    //   .insert(auditLog);
  } catch (error) {
    console.error('❌ Failed to log audit event:', error);
  }
}

// ==================== Error Handling ====================

export class SecurityError extends Error {
  constructor(
    message: string,
    public statusCode: number = 500,
    public code?: string
  ) {
    super(message);
    this.name = 'SecurityError';
  }
}

export function createErrorResponse(
  error: Error | SecurityError,
  corsHeaders: Record<string, string> = {}
): Response {
  const statusCode = error instanceof SecurityError ? error.statusCode : 500;
  const code = error instanceof SecurityError ? error.code : 'INTERNAL_ERROR';

  const body = {
    error: {
      code: code || 'INTERNAL_ERROR',
      message: error.message,
      status: statusCode,
      timestamp: new Date().toISOString(),
    },
  };

  const bodyStr = JSON.stringify(body);

  return new Response(bodyStr, {
    status: statusCode,
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': String(new TextEncoder().encode(bodyStr).length),
      'Connection': 'close',
      ...corsHeaders,
      ...getSecurityHeaders(),
    },
  });
}

export function createSuccessResponse(
  data: any,
  corsHeaders: Record<string, string> = {},
  additionalHeaders: Record<string, string> = {}
): Response {
  return new Response(JSON.stringify(data), {
    status: 200,
    headers: {
      'Content-Type': 'application/json',
      ...corsHeaders,
      ...getSecurityHeaders(),
      ...additionalHeaders,
    },
  });
}

// ==================== Request Context ====================

export interface RequestContext {
  requestId: string;
  method: string;
  path: string;
  clientIp: string;
  startTime: number;
  authContext?: AuthContext;
}

export function createRequestContext(request: Request): RequestContext {
  const url = new URL(request.url);
  const clientIp = request.headers.get('x-forwarded-for')?.split(',')[0].trim() ||
                    request.headers.get('x-real-ip') ||
                    'unknown';

  return {
    requestId: crypto.randomUUID(),
    method: request.method,
    path: url.pathname,
    clientIp,
    startTime: Date.now(),
  };
}

// ==================== Utility Functions ====================

export function extractClientId(request: Request): string {
  // Use X-Forwarded-For or X-Real-IP for client identification
  const xForwardedFor = request.headers.get('x-forwarded-for');
  if (xForwardedFor) {
    return xForwardedFor.split(',')[0].trim();
  }

  const xRealIp = request.headers.get('x-real-ip');
  if (xRealIp) {
    return xRealIp;
  }

  // Fallback to random ID (for local development)
  return 'client_unknown';
}

export function isValidEmail(email: string): boolean {
  const emailRegex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
  return emailRegex.test(email);
}

export function isValidUuid(uuid: string): boolean {
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
  return uuidRegex.test(uuid);
}

// Clean up old rate limit buckets periodically (memory management)
setInterval(() => {
  const now = Date.now();
  const maxAge = 3600000; // 1 hour

  for (const [key, bucket] of rateLimitBuckets.entries()) {
    if (now - bucket.lastRefill > maxAge) {
      rateLimitBuckets.delete(key);
    }
  }
}, 600000); // Run every 10 minutes
