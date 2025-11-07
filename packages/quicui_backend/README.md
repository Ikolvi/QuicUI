# QuicUI Backend

REST API server for QuicUI Code Push system - manages over-the-air updates for Flutter applications.

## Features

- 🚀 **Patch Management** - Upload, download, and manage code patches
- 📦 **Compression Support** - xz, bzip2, gzip compression
- 🔐 **Security** - SHA-256 validation, secure patch delivery
- 🌐 **CORS Enabled** - Ready for web and mobile clients
- 📊 **Analytics** - Track patch downloads and app versions
- ☁️ **Cloud Ready** - Optimized for Render.com deployment

## Quick Start

### Local Development

```bash
# Install dependencies
dart pub get

# Run server
dart run bin/server.dart
```

Server runs on `http://localhost:8080`

### Docker (Local)

```bash
# Build
docker build -t quicui-backend .

# Run
docker run -p 8080:8080 -e PORT=8080 quicui-backend

# Test
curl http://localhost:8080/api/v1/patches
```

### Render.com Deployment

See [DEPLOYMENT.md](./DEPLOYMENT.md) for detailed instructions.

**Quick Deploy:**
1. Push to GitHub (`develop` branch)
2. Render.com auto-detects `render.yaml`
3. Automatic build and deployment

## API Endpoints

### Patches

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/patches` | List all patches |
| POST | `/api/v1/patches/check` | Check for available patches |
| POST | `/api/v1/patches/download/{patchId}` | Download patch |
| POST | `/api/v1/patches` | Upload new patch |
| DELETE | `/api/v1/patches/{patchId}` | Delete patch |

### Example: Check for Patches

```bash
curl -X POST http://localhost:8080/api/v1/patches/check \
  -H "Content-Type: application/json" \
  -d '{
    "appId": "com.example.app",
    "currentVersion": "1.0.0",
    "supportedCompressions": ["xz", "bz2", "gz"]
  }'
```

**Response:**
```json
{
  "updateAvailable": true,
  "patchId": "patch-v2.0.0",
  "version": "2.0.0",
  "downloadUrl": "/api/v1/patches/download/patch-v2.0.0",
  "size": 1048576,
  "hash": "abc123...",
  "compression": "xz"
}
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PORT` | Server port | `8080` |
| `RENDER` | Render.com indicator | - |
| `RENDER_EXTERNAL_URL` | Public URL | - |
| `ENVIRONMENT` | Environment name | `development` |
| `LOG_LEVEL` | Logging level | `info` |

## Architecture

```
QuicUI Backend (Dart/Shelf)
├── bin/server.dart          # Main server
├── Dockerfile               # Docker configuration
├── render.yaml              # Render.com config
└── pubspec.yaml             # Dependencies

Dependencies:
- shelf: HTTP server framework
- shelf_router: API routing
- crypto: SHA-256 hashing
- postgres: Database (optional)
```

## Development

**Requirements:**
- Dart SDK ^3.0.0
- Docker (optional)

**Dependencies:**
```yaml
shelf: ^1.4.2
shelf_router: ^1.1.4
crypto: ^3.0.6
http: ^1.5.0
```

**Run Tests:**
```bash
dart test
```

**Format Code:**
```bash
dart format .
```

**Analyze:**
```bash
dart analyze
```

## Deployment

### Render.com (Recommended)

**Configuration:** `render.yaml`
- **Runtime:** Docker
- **Build:** Automatic (Dockerfile)
- **Deploy:** Auto-deploy from `main` branch
- **Health Check:** `/api/v1/patches`
- **Repository:** https://github.com/Ikolvi/quicui-backend

### Manual Deployment

```bash
# Build Docker image
docker build -t quicui-backend .

# Push to registry
docker tag quicui-backend:latest your-registry/quicui-backend:latest
docker push your-registry/quicui-backend:latest

# Deploy to cloud provider
kubectl apply -f k8s/deployment.yaml
```

## Security

- ✅ CORS enabled for API access
- ✅ SHA-256 hash validation
- ✅ Environment-based configuration
- ✅ No hardcoded secrets
- ⚠️ Add authentication for production use

## Monitoring

**Logs:**
- Local: Console output
- Render.com: Dashboard logs

**Health Check:**
```bash
curl https://your-app.onrender.com/api/v1/patches
```

## Roadmap

- [ ] Add authentication (JWT/API keys)
- [ ] Implement database persistence (PostgreSQL)
- [ ] Add rate limiting
- [ ] Implement patch rollback
- [ ] Add analytics dashboard
- [ ] WebSocket support for real-time updates

## License

MIT License - See repository for details.

## Support

- **Issues:** https://github.com/Ikolvi/quicui-backend/issues
- **Docs:** [DEPLOYMENT.md](./DEPLOYMENT.md)
- **Repository:** https://github.com/Ikolvi/quicui-backend

---

**Part of QuicUI Code Push** - Commercial SaaS for Flutter OTA updates
