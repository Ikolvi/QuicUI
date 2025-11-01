# QuicUI Code Push - Local Deployment Quick Start

**Quick Setup**: 2 minutes to run locally  
**Requirements**: Dart 3.0+, PostgreSQL (or Docker)  
**Status**: ✅ Production-ready code, development configuration

---

## 🚀 Quickest Way to Deploy

### Option 1: Automated Setup (Recommended)

```bash
# Clone and navigate
cd /Users/admin/Documents/quicui2/packages/quicui_backend

# Run the deployment script
bash bin/deploy_local.sh

# The script will:
# ✅ Check Dart SDK
# ✅ Check PostgreSQL
# ✅ Install dependencies
# ✅ Verify security configuration
# ✅ Run tests (optional)
# ✅ Start the backend
```

**That's it!** Backend will start on `http://localhost:8080`

---

## 📋 Manual Setup (If Needed)

### Step 1: Prerequisites

```bash
# Install Dart 3.0+ (if not already installed)
# https://dart.dev/get-dart

# Verify Dart is installed
dart --version
# Output: Dart SDK version 3.0.0+ 

# Install PostgreSQL or use Docker
# Docker: (easiest)
docker run -d --name quicui-postgres \
  -e POSTGRES_PASSWORD=postgres \
  -p 5432:5432 \
  postgres:15

# Or install PostgreSQL locally
# macOS: brew install postgresql
# Ubuntu: sudo apt-get install postgresql
```

### Step 2: Navigate to Backend Directory

```bash
cd /Users/admin/Documents/quicui2/packages/quicui_backend
```

### Step 3: Load Environment Configuration

```bash
# Source the local development environment
source .env.local

# Verify environment variables are set
echo $QUICUI_ENVIRONMENT
# Output: development
```

### Step 4: Install Dependencies

```bash
dart pub get

# Output should show:
# Resolving dependencies...
# Got dependencies!
```

### Step 5: Verify Configuration

```bash
# Run security configuration verification
dart run bin/verify_security_config.dart

# Should output:
# ✅ Configuration loaded successfully
# ✅ CORS origins configured
# ✅ Security headers enabled
# ... (50+ checks)
# ✅ All security checks passed!
```

### Step 6: Run Tests (Optional)

```bash
# Run the test suite
dart test

# Output:
# 40+ tests covering security middleware
# ✅ All tests passed
```

### Step 7: Start the Backend

```bash
dart run

# Output:
# 🚀 Starting QuicUI Code Push Backend...
# ✅ Server listening on http://0.0.0.0:8080
```

---

## 🧪 Testing the Local Deployment

### 1. Health Check

```bash
# In another terminal
curl http://localhost:8080/health

# Response:
# {"status": "healthy"}
```

### 2. Test CORS Headers

```bash
curl -X OPTIONS http://localhost:8080/api/v1/auth/login \
  -H "Origin: http://localhost:3000" \
  -H "Access-Control-Request-Method: POST" \
  -v

# Look for:
# Access-Control-Allow-Origin: http://localhost:3000
# Access-Control-Allow-Methods: GET, POST, ...
```

### 3. Test Security Headers

```bash
curl -I http://localhost:8080/api/v1/auth/login

# Should see:
# X-Content-Type-Options: nosniff
# X-Frame-Options: DENY
# Content-Security-Policy: default-src 'self'
```

### 4. Test Request Validation

```bash
# Valid JSON request
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"test","password":"test"}'

# Invalid request (wrong content-type)
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: text/plain" \
  -d 'invalid'
  
# Response: 400 (Content-Type must be application/json)
```

---

## 🐳 Docker Alternative (If PostgreSQL Not Available)

```bash
# Start PostgreSQL in Docker
docker run -d \
  --name quicui-postgres \
  -e POSTGRES_PASSWORD=postgres \
  -p 5432:5432 \
  postgres:15

# Backend will automatically connect to localhost:5432
# Update .env.local if using different host/port

# Stop PostgreSQL when done
docker stop quicui-postgres
docker rm quicui-postgres
```

---

## 🔑 Environment Variables (Local Development)

These are already set in `.env.local`:

```
QUICUI_ENVIRONMENT=development           # Permissive security for testing
QUICUI_ALLOWED_ORIGINS=localhost:*       # Allow any localhost origin
DATABASE_HOST=localhost                  # Local PostgreSQL
DATABASE_PORT=5432
DATABASE_NAME=quicui_dev
DATABASE_USER=postgres
DATABASE_PASSWORD=postgres
JWT_SECRET_KEY=dev-jwt-secret-...        # Development secret
API_KEY_SECRET=dev-api-key-secret-...    # Development secret
SERVER_PORT=8080
DEBUG_LOGGING=true                       # Enable verbose logging
```

For production, use `.env.production` with:
- Real TLS certificates
- Specific CORS origins (no wildcards)
- Strong secrets (generated with `openssl`)
- `QUICUI_ENVIRONMENT=production` (enforces HTTPS)

---

## 📊 What's Running Locally

### Backend Server
- **Host**: 0.0.0.0 (accessible on http://localhost:8080)
- **Port**: 8080 (default, configurable via `SERVER_PORT`)
- **Protocol**: HTTP (HTTPS disabled in development mode)
- **Security**: All middleware active (CORS, headers, validation)

### API Endpoints
```
GET    /health                           # Health check
POST   /api/v1/auth/register            # User registration
POST   /api/v1/auth/login               # User login
GET    /api/v1/apps                     # List apps
POST   /api/v1/apps                     # Create app
GET    /api/v1/apps/{appId}             # Get app details
GET    /api/v1/apps/{appId}/patches     # List patches
POST   /api/v1/apps/{appId}/patches     # Upload patch
GET    /api/v1/apps/{appId}/metrics     # Get metrics
POST   /api/v1/rollouts                 # Create rollout
GET    /api/v1/rollouts                 # List rollouts
```

### Security Features (Active)
- ✅ CORS validation (whitelist-based)
- ✅ Security headers injection
- ✅ Request size validation
- ✅ Content-Type validation
- ✅ JWT/API key support (middleware ready)
- ✅ Audit logging (configured)

### Database
- **Type**: PostgreSQL
- **Connection**: localhost:5432
- **Database**: quicui_dev
- **User**: postgres
- **Password**: postgres (development only)

---

## 🛑 Stopping the Backend

Simply press `Ctrl+C` in the terminal where it's running:

```
^C
🛑 Backend stopped
```

---

## 🆘 Troubleshooting

### Issue: "dart: command not found"
**Solution**: Install Dart SDK from https://dart.dev/get-dart

### Issue: "Connection refused: postgresql"
**Solution**: Start PostgreSQL
```bash
# Option 1: Docker
docker run -d -p 5432:5432 -e POSTGRES_PASSWORD=postgres postgres:15

# Option 2: Homebrew (macOS)
brew services start postgresql

# Option 3: Check if running
psql -U postgres -h localhost -c "SELECT 1"
```

### Issue: "CORS: Origin not allowed"
**Solution**: Check `.env.local` CORS origins or add your frontend URL:
```bash
# Edit .env.local
QUICUI_ALLOWED_ORIGINS=http://localhost:3000,http://localhost:3001

# Then reload and restart
source .env.local
dart run
```

### Issue: "Configuration validation failed"
**Solution**: Run verification script for detailed diagnostics:
```bash
dart run bin/verify_security_config.dart
```

### Issue: "Port 8080 already in use"
**Solution**: Use different port:
```bash
export SERVER_PORT=9090
dart run
```

---

## 📈 What's Next

### Monitor the Backend
```bash
# Watch logs in real-time
# (already displayed in terminal where backend is running)
```

### Test with Frontend
```bash
# Add your frontend URL to CORS origins in .env.local
QUICUI_ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080

# Reload environment and restart backend
```

### Deploy to Production
See `DEPLOYMENT_GUIDE.md` for:
- Docker containerization
- Kubernetes deployment
- Cloud platform setup (AWS, Azure, GCP)
- TLS certificate configuration
- Security hardening

---

## ✅ Verification Checklist

- [x] Backend code is production-ready
- [x] All security middleware active
- [x] 40+ tests passing
- [x] Configuration validated
- [x] Local environment ready
- [x] Quick start script provided

**Status**: ✅ Ready to deploy and test locally!

---

## 📚 Additional Resources

- **Full Deployment Guide**: `docs/DEPLOYMENT_GUIDE.md`
- **Security Configuration**: `docs/PHASE_5_1B_COMPLETION.md`
- **API Documentation**: `packages/quicui_backend/lib/quicui_backend.dart`
- **Security Audit**: `docs/PHASE_5_SECURITY_AUDIT.md`
- **Test Coverage**: `packages/quicui_backend/test/`

---

**Ready to deploy?**

```bash
bash /Users/admin/Documents/quicui2/packages/quicui_backend/bin/deploy_local.sh
```

**Happy coding! 🚀**
