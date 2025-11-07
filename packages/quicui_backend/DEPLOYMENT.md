# QuicUI Backend Deployment Guide

## Render.com Deployment

### Prerequisites
- GitHub repository connected to Render.com
- Render.com account (free tier available)

### Automatic Deployment (Blueprint)

1. **Using render.yaml (Recommended)**
   - Render will auto-detect `render.yaml` in the repository
   - Push to `develop` branch triggers auto-deployment
   - Configuration in `render.yaml`

2. **Manual Setup**
   - Go to [Render Dashboard](https://dashboard.render.com)
   - Click "New +" → "Web Service"
   - Connect to `Ikolvi/quicui-backend` repository
   - Configure:
     * **Name**: `quicui-backend`
     * **Region**: Oregon (or closest to users)
     * **Branch**: `main`
     * **Runtime**: Docker
     * **Plan**: Free (or higher for production)

### Docker Configuration

**Multi-stage Build:**
- Stage 1: Build with full Dart SDK
- Stage 2: Minimal runtime image (from scratch)
- AOT compilation for optimal performance

**Environment Variables:**
- `PORT` - Auto-provided by Render.com
- `RENDER` - Auto-set to indicate Render environment
- `RENDER_EXTERNAL_URL` - Your public URL
- `ENVIRONMENT` - Set to "production" in render.yaml
- `LOG_LEVEL` - Set to "info" in render.yaml

### Health Checks

Render.com will ping: `https://your-app.onrender.com/api/v1/patches`

### Deployment Commands

**Build Command:** (Handled by Dockerfile)
```bash
dart pub get
dart compile exe bin/server.dart -o bin/server
```

**Start Command:** (Handled by Dockerfile)
```bash
/app/bin/server
```

### Local Docker Testing

**Build:**
```bash
cd packages/quicui_backend
docker build -t quicui-backend .
```

**Run:**
```bash
docker run -p 8080:8080 -e PORT=8080 quicui-backend
```

**Test:**
```bash
curl http://localhost:8080/api/v1/patches
```

### Deployment Process

1. **Push to GitHub:**
   ```bash
   git push origin main
   ```

2. **Render.com Auto-Deploy:**
   - Detects push to `main` branch
   - Pulls latest code
   - Builds Docker image
   - Deploys to production
   - Runs health checks

3. **Verify Deployment:**
   - Check Render dashboard for build logs
   - Test public URL: `https://quicui-backend.onrender.com/api/v1/patches`

### API Endpoints

All endpoints available at: `https://quicui-backend.onrender.com`

- `GET /api/v1/patches` - List all patches
- `POST /api/v1/patches/check` - Check for updates
- `POST /api/v1/patches/download/{patchId}` - Download patch
- `POST /api/v1/patches` - Upload new patch
- `DELETE /api/v1/patches/{patchId}` - Delete patch

### Monitoring

**Logs:**
- View in Render.com dashboard
- Real-time streaming available

**Metrics:**
- CPU/Memory usage in dashboard
- Request counts and response times

### Troubleshooting

**Build Failures:**
- Check Render logs for Dart pub errors
- Verify `pubspec.yaml` dependencies
- Ensure Dockerfile is in correct location

**Runtime Errors:**
- Check logs: `https://dashboard.render.com/web/[your-service]/logs`
- Verify environment variables
- Test health check endpoint

**Connection Issues:**
- Ensure CORS is enabled (already configured)
- Verify client uses correct URL
- Check firewall/network settings

### Cost Optimization

**Free Tier:**
- 750 hours/month free
- Spins down after 15 minutes of inactivity
- Cold start on next request (~30 seconds)

**Paid Tier ($7/month):**
- Always on (no cold starts)
- More CPU/memory
- Better for production use

### Production Checklist

- [ ] Environment variables configured
- [ ] Health check endpoint working
- [ ] CORS enabled for mobile clients
- [ ] Logging configured
- [ ] Database connected (if needed)
- [ ] Custom domain configured (optional)
- [ ] SSL/TLS enabled (automatic on Render)
- [ ] Monitoring setup
- [ ] Backup strategy (for patch files)

### Next Steps

1. Deploy to Render.com
2. Test all endpoints
3. Update mobile app to use production URL
4. Monitor performance and logs
5. Scale as needed

---

**Support:** For issues, check Render.com docs or GitHub issues at https://github.com/Ikolvi/quicui-backend/issues
