# Security Best Practices Guide - QuicUI v1.0.0

**Last Updated**: November 1, 2025  
**Version**: 1.0.0  
**Classification**: Public

## Overview

This guide provides security best practices for deploying and using QuicUI v1.0.0. It complements the API documentation and deployment guide with practical security recommendations.

---

## Table of Contents

1. [Server-Side Security](#server-side-security)
2. [Client-Side Security](#client-side-security)
3. [Authentication & Authorization](#authentication--authorization)
4. [Network Security](#network-security)
5. [Data Protection](#data-protection)
6. [Incident Response](#incident-response)
7. [Compliance & Audit](#compliance--audit)

---

## Server-Side Security

### Input Validation ✅ (Implemented)

QuicUI v1.0.0 includes comprehensive input validation. Ensure you leverage it:

#### Parameter Validation

```dart
// QuicUI automatically validates:
// - Parameter types (string, int, bool, etc.)
// - Parameter formats (email, UUID, URL, date-time)
// - Parameter ranges (min, max values)
// - Pattern matching (regex for custom formats)

// Example: GET /api/v1/products?page=1&limit=20
// QuicUI validates:
// - page is integer >= 1
// - limit is integer between 1-100
// - Dangerous patterns are rejected
```

#### Body Validation

```dart
// For POST/PUT requests, body is validated:
// - JSON structure conforms to schema
// - Required fields present
// - Field types correct
// - No injection patterns detected

// Example POST /api/v1/submit
{
  "title": "Product Name",      // String, validated
  "category": "electronics",     // Enum from whitelist
  "price": 99.99                 // Number within range
  // SQL injection attempts are rejected
  // XSS payloads are rejected
}
```

#### Best Practices

1. **Always validate on both client and server**
   - Client validation for UX
   - Server validation for security

2. **Use strict formats**
   - Email: RFC 5322 compliant
   - UUID: v4 format
   - Date-time: ISO-8601
   - URL: Valid HTTP(S) scheme

3. **Whitelist, don't blacklist**
   - Define allowed values
   - Reject everything else
   - QuicUI uses this approach

4. **Sanitize output**
   - Even with valid input, escape output for context
   - HTML context: escape `<>&"'`
   - JavaScript context: JSON encode
   - SQL context: Use parameterized queries (handled by ORM)

### Rate Limiting ✅ (Implemented)

QuicUI's rate limiting protects against brute force and DDoS attacks.

#### Understanding Rate Limits

```
Public Tier:    100 requests per minute (unauthenticated)
Auth Tier:      10 requests per minute (login/sensitive operations)
Metrics Tier:   1000 requests per minute (analytics)
Admin Tier:     500 requests per minute (administrative)
```

#### Rate Limit Headers

```http
X-RateLimit-Limit: 100        # Total requests allowed
X-RateLimit-Remaining: 87     # Requests remaining
X-RateLimit-Reset: 1698806460 # Unix timestamp when limit resets
Retry-After: 30                # Seconds to wait if rate limited
```

#### Handling Rate Limits in Clients

```dart
// Bad: Retry immediately
await api.request();  // Fails with 429

// Good: Respect Retry-After header
final response = await api.request();
if (response.statusCode == 429) {
  final retryAfter = int.parse(
    response.headers['Retry-After'] ?? '30'
  );
  await Future.delayed(Duration(seconds: retryAfter));
  await api.request();  // Retry after waiting
}

// Better: Exponential backoff
int retries = 0;
while (retries < 3) {
  try {
    return await api.request();
  } catch (e) {
    if (e.statusCode != 429) rethrow;
    
    final backoff = Duration(seconds: pow(2, retries).toInt());
    await Future.delayed(backoff);
    retries++;
  }
}
```

#### Rate Limiting for Brute Force Protection

The Auth Tier has a very low limit (10 req/min) specifically to prevent brute force attacks on login endpoints:

```
Scenario: Attacker tries 100 password attempts
- Timestamp 0s: Attempt 1-10 ✓ (within limit)
- Timestamp 1m: Rate limited 429 response
- Result: Attacker can only try ~10 passwords per minute
- To try 100,000 passwords: ~10,000 minutes (~7 days)
```

### Security Headers ✅ (Implemented)

Every response includes security headers protecting against common attacks.

#### Critical Headers Explained

| Header | Purpose | Example |
|--------|---------|---------|
| X-Frame-Options | Prevent clickjacking | DENY |
| X-Content-Type-Options | Prevent MIME sniffing | nosniff |
| Content-Security-Policy | Prevent XSS | default-src 'self' |
| Strict-Transport-Security | Force HTTPS | max-age=31536000 |
| X-XSS-Protection | Legacy XSS protection | 1 |
| Referrer-Policy | Control referrer | strict-origin-when-cross-origin |
| Permissions-Policy | Control feature access | geolocation=(), microphone=() |

#### Verifying Security Headers

```bash
# Check response headers
curl -I http://localhost:8080/api/v1/health

# Look for security headers in response:
# X-Frame-Options: DENY ✓
# X-Content-Type-Options: nosniff ✓
# Content-Security-Policy: ... ✓
# Strict-Transport-Security: ... ✓
```

### Error Handling ✅ (Implemented)

Production deployments hide sensitive information in error responses.

#### Production Error Response

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid email format",
    "status": 400,
    "timestamp": "2025-11-01T12:00:00Z",
    "trace_id": "req_abc123def456"
  }
}
```

**What's hidden**:
- ❌ Stack traces (not shown)
- ❌ Internal file paths (not shown)
- ❌ Database query details (not shown)
- ❌ Configuration details (not shown)
- ✅ User-friendly message (shown)
- ✅ Trace ID for support (shown)

#### Development Error Response (with detailed traces)

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid email format",
    "status": 400,
    "timestamp": "2025-11-01T12:00:00Z",
    "trace_id": "req_abc123def456",
    "details": {
      "field": "email",
      "provided": "invalid-email",
      "expected": "RFC 5322 email format"
    },
    "stack_trace": "..."  // Only in development
  }
}
```

#### Using Trace IDs for Debugging

```bash
# Share with support team when reporting issues
# Support uses trace_id to:
# - Find exact request in server logs
# - Identify root cause of error
# - Provide targeted solution

# Example: req_abc123def456
# Support runs: grep "req_abc123def456" /var/log/quicui/app.log
# Returns: Full request context, database queries, timing info
```

---

## Client-Side Security

### Token Storage

**❌ NEVER** store JWT tokens in vulnerable locations:

```dart
// BAD: SharedPreferences (plaintext on disk)
await prefs.setString('token', jwtToken);

// BAD: Regular files (readable by other apps)
File('token.txt').writeAsStringSync(jwtToken);

// BAD: Session storage (browser dev tools accessible)
window.sessionStorage['token'] = jwtToken;
```

**✅ ALWAYS** use secure storage:

```dart
// GOOD: flutter_secure_storage (uses OS keychain/keystore)
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const storage = FlutterSecureStorage();

// Store token securely
await storage.write(key: 'auth_token', value: jwtToken);

// Retrieve token securely
final token = await storage.read(key: 'auth_token');

// Delete on logout
await storage.delete(key: 'auth_token');
```

**Platform-specific Security**:
- **Android**: Uses Android Keystore
- **iOS**: Uses Keychain
- **Linux/Mac**: Uses system credential manager

### HTTPS/TLS Only

Never send sensitive data over HTTP:

```dart
// BAD: HTTP (man-in-the-middle vulnerable)
const url = 'http://api.example.com/api/v1/authenticate';

// GOOD: HTTPS (encrypted)
const url = 'https://api.example.com/api/v1/authenticate';

// For development with self-signed certificates:
import 'dart:io';

HttpClient httpClient = HttpClient();
httpClient.badCertificateCallback = 
    (X509Certificate cert, String host, int port) => true;

// For production: Always validate certificates
// Use certificate pinning for sensitive apps:
```

### Certificate Pinning (Advanced)

For high-security applications, pin certificates:

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class PinnedHttpClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (!request.url.host.endsWith('api.example.com')) {
      return super.send(request);
    }

    // Validate certificate fingerprint
    final fingerprint = await _getCertificateFingerprint(request.url);
    const expectedFingerprint = 'SHA256/abc123...';
    
    if (fingerprint != expectedFingerprint) {
      throw Exception('Certificate pinning validation failed');
    }

    return super.send(request);
  }

  Future<String> _getCertificateFingerprint(Uri url) async {
    // Implementation to extract and hash certificate
    // Compare with pinned fingerprint
  }
}
```

### Token Refresh

Automatically refresh tokens before expiration:

```dart
class AuthenticationService {
  Future<String> getValidToken() async {
    String? token = await _storage.read(key: 'auth_token');
    
    if (token == null) {
      // No token, redirect to login
      throw AuthenticationException('No token available');
    }

    // Check if token expires in next 5 minutes
    if (_isTokenExpiringSoon(token)) {
      // Refresh token
      token = await _refreshToken();
      await _storage.write(key: 'auth_token', value: token);
    }

    return token;
  }

  bool _isTokenExpiringSoon(String token) {
    // Decode JWT payload
    final parts = token.split('.');
    final payload = _decodeBase64(parts[1]);
    final json = jsonDecode(payload);
    
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(json['exp'] * 1000);
    final now = DateTime.now();
    
    // Return true if expires in next 5 minutes
    return expiresAt.difference(now).inMinutes <= 5;
  }

  Future<String> _refreshToken() async {
    // Call refresh endpoint with current token
    // Receive new token
    // Return new token
  }
}
```

### Logout Security

Always clear tokens on logout:

```dart
Future<void> logout() async {
  const storage = FlutterSecureStorage();
  
  // 1. Call server logout endpoint (invalidate server-side token)
  await api.post('/api/v1/logout');
  
  // 2. Clear all stored credentials
  await storage.delete(key: 'auth_token');
  await storage.delete(key: 'refresh_token');
  
  // 3. Clear any cached data
  await _clearCachedData();
  
  // 4. Redirect to login screen
  _navigateToLogin();
}
```

---

## Authentication & Authorization

### JWT Token Structure

QuicUI uses JWT (JSON Web Tokens) for authentication:

```
Header.Payload.Signature

Example: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ1c2VyLTEyMyIsImlhdCI6MTY5ODgwNjQwMCwiZXhwIjoxNjk4ODkyODAwLCJzY29wZSI6InJlYWQgd3JpdGUifQ.abc123...

Decoded:
{
  "alg": "HS256",      // Algorithm
  "typ": "JWT"        // Type
}
{
  "sub": "user-123",     // Subject (user ID)
  "iat": 1698806400,     // Issued at
  "exp": 1698892800,     // Expiration
  "scope": "read write"  // Permissions
}
```

### Scope System

Scopes define what operations a user can perform:

```
Scope: read
- GET requests allowed
- No POST/PUT/DELETE

Scope: write
- POST, PUT, DELETE allowed
- GET implied

Scope: admin
- All operations allowed
- Administrative endpoints accessible

Scope: metrics
- High-frequency analytics access
- Not allowed for regular endpoints
```

### Using Scopes Correctly

```dart
// Request token with appropriate scopes
final loginResponse = await api.post('/api/v1/authenticate', {
  'email': 'user@example.com',
  'password': 'password',
  'requested_scopes': 'read write'  // Only request needed scopes
});

// Store token with claims
final token = loginResponse['token'];
final claims = _decodeJWT(token);
print('Scopes: ${claims['scope']}');

// Use scopes to control UI
if (claims['scope'].contains('write')) {
  // Show edit/delete buttons
  showEditButton = true;
}

// Server enforces scopes
// POST /api/v1/submit requires 'write' scope
// If token has only 'read', request fails with 403 Forbidden
```

---

## Network Security

### CORS (Cross-Origin Resource Sharing)

QuicUI enforces strict CORS to prevent cross-origin attacks.

#### Understanding CORS

```
Browser Request from https://yourdomain.com
            ↓
    OPTIONS /api/v1/products
    Origin: https://yourdomain.com
            ↓
Server Response
    Access-Control-Allow-Origin: https://yourdomain.com ✓
    Access-Control-Allow-Methods: GET, POST
    Access-Control-Allow-Headers: Content-Type, Authorization
```

#### Configuring CORS

```bash
# .env.production
ENABLE_CORS=true
CORS_ORIGINS=https://yourdomain.com,https://app.yourdomain.com

# .env.development
ENABLE_CORS=true
CORS_ORIGINS=http://localhost:3000,http://localhost:8000
```

#### CORS Best Practices

1. **Whitelist specific origins**
   - ✅ `https://yourdomain.com` (good)
   - ✅ `https://app.yourdomain.com` (good)
   - ❌ `*` (dangerous - allows any origin)

2. **Use HTTPS in production**
   - ✅ `https://yourdomain.com` (secure)
   - ❌ `http://yourdomain.com` (insecure)

3. **Avoid localhost in production**
   - ✅ Localhost only in development
   - ✅ Production URLs in production config

### VPN & Private Networks

For internal APIs, use VPN or private networks:

```yaml
# Kubernetes Network Policy
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: quicui-network-policy
spec:
  podSelector:
    matchLabels:
      app: quicui
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: internal
    ports:
    - protocol: TCP
      port: 8080
```

### IP Whitelisting

For sensitive operations, whitelist IPs:

```bash
# Restrict /api/v1/settings to admin IPs
ufw allow from 10.0.1.100 to any port 8080
ufw allow from 10.0.1.101 to any port 8080
ufw deny to any port 8080  # Default deny
```

---

## Data Protection

### Encryption at Rest

Database data should be encrypted:

```bash
# PostgreSQL with encryption
ALTER SYSTEM SET ssl = on;
ALTER SYSTEM SET ssl_cert_file = 'server.crt';
ALTER SYSTEM SET ssl_key_file = 'server.key';
SELECT pg_reload_conf();

# Or use full-disk encryption
# Linux: LUKS
# macOS: FileVault
# Windows: BitLocker
```

### Encryption in Transit

All data in transit should be encrypted (TLS):

```bash
# Generate SSL certificate
openssl req -x509 -newkey rsa:4096 \
  -keyout server.key \
  -out server.crt \
  -days 365

# Or use Let's Encrypt (free, trusted)
certbot certonly --standalone -d api.yourdomain.com
```

### Data Minimization

Collect and store only necessary data:

```dart
// BAD: Store everything
{
  "user_id": "123",
  "email": "user@example.com",
  "password_hash": "bcrypt...",
  "ip_address": "203.0.113.42",
  "user_agent": "Mozilla/5.0...",
  "timestamp": "2025-11-01T12:00:00Z",
  "credit_card": "4532-xxxx-xxxx-0000",  // PCI-DSS required!
  "ssn": "xxx-xx-1234",                   // Never store!
  "medical_history": "..."                // Very sensitive
}

// GOOD: Store only what you need
{
  "user_id": "123",
  "email": "user@example.com",
  "password_hash": "bcrypt...",
  "timestamp": "2025-11-01T12:00:00Z"
  // Don't store: IP, user agent, credit cards, SSN, health info
  // Use payment processor for credit cards (Stripe, PayPal)
  // Use identity verification service for SSN
}
```

### Personally Identifiable Information (PII)

Handle PII with extra care:

```dart
// PII Examples:
// - Email address
// - Phone number
// - Full name
// - Address
// - Date of birth
// - Government ID numbers
// - Payment information

// Best practices for PII:
// 1. Collect only what's necessary
// 2. Encrypt PII in database
// 3. Hash PII in logs/traces
// 4. Delete PII after retention period
// 5. Encrypt PII in transit
// 6. Restrict access to PII
// 7. Audit PII access
```

---

## Incident Response

### Identifying Security Issues

Common signs of security incidents:

1. **Unusual API Activity**
   ```
   - Sudden spike in 401/403 errors
   - Rate limit hits increasing
   - Unusual geographic origins
   - Unusual user agents
   ```

2. **Performance Degradation**
   ```
   - Response times increasing
   - Error rates increasing
   - Memory/CPU spikes
   - Possible DDoS attack
   ```

3. **Error Anomalies**
   ```
   - New error patterns
   - SQL injection attempts in logs
   - XSS payload attempts
   - Path traversal attempts
   ```

### Response Procedures

#### Step 1: Detect

```bash
# Monitor error logs
docker logs -f quicui-backend | grep -i "error\|failed"

# Check metrics
curl http://localhost:8080/api/v1/analytics

# Verify security headers
curl -I https://api.yourdomain.com | grep "X-"
```

#### Step 2: Contain

```bash
# If under DDoS:
# 1. Scale up instances
# 2. Enable rate limiting
# 3. Contact infrastructure team

# If security breach suspected:
# 1. Invalidate all tokens
# 2. Force password reset
# 3. Enable MFA
# 4. Review access logs
```

#### Step 3: Investigate

```bash
# Check application logs
grep "trace_id:req_abc123" /var/log/quicui/app.log

# Check database activity
SELECT * FROM audit_log WHERE created_at > now() - interval '1 hour';

# Check failed login attempts
SELECT COUNT(*) FROM login_attempts 
WHERE status = 'failed' AND created_at > now() - interval '1 hour'
GROUP BY source_ip;
```

#### Step 4: Remediate

```bash
# Fix vulnerability
# - Apply security patch
# - Update dependencies
# - Fix configuration
# - Deploy fix to production

# Verify fix
curl https://api.yourdomain.com/api/v1/health
```

#### Step 5: Communicate

```
Incident Report Template:

Title: [INCIDENT] Description
Severity: Critical / High / Medium / Low
Status: Investigating / Contained / Resolved

What Happened:
- Detailed description
- Timeline
- Systems affected
- Users affected

Impact:
- Data exposed (Y/N)
- Services down (Y/N)
- Financial impact
- Reputation impact

Root Cause:
- Initial investigation
- Contributing factors

Resolution:
- Actions taken
- Timing
- Verification

Prevention:
- Process improvements
- Technical improvements
- Monitoring enhancements
```

---

## Compliance & Audit

### Security Audit Checklist

**Pre-Deployment** ✅
- [ ] All vulnerabilities fixed (15/15 in v1.0.0)
- [ ] Security headers present
- [ ] Rate limiting configured
- [ ] Input validation working
- [ ] Error handling secure
- [ ] Database encrypted
- [ ] HTTPS/TLS enabled
- [ ] Firewall configured

**Post-Deployment** ✅
- [ ] Health check passing
- [ ] Monitoring enabled
- [ ] Alerting configured
- [ ] Logs aggregated
- [ ] Backups automated
- [ ] Access control verified
- [ ] Security headers verified
- [ ] Rate limits verified

**Ongoing** ✅
- [ ] Daily security log review
- [ ] Weekly vulnerability scans
- [ ] Monthly penetration tests
- [ ] Quarterly security audits
- [ ] Dependency updates
- [ ] Password rotations
- [ ] Access reviews
- [ ] Incident drills

### Logging & Monitoring

```bash
# Enable audit logging
LOG_LEVEL=info

# Key events to log:
# - Authentication attempts (success/failure)
# - Authorization failures
# - Data access (especially PII)
# - Configuration changes
# - Error conditions
# - Rate limit hits
# - Security header misses

# Example log format:
timestamp=2025-11-01T12:00:00Z \
event=authentication_success \
user_id=user-123 \
ip=203.0.113.42 \
trace_id=req_abc123def456
```

### Regular Security Reviews

```bash
# Weekly review
- Security log analysis
- Error pattern detection
- Rate limit effectiveness
- Cache hit rates

# Monthly review
- Dependency updates available
- Security patch status
- Access control effectiveness
- Incident trend analysis

# Quarterly review
- Full security audit
- Penetration testing
- Compliance verification
- Policy updates
```

---

## Key Takeaways

✅ **Server-Side** (Implemented in QuicUI v1.0.0):
- Input validation prevents injection attacks
- Rate limiting prevents brute force/DDoS
- Security headers prevent client-side attacks
- Error handling hides sensitive information

✅ **Client-Side** (Your Implementation):
- Store tokens in secure storage
- Use HTTPS/TLS always
- Refresh tokens before expiration
- Clear tokens on logout

✅ **Network** (Shared Responsibility):
- Configure CORS whitelist
- Use firewalls and VPNs
- Enable HTTPS certificates
- Monitor unusual activity

✅ **Data** (Your Responsibility):
- Minimize data collection
- Encrypt sensitive data
- Handle PII carefully
- Audit access regularly

---

## Additional Resources

- **OWASP Top 10**: https://owasp.org/www-project-top-ten/
- **NIST Cybersecurity Framework**: https://www.nist.gov/cyberframework
- **CIS Benchmarks**: https://www.cisecurity.org/cis-benchmarks/
- **QuicUI Security Report**: See SECURITY_AUDIT_REPORT.md
- **API Documentation**: See API_DOCUMENTATION.md

---

**Last Updated**: November 1, 2025  
**Version**: 1.0.0  
**Status**: Production Ready ✅

Questions about security? Contact: security@quicui.com
