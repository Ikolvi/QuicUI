# Deployment Guide - QuicUI v1.0.0

**Last Updated**: November 1, 2025  
**Version**: 1.0.0  
**Status**: Production Ready ✅

## Quick Start

```bash
# Development
cd packages/quicui_backend
dart run lib/quicui_backend.dart

# Production (Docker)
docker build -t quicui:1.0.0 .
docker run -p 8080:8080 \
  -e ENVIRONMENT=production \
  -e DATABASE_URL=postgres://... \
  quicui:1.0.0
```

---

## Table of Contents

1. [Local Development](#local-development)
2. [Docker Deployment](#docker-deployment)
3. [Production Environment](#production-environment)
4. [Security Hardening](#security-hardening)
5. [Monitoring & Observability](#monitoring--observability)
6. [Troubleshooting](#troubleshooting)
7. [Rollback Procedures](#rollback-procedures)

---

## Local Development

### Prerequisites

```bash
# Check Dart version
dart --version
# Output: Dart SDK version 3.2.0 or higher

# Check PostgreSQL
psql --version
# Output: psql (PostgreSQL) 14.0 or higher

# Optional: Check Redis
redis-cli --version
# Output: redis-cli 7.0.0 or higher
```

### Setup Steps

#### 1. Clone Repository

```bash
git clone https://github.com/Ikolvi/quicui2.git
cd quicui2
```

#### 2. Configure Environment

```bash
cd packages/quicui_backend

# Copy example environment
cp .env.example .env.local

# Edit with your settings
cat > .env.local << 'EOF'
ENVIRONMENT=development
DATABASE_URL=postgres://localhost:5432/quicui
REDIS_URL=redis://localhost:6379
API_KEY=dev-key-123
LOG_LEVEL=debug
ENABLE_CORS=true
CORS_ORIGINS=http://localhost:3000,http://localhost:8000
EOF
```

#### 3. Install Dependencies

```bash
dart pub get

# Verify packages installed
dart pub outdated
```

#### 4. Set Up Database

```bash
# Create database
createdb quicui

# Run migrations (if any)
dart run lib/migrations/migrate.dart

# Verify connection
psql -d quicui -c "SELECT version();"
```

#### 5. Start Backend

```bash
# Start server
dart run lib/quicui_backend.dart

# Output:
# [INFO] QuicUI Backend v1.0.0 starting...
# [INFO] Database connected: postgres://localhost:5432/quicui
# [INFO] Cache service initialized
# [INFO] Server listening on http://0.0.0.0:8080
# [INFO] Ready to accept requests
```

#### 6. Verify Deployment

```bash
# Check health endpoint
curl http://localhost:8080/api/v1/health

# Expected response:
# {
#   "status": "operational",
#   "timestamp": "2025-11-01T12:00:00Z",
#   "version": "1.0.0",
#   "uptime_ms": 1234
# }

# Check authentication
curl -X POST http://localhost:8080/api/v1/authenticate \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"password"}'
```

### Local Development Commands

```bash
# Run tests
dart test

# Format code
dart format lib/

# Analyze code
dart analyze

# Get package updates
dart pub upgrade

# Watch for changes (requires `dart_watch` package)
dart pub global activate dart_watch
dart_watch
```

---

## Docker Deployment

### Prerequisites

```bash
# Check Docker installation
docker --version
# Output: Docker version 20.10.0 or higher

docker-compose --version
# Output: Docker Compose version 1.29.0 or higher
```

### Build Docker Image

#### Option 1: Using Dockerfile

```bash
# From project root
cd packages/quicui_backend

# Build image
docker build -t quicui:1.0.0 .

# Verify image
docker images | grep quicui

# Output:
# quicui                      1.0.0        abc123def456   2 minutes ago   450MB
```

#### Option 2: Using Docker Compose

```bash
# From project root
docker-compose build

# Output:
# Building quicui_backend
# Step 1/10 : FROM google/dart:latest
# ...
# Successfully tagged quicui:1.0.0
```

### Run Docker Container

#### Option 1: Single Container

```bash
# Basic run
docker run -p 8080:8080 quicui:1.0.0

# Run with environment variables
docker run -p 8080:8080 \
  -e ENVIRONMENT=production \
  -e DATABASE_URL=postgres://db:5432/quicui \
  -e REDIS_URL=redis://cache:6379 \
  -e API_KEY=prod-key-123 \
  -e LOG_LEVEL=info \
  quicui:1.0.0

# Run in background
docker run -d \
  --name quicui-backend \
  -p 8080:8080 \
  -e ENVIRONMENT=production \
  -e DATABASE_URL=postgres://db:5432/quicui \
  quicui:1.0.0

# Check container status
docker ps | grep quicui
```

#### Option 2: Using Docker Compose

```yaml
# docker-compose.yml
version: '3.8'

services:
  db:
    image: postgres:14
    environment:
      POSTGRES_DB: quicui
      POSTGRES_USER: quicui
      POSTGRES_PASSWORD: secret
    ports:
      - "5432:5432"
    volumes:
      - db_data:/var/lib/postgresql/data

  redis:
    image: redis:7
    ports:
      - "6379:6379"

  backend:
    build: ./packages/quicui_backend
    ports:
      - "8080:8080"
    environment:
      ENVIRONMENT: production
      DATABASE_URL: postgres://quicui:secret@db:5432/quicui
      REDIS_URL: redis://redis:6379
      API_KEY: prod-key-123
      LOG_LEVEL: info
    depends_on:
      - db
      - redis

volumes:
  db_data:
```

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f backend

# Stop all services
docker-compose down
```

### Container Management

```bash
# View running containers
docker ps

# View container logs
docker logs quicui-backend

# Follow logs (live)
docker logs -f quicui-backend

# Execute command in container
docker exec quicui-backend dart --version

# Stop container
docker stop quicui-backend

# Restart container
docker restart quicui-backend

# Remove container
docker rm quicui-backend

# View container stats
docker stats quicui-backend
```

---

## Production Environment

### Environment Configuration

#### Create .env.production

```bash
# .env.production

# Application
ENVIRONMENT=production
API_KEY=your-production-api-key-here

# Database
DATABASE_URL=postgres://quicui_prod_user:secure_password@prod-db-host:5432/quicui_prod

# Cache
REDIS_URL=redis://:cache_password@prod-redis-host:6379

# Logging
LOG_LEVEL=info

# Security
ENABLE_CORS=true
CORS_ORIGINS=https://yourdomain.com,https://api.yourdomain.com

# Performance
RESPONSE_CACHE_TTL=120
CONNECTION_POOL_SIZE=50
```

#### Load Environment Variables

```bash
# In Docker
docker run -p 8080:8080 \
  --env-file .env.production \
  quicui:1.0.0

# In Kubernetes
kubectl create secret generic quicui-env --from-file=.env.production
kubectl set env deployment/quicui --from=secret/quicui-env
```

### Database Setup for Production

```bash
# 1. Create dedicated database user
sudo -u postgres psql << 'EOF'
CREATE USER quicui_prod_user WITH PASSWORD 'secure_password';
CREATE DATABASE quicui_prod OWNER quicui_prod_user;
GRANT CONNECT ON DATABASE quicui_prod TO quicui_prod_user;
GRANT USAGE ON SCHEMA public TO quicui_prod_user;
GRANT CREATE ON SCHEMA public TO quicui_prod_user;
EOF

# 2. Run migrations
export DATABASE_URL=postgres://quicui_prod_user:secure_password@localhost:5432/quicui_prod
dart run lib/migrations/migrate.dart

# 3. Set up backups
pg_dump quicui_prod > backup_$(date +%Y%m%d_%H%M%S).sql

# 4. Set up automated backups (cron)
# 0 2 * * * pg_dump quicui_prod | gzip > /backups/quicui_prod_$(date +\%Y\%m\%d_\%H\%M\%S).sql.gz
```

### SSL/TLS Configuration

```bash
# Generate self-signed certificate (development)
openssl req -x509 -newkey rsa:4096 \
  -keyout key.pem \
  -out cert.pem \
  -days 365 -nodes

# For production, use Let's Encrypt with Certbot
sudo apt-get install certbot python3-certbot-nginx
sudo certbot certonly --standalone -d yourdomain.com

# Configure Nginx reverse proxy with SSL
cat > /etc/nginx/sites-available/quicui << 'EOF'
upstream quicui_backend {
    server 127.0.0.1:8080;
}

server {
    listen 80;
    server_name yourdomain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name yourdomain.com;

    ssl_certificate /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;

    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "DENY" always;
    add_header X-Content-Type-Options "nosniff" always;

    location / {
        proxy_pass http://quicui_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# Enable site
sudo ln -s /etc/nginx/sites-available/quicui /etc/nginx/sites-enabled/
sudo systemctl restart nginx
```

### Systemd Service (Linux)

```bash
# Create systemd service
sudo tee /etc/systemd/system/quicui.service << 'EOF'
[Unit]
Description=QuicUI Backend v1.0.0
After=network.target

[Service]
Type=simple
User=quicui
WorkingDirectory=/opt/quicui
EnvironmentFile=/opt/quicui/.env.production
ExecStart=/usr/bin/dart run lib/quicui_backend.dart
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable quicui
sudo systemctl start quicui

# Check status
sudo systemctl status quicui

# View logs
sudo journalctl -u quicui -f
```

---

## Security Hardening

### Pre-Deployment Security Checklist

- [ ] Environment variables configured for production
- [ ] Database credentials in secure storage (secrets manager)
- [ ] HTTPS/TLS enabled with valid certificates
- [ ] Firewall configured (allow only necessary ports)
- [ ] Rate limiting tiers configured for your load
- [ ] CORS origins whitelist updated
- [ ] Security headers validated in production
- [ ] Error tracing enabled for debugging
- [ ] Monitoring and alerting configured
- [ ] Incident response procedures documented

### Firewall Configuration

```bash
# UFW (Ubuntu)
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw deny 5432/tcp  # Deny PostgreSQL from external
sudo ufw enable

# iptables
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 5432 -j DROP
sudo iptables-save > /etc/iptables/rules.v4
```

### Network Security

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
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: ingress
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: postgres
    ports:
    - protocol: TCP
      port: 5432
  - to:
    - podSelector:
        matchLabels:
          app: redis
    ports:
    - protocol: TCP
      port: 6379
```

### Access Control

```bash
# Restrict file permissions
chmod 700 /opt/quicui
chmod 600 /opt/quicui/.env.production
chmod 600 /opt/quicui/.ssh/id_rsa

# SSH key-based authentication only
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl restart sshd

# Audit logging
auditctl -w /opt/quicui/ -p wa -k quicui_changes
```

---

## Monitoring & Observability

### Health Checks

```bash
# Basic health check
curl http://localhost:8080/api/v1/health

# With authentication token
curl -H "Authorization: Bearer YOUR_TOKEN" \
     http://localhost:8080/api/v1/health

# Automated monitoring
# Set up in your monitoring tool (Prometheus, Grafana, CloudWatch, etc.)
```

### Logging Configuration

```dart
// Configure logging level in production
import 'package:logging/logging.dart';

void main() {
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
}
```

### Metrics Collection

```bash
# Collect metrics endpoint
curl http://localhost:8080/api/v1/analytics

# Parse response for monitoring
{
  "requests_total": 10234,
  "requests_per_second": 12.5,
  "avg_response_time_ms": 45,
  "error_rate": 0.02,
  "cache_hit_rate": 0.78,
  "db_connection_pool_usage": 0.45
}
```

### Prometheus Integration

```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'quicui'
    static_configs:
      - targets: ['localhost:8080']
    metrics_path: '/api/v1/metrics'
    scrape_interval: 15s
```

### Grafana Dashboards

Create dashboard for:
- Request latency (P50, P95, P99)
- Error rates by endpoint
- Rate limit hits
- Cache hit rate
- Database connection pool utilization
- Memory and CPU usage

---

## Troubleshooting

### Common Issues

#### Issue: Port Already in Use

```bash
# Find process using port 8080
lsof -i :8080

# Kill process
kill -9 <PID>

# Or use different port
dart run lib/quicui_backend.dart --port 8081
```

#### Issue: Database Connection Failed

```bash
# Verify connection string
echo $DATABASE_URL

# Test connection
psql $DATABASE_URL -c "SELECT 1;"

# Check PostgreSQL service
sudo systemctl status postgresql

# Start if not running
sudo systemctl start postgresql
```

#### Issue: High Memory Usage

```bash
# Check memory usage
docker stats quicui-backend

# Reduce cache size
RESPONSE_CACHE_MAX_SIZE=5000  # Default: 10000

# Reduce connection pool size
CONNECTION_POOL_SIZE=25  # Default: 50

# Restart service
docker restart quicui-backend
```

#### Issue: Slow Response Times

```bash
# Check application logs
docker logs -f quicui-backend | grep -i slow

# Monitor resource usage
docker stats quicui-backend

# Check database queries
psql -d quicui -c "SELECT * FROM pg_stat_statements ORDER BY mean_time DESC LIMIT 10;"

# Optimize queries or increase resources
```

### Debug Mode

```bash
# Enable debug logging
LOG_LEVEL=debug dart run lib/quicui_backend.dart

# View debug output
docker logs -f quicui-backend | grep "DEBUG"
```

---

## Rollback Procedures

### Version Rollback

```bash
# Tag current version before update
git tag v1.0.0-production

# If issues occur, rollback to previous version
git checkout v0.9.9
docker build -t quicui:0.9.9 .
docker-compose up -d

# Or with Kubernetes
kubectl rollout history deployment/quicui
kubectl rollout undo deployment/quicui --to-revision=1
```

### Database Rollback

```bash
# Backup current state
pg_dump quicui_prod > backup_before_migration.sql

# If migration fails, restore
psql quicui_prod < backup_previous.sql

# Verify data integrity
psql quicui_prod -c "SELECT COUNT(*) FROM products;"
```

### Docker Rollback

```bash
# Stop current container
docker-compose down

# Use previous image
docker-compose.yml (change version)
docker-compose up -d

# Verify
curl http://localhost:8080/api/v1/health
```

---

## Upgrade Path

### From v0.x to v1.0.0

1. **Backup**: Create database and Docker image backups
2. **Test**: Test new version in staging environment
3. **Deploy**: Follow blue-green deployment strategy
4. **Verify**: Run health checks and smoke tests
5. **Monitor**: Watch error rates and latency for 24 hours

### Blue-Green Deployment

```bash
# Run current version (blue)
docker-compose -f docker-compose.blue.yml up -d

# Deploy new version (green)
docker-compose -f docker-compose.green.yml up -d

# Test green deployment
curl http://localhost:8081/api/v1/health

# Switch traffic to green (via load balancer or DNS)
# If issues occur, switch back to blue

# Once verified, remove blue
docker-compose -f docker-compose.blue.yml down
```

---

## Support & Documentation

- **API Documentation**: See [API_DOCUMENTATION.md](./API_DOCUMENTATION.md)
- **Security Audit**: See [SECURITY_AUDIT_REPORT.md](./SECURITY_AUDIT_REPORT.md)
- **Release Notes**: See [RELEASE_NOTES_v1.0.0.md](./RELEASE_NOTES_v1.0.0.md)
- **Issues**: https://github.com/Ikolvi/quicui2/issues
- **Security**: security@quicui.com

---

**Last Updated**: November 1, 2025  
**Version**: 1.0.0  
**Status**: Production Ready ✅
