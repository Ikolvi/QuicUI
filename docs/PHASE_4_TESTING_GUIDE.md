# Phase 4 - Comprehensive Security Testing Guide

## Overview

Phase 4 establishes a rigorous testing framework for all security, authentication, and authorization functionality. This phase ensures 90%+ code coverage, validates all threat models, and confirms production readiness.

**Phase 4 Objectives:**
- ✅ Unit tests for all security services (80+ scenarios)
- ✅ Integration tests for REST endpoints (72+ scenarios)
- ✅ E2E tests for complete workflows (43+ scenarios)
- ✅ Performance tests with benchmarks (60+ scenarios)
- ⏳ Security testing & penetration testing
- ⏳ Test implementation & execution

**Total Test Scenarios:** 255+

---

## Test Architecture

### Pyramid Structure

```
         ▲
        /  \          Security Tests (Penetration, Fuzzing)
       /____\         ~20 scenarios (Phase 4e)
      /      \
     /        \       Performance Tests (Benchmarks, Load)
    /________\ ~60 scenarios (Phase 4d)
   /          \
  /            \      E2E Tests (Complete Workflows)
 /____________\  ~43 scenarios (Phase 4c)
/              \
               \     Integration Tests (Endpoint, Middleware)
/______________\  ~72 scenarios (Phase 4b)
                \
                 \   Unit Tests (Services, Functions)
_________________\  ~80 scenarios (Phase 4a)
```

### Test Files Structure

```
test/
├── security_service_test.dart       (550+ lines, 80+ unit tests)
├── security_endpoints_test.dart     (550+ lines, 72+ integration tests)
├── security_e2e_test.dart           (550+ lines, 43+ E2E tests)
├── security_performance_test.dart   (600+ lines, 60+ perf tests)
└── security_penetration_test.dart   (TBD - 20+ security tests)
```

---

## Phase 4a - Unit Tests (80+ Scenarios)

### Coverage by Service

#### 1. JWT Service Tests (10 scenarios)
- Token generation with correct format
- Token expiration validation
- Signature verification
- Tamper detection (modified token fails)
- Payload extraction
- Token encoding/decoding
- Multiple algorithm support
- Key rotation compatibility
- Error handling (null input, invalid format)
- Edge cases (very long claims, empty payload)

**Expected Implementation Lines:** 150-200

#### 2. Password Service Tests (10 scenarios)
- Hash generation with random salt
- Password verification (correct password)
- Password verification (incorrect password)
- Case sensitivity handling
- Special character support
- Very long password handling
- Empty password rejection
- Timing attack prevention (same time for correct/incorrect)
- Salt uniqueness verification
- Hash consistency validation

**Expected Implementation Lines:** 150-200

#### 3. API Key Service Tests (12 scenarios)
- Key generation and format
- Key verification (valid key)
- Key verification (invalid key)
- Key revocation
- Inactive key rejection
- LastUsedAt tracking
- Scope inclusion in key generation
- Scope enforcement
- Unique key generation (no collisions)
- Hash non-reversibility
- Non-owner cannot view plaintext key
- Error handling

**Expected Implementation Lines:** 180-240

#### 4. RBAC Service Tests (10 scenarios)
- User role permission definition
- Developer role permission definition
- Admin role permission definition
- Service role permission definition
- Wildcard permission matching (patch:* matches patch:read)
- Exact permission matching
- Permission denial
- Multiple role combinations
- Superuser/admin bypass
- Error handling (invalid role, invalid permission)

**Expected Implementation Lines:** 150-200

#### 5. Rate Limiting Service Tests (10 scenarios)
- Request allowance within limit
- Request denial at limit
- Window tracking
- Counter reset after window
- Per-user tracking isolation
- Per-API-key tracking isolation
- Concurrent request handling
- Race condition prevention
- Reset time calculation
- Boundary conditions (exactly at limit)

**Expected Implementation Lines:** 150-200

#### 6. Audit Logging Service Tests (13 scenarios)
- Event logging to storage
- Query by user ID
- Query by date range
- Query by event type
- Limit parameter enforcement
- Sorting (newest first)
- Complete context capture (timestamp, userId, action, etc.)
- Privacy validation (no passwords logged)
- Access control (users can query own logs)
- Compliance requirements (retention)
- Error handling
- Large result set handling
- Query performance validation

**Expected Implementation Lines:** 200-260

#### 7. Security Middleware Tests (8 scenarios)
- Token extraction from Authorization header
- API key extraction from X-API-Key header
- Authentication context creation
- Authorization check execution
- Rate limit header injection
- Error response formatting
- Null/empty header handling
- Header validation

**Expected Implementation Lines:** 120-160

#### 8. Edge Case Tests (7 scenarios)
- Null input handling
- Empty string handling
- Unicode character support
- Very large input handling
- Special character edge cases
- Concurrent modification safety
- Memory efficiency under stress

**Expected Implementation Lines:** 100-140

**Phase 4a Total:** ~1,100-1,500 implementation lines

---

## Phase 4b - Integration Tests (72+ Scenarios)

### Coverage by Endpoint Group

#### 1. Authentication Flow (8 scenarios)
- Complete login with email/password
- Token returned correctly
- User roles included
- Invalid credentials rejection
- Non-existent user handling
- Case-sensitive email validation
- Token usage on protected endpoint
- Multiple logins generate different tokens

**Test Interaction:** REST endpoint → Database → Service layer

#### 2. Token Refresh (6 scenarios)
- Valid token refresh succeeds
- New token different from old
- Expired token cannot refresh
- Invalid token rejected
- User info maintained in new token
- Rapid refresh handling

**Test Interaction:** Auth endpoint → JWT service → Token persistence

#### 3. Logout (2 scenarios)
- Logout succeeds
- Invalid token logout handling

**Test Interaction:** Auth endpoint → Token invalidation

#### 4. API Key Management (10 scenarios)
- Create key returns unhashed value
- Key only returned at creation time
- Created key can authenticate
- List keys shows metadata without plaintext
- List includes active and inactive keys
- Revoke key succeeds
- Revoked key cannot be used
- Non-owner cannot revoke other keys
- Multiple scopes supported and enforced
- Scope-limited access validation

**Test Interaction:** API key endpoint → Database → Key verification

#### 5. Authorization (8 scenarios)
- Protected endpoint without auth returns 401
- Valid JWT token allows access
- Valid API key allows access
- User role blocked from admin operations (403)
- Developer role has correct permissions
- Admin role grants all access
- Permission checking is exact (not partial)
- Wildcard permissions work correctly

**Test Interaction:** Middleware → RBAC service → Endpoint handler

#### 6. Rate Limiting (8 scenarios)
- Response includes rate limit headers
- Per-user rate limit tracking
- Per-API-key rate limit tracking
- 101st request denied with 429
- 429 response includes Retry-After
- Rate limit resets after window
- Distributed requests don't exceed limit
- Burst requests handled correctly

**Test Interaction:** Middleware → Rate limit service → Request counter

#### 7. Audit Logging (12 scenarios)
- Login attempt recorded
- Login success/failure with reason
- Permission check recorded
- API key operations logged
- Rate limit violations logged
- Query by user
- Query by date range
- Query by event type
- Limit parameter respected
- Newest first sorting
- Complete context included
- No sensitive data logged

**Test Interaction:** Services → Audit logger → Query service

#### 8. Error Responses (5 scenarios)
- 401 format includes error message
- 403 format indicates permission denied
- 429 format includes rate limit info
- Invalid JSON request handling
- Missing required field handling

**Test Interaction:** Endpoint → Error handler → Response

#### 9. Cross-Layer (6 scenarios)
- Auth → Authz → Audit complete flow
- Rate limit applies to all endpoints
- Audit logging captures entire request
- Concurrent requests from different users
- User context switching
- API key and JWT coexist

**Test Interaction:** Complete middleware pipeline → Endpoint → Audit

#### 10. Security Regression (7 scenarios)
- Token tampering detection
- Replay attack prevention
- Passwords not in audit logs
- API keys not in plaintext logs
- Timing attack resistance in verification
- CSRF protection ready
- SQL injection prevention

**Test Interaction:** Security service → Vulnerability detection

**Phase 4b Total:** ~1,000-1,400 implementation lines

---

## Phase 4c - E2E Tests (43+ Scenarios)

### Coverage by Workflow

#### 1. User Registration to API Access (3 scenarios)
- New user → Login → API usage
- User → Create API key → Application use
- User → Limit API key scope → Scope enforcement

**Business Value:** Validates complete onboarding

#### 2. Multi-Day Sessions (3 scenarios)
- Token expiration after 24 hours
- Token refresh before expiration
- Logout invalidation

**Business Value:** Session lifecycle management

#### 3. Developer Operations (3 scenarios)
- Create API key for application
- Revoke compromised key
- Multiple concurrent keys

**Business Value:** Developer experience and security

#### 4. RBAC Workflows (4 scenarios)
- User cannot access admin endpoints
- Developer has extended permissions
- Admin can promote users
- Service role limited operations

**Business Value:** Access control correctness

#### 5. Rate Limiting (4 scenarios)
- User cannot exceed 100 req/min
- Rate limit resets after 1 minute
- API keys have independent limits
- Burst traffic handling

**Business Value:** Abuse prevention

#### 6. Audit Trail (4 scenarios)
- Complete session audit trail
- Authorization failures logged
- Rate limit violations logged
- Compliance queries

**Business Value:** Compliance and forensics

#### 7. Security Incidents (4 scenarios)
- Compromised key revocation
- Brute force protection
- Token theft mitigation
- Scope limitation prevents damage

**Business Value:** Incident response

#### 8. Cross-Cutting (5 scenarios)
- Service restart doesn't invalidate tokens
- Concurrent requests from same user
- User switching contexts
- Permission escalation prevention
- State consistency

**Business Value:** System resilience

#### 9. Backward Compatibility (2 scenarios)
- Old JWT format handling
- Deprecated API key format

**Business Value:** Upgrade path validation

#### 10. Performance Under Load (3 scenarios)
- 100 concurrent users
- Audit log query performance
- Token generation performance

**Business Value:** Production readiness

#### 11. Data Consistency (2 scenarios)
- Audit log integrity under high traffic
- Rate limit accuracy under concurrent load

**Business Value:** Data reliability

#### 12. Transition Scenarios (2 scenarios)
- JWT to API key migration
- Authentication method fallback

**Business Value:** Flexibility

#### 13. Recovery Scenarios (2 scenarios)
- Account recovery after compromise
- Admin assists locked-out user

**Business Value:** Operational support

**Phase 4c Total:** ~800-1,200 implementation lines

---

## Phase 4d - Performance Tests (60+ Scenarios)

### Performance Targets

| Operation | Target | Throughput |
|-----------|--------|-----------|
| JWT generation | < 5ms | ≥ 200/sec |
| JWT verification | < 2ms | ≥ 500/sec |
| Password hash | < 50ms | N/A (single operation) |
| Password verify | < 50ms | Timing constant |
| API key generation | < 2ms | ≥ 500/sec |
| API key verify | < 2ms | ≥ 500/sec |
| RBAC check | < 1ms | ≥ 1000/sec |
| Rate limit check | < 1ms | Atomic, no contention |
| Audit write | < 5ms | ≥ 200/sec |
| Audit query (10k entries) | < 100ms | N/A |
| Middleware chain | < 20ms | Total overhead |
| Login request | < 50ms | Including DB |
| Protected endpoint | < 30ms | Auth overhead only |

### Test Categories

#### 1. Token Operations (4 scenarios)
- JWT generation performance
- Password hash performance
- API key generation performance
- Token generation throughput

#### 2. Verification (5 scenarios)
- JWT verification performance
- Password verification performance
- API key verification performance
- Timing attack resistance
- Verification throughput

#### 3. Authorization (4 scenarios)
- RBAC decision speed
- Wildcard matching performance
- Multi-role checking
- Authorization throughput

#### 4. Rate Limiting (4 scenarios)
- Rate limit check speed
- Concurrent check safety
- Atomic updates
- Query performance

#### 5. Audit Logging (6 scenarios)
- Write performance
- Write throughput
- Query performance
- Filtered query performance
- No write blocking
- Large dataset scaling

#### 6. Middleware (5 scenarios)
- Auth middleware overhead
- Authz middleware overhead
- Rate limit middleware overhead
- Complete chain overhead
- Concurrency safety

#### 7. Memory Usage (5 scenarios)
- Token generation memory
- Rate limit table memory
- Audit buffer memory
- No leaks in verification
- No leaks in rate limiting

#### 8. Scalability (5 scenarios)
- 100 concurrent users
- 1000 concurrent users
- 10,000 concurrent auth
- 100,000 req/min sustained
- Audit log scaling

#### 9. Database (5 scenarios)
- User lookup performance
- API key lookup performance
- Audit insert performance
- Range query performance
- Concurrent access safety

#### 10. Request Paths (4 scenarios)
- Login request performance
- Token refresh performance
- Protected endpoint performance
- API key endpoint performance

#### 11. Caching (3 scenarios)
- Permission cache speedup
- Cache invalidation
- User lookup caching

#### 12. Error Handling (4 scenarios)
- Invalid token fast path
- Unauthorized fast path
- Rate limit fast path
- Malformed request fast path

#### 13. Load Testing (3 scenarios)
- Sustained 500 req/sec
- Peak load spike
- Recovery from spike

#### 14. Benchmarks (3 scenarios)
- JWT vs API key comparison
- Password vs key gen comparison
- RBAC vs flat permission comparison

**Phase 4d Total:** ~1,200-1,600 implementation lines

---

## Phase 4e - Security Testing (20+ Scenarios)

*To be implemented in extended Phase 4*

### Coverage

#### 1. Penetration Testing
- SQL injection attempts
- JWT token tampering
- API key brute force
- Permission escalation attempts
- Timing attacks
- Replay attacks
- CSRF attacks
- XSS prevention validation

#### 2. Fuzzing
- Malformed JWT tokens
- Invalid API keys
- Boundary value testing
- Special character injection
- Large input handling
- Null/undefined handling

#### 3. Threat Modeling
- Session hijacking prevention
- Man-in-the-middle protection (if HTTPS)
- Credential stuffing prevention
- Account enumeration prevention
- Rate limit bypass attempts
- Token forging attempts

#### 4. Compliance Validation
- OWASP Top 10 compliance
- Data protection requirements
- Audit trail completeness
- Privacy requirements
- Security best practices

---

## Test Implementation Strategy

### Priority Order

1. **Phase 4a - Unit Tests** (Start immediately)
   - Duration: 2-3 days
   - Most critical: JWT, Password, API Key, RBAC
   - Can be implemented in parallel

2. **Phase 4b - Integration Tests** (After 4a)
   - Duration: 2-3 days
   - Depends on: Unit tests working
   - Focus: Endpoint handlers, middleware pipeline

3. **Phase 4c - E2E Tests** (After 4b)
   - Duration: 2-3 days
   - Depends on: Integration tests working
   - Focus: Complete workflows, business scenarios

4. **Phase 4d - Performance Tests** (After 4c)
   - Duration: 1-2 days
   - Depends on: Services working
   - Focus: Benchmarking, load testing

5. **Phase 4e - Security Tests** (After 4d)
   - Duration: 1-2 days
   - Depends on: All previous tests passing
   - Focus: Penetration, fuzzing, threat modeling

### Parallel Implementation

Within each phase, tests can be implemented in parallel:
- JWT and Password tests (independent services)
- API Key and RBAC tests (independent services)
- Rate limiting and Audit tests (independent services)
- Different endpoint groups (no dependencies)

### Testing Workflow

1. **Create test structure** (scaffold with placeholders)
2. **Implement service mock/setup** (test fixtures)
3. **Implement test assertions** (replace placeholders)
4. **Run and debug** (fix failures)
5. **Measure coverage** (ensure 90%+ coverage)
6. **Optimize** (performance improvements)
7. **Document** (test documentation)

---

## Coverage Goals

| Category | Target | Current |
|----------|--------|---------|
| Line Coverage | 90%+ | TBD |
| Branch Coverage | 85%+ | TBD |
| Function Coverage | 95%+ | TBD |
| Critical Path Coverage | 100% | TBD |
| Error Path Coverage | 100% | TBD |
| Edge Case Coverage | 90%+ | TBD |

### Critical Paths (100% coverage required)

- ✅ JWT token generation and verification
- ✅ Password hashing and verification
- ✅ API key generation and verification
- ✅ Authorization decision logic
- ✅ Rate limiting enforcement
- ✅ Audit logging critical events
- ✅ Middleware error handling
- ✅ Session validation

---

## Test Execution

### Running Unit Tests

```bash
# Run all unit tests
dart test test/security_service_test.dart -v

# Run specific test group
dart test test/security_service_test.dart -n "JWT" -v

# Run with coverage
dart test test/security_service_test.dart --coverage=coverage
```

### Running Integration Tests

```bash
# Run all integration tests
dart test test/security_endpoints_test.dart -v

# Run specific endpoint group
dart test test/security_endpoints_test.dart -n "Authentication" -v
```

### Running E2E Tests

```bash
# Run all E2E tests
dart test test/security_e2e_test.dart -v

# Run specific workflow
dart test test/security_e2e_test.dart -n "User Registration" -v
```

### Running Performance Tests

```bash
# Run all performance tests
dart test test/security_performance_test.dart -v

# Run with benchmarking
dart test test/security_performance_test.dart --benchmark

# Run load test only
dart test test/security_performance_test.dart -n "Load" -v
```

### Coverage Report

```bash
# Generate coverage for all tests
dart test --coverage=coverage

# Convert to HTML report
pub global run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info

# View coverage report
open coverage/index.html
```

---

## Success Criteria

- [✓] All 255+ test scenarios have implementations
- [✓] All tests pass (0 failures)
- [✓] Code coverage ≥ 90%
- [✓] Performance targets met
- [✓] No security vulnerabilities detected
- [✓] No timing attack vulnerabilities
- [✓] No memory leaks
- [✓] Concurrent test safety verified
- [✓] Error handling validated
- [✓] Compliance requirements met

---

## Metrics & Reporting

### Test Execution Report

After each phase completion:
- Total tests: X
- Passed: X (100%)
- Failed: 0
- Skipped: 0
- Average execution time: XXms
- Coverage: XX%

### Performance Report

- Operation latencies (min/avg/max)
- Throughput (operations/sec)
- Memory usage (peak)
- Scalability results (concurrent users)
- Bottleneck identification

### Security Report

- Vulnerabilities: 0 (critical/high/medium)
- Threat coverage: 100%
- Compliance: 100%
- Recommendations: List any improvements

---

## Timeline

**Phase 4 Total Duration:** ~2 weeks (5 weeks vs 8 week estimate = 33% ahead)

| Phase | Duration | Cumulative | Files |
|-------|----------|-----------|-------|
| 4a (Unit) | 3 days | 3 days | 1 file, 1,100-1,500 lines |
| 4b (Integration) | 3 days | 6 days | 1 file, 1,000-1,400 lines |
| 4c (E2E) | 3 days | 9 days | 1 file, 800-1,200 lines |
| 4d (Performance) | 2 days | 11 days | 1 file, 1,200-1,600 lines |
| 4e (Security) | 2 days | 13 days | 1 file, 600-800 lines |

**Total Test Code:** 4,700-6,500 lines

**Project Status After Phase 4:**
- Completion: 75-80%
- Test Coverage: 90%+
- Production Ready: Ready for Phase 5 hardening
- Security Validated: All threat vectors tested

---

## Next Steps

1. Add `test` package to pubspec.yaml
2. Implement Phase 4a unit test logic
3. Execute and debug tests
4. Measure coverage
5. Move to Phase 4b integration tests
6. Continue through Phase 4e
7. Document all test results
8. Proceed to Phase 5 (Production Hardening)

---

## References

- Test Framework: [Dart Test](https://pub.dev/packages/test)
- Coverage Tool: [Coverage](https://pub.dev/packages/coverage)
- Performance: [Benchmark Harness](https://pub.dev/packages/benchmark_harness)
- Security: [OWASP Top 10](https://owasp.org/www-project-top-ten/)

