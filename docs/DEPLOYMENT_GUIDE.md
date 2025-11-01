# QuicUI Code Push Backend - Deployment Guide

**Phase 5.1b: Critical Security Fixes for v1.0.0 Production Release**

## Overview

This guide provides comprehensive instructions for deploying the QuicUI Code Push Backend to production with all critical security hardening implemented.

## Prerequisites

- Dart 3.0+ SDK
- PostgreSQL 12+ database
- TLS/SSL certificates from a trusted Certificate Authority (e.g., Let's Encrypt)
- Docker (optional, for containerized deployment)
- Kubernetes (optional, for cloud-native deployment)

## Security Checklist

Before deploying to production, complete ALL critical items:

- [ ] TLS/SSL certificates obtained and validated
- [ ] CORS origins configured for your domain(s)
- [ ] Environment variables documented and set
- [ ] Database credentials rotated and secured
- [ ] JWT secret key generated and stored securely
- [ ] Security configuration verified with `dart run bin/verify_security_config.dart`
- [ ] All tests passing: `dart test`
- [ ] Database backups configured
- [ ] Monitoring and logging configured

## Environment Configuration

### Required Variables (Production)

```bash
# Environment
QUICUI_ENVIRONMENT=production

# CORS Origins (comma-separated, NO WILDCARDS in production)
QUICUI_ALLOWED_ORIGINS=https://app.example.com,https://api.example.com

# TLS/HTTPS Configuration
QUICUI_TLS_CERT_PATH=/etc/ssl/certs/server.crt
QUICUI_TLS_KEY_PATH=/etc/ssl/private/server.key

# Database Configuration
DATABASE_HOST=db.internal.example.com
DATABASE_PORT=5432
DATABASE_NAME=quicui_production
DATABASE_USER=quicui_user
DATABASE_PASSWORD=<securely-generated-password>

# Authentication
JWT_SECRET_KEY=<securely-generated-32-byte-key>
API_KEY_SECRET=<securely-generated-api-key>
```

### Generating Secure Secrets

```bash
# Generate JWT secret (32 bytes = 256 bits)
JWT_SECRET_KEY=$(openssl rand -base64 32)
echo "JWT_SECRET_KEY=$JWT_SECRET_KEY"

# Generate API key secret
API_KEY_SECRET=$(openssl rand -hex 32)
echo "API_KEY_SECRET=$API_KEY_SECRET"

# Generate database password (16 bytes minimum)
DATABASE_PASSWORD=$(openssl rand -base64 16)
echo "DATABASE_PASSWORD=$DATABASE_PASSWORD"
```

### .env.production File

```bash
# Create .env.production in the backend directory
cat > packages/quicui_backend/.env.production <<EOF
QUICUI_ENVIRONMENT=production
QUICUI_ALLOWED_ORIGINS=https://app.example.com,https://api.example.com
QUICUI_TLS_CERT_PATH=/etc/ssl/certs/server.crt
QUICUI_TLS_KEY_PATH=/etc/ssl/private/server.key
DATABASE_HOST=db.example.com
DATABASE_PORT=5432
DATABASE_NAME=quicui_production
DATABASE_USER=quicui_user
DATABASE_PASSWORD=$DATABASE_PASSWORD
JWT_SECRET_KEY=$JWT_SECRET_KEY
API_KEY_SECRET=$API_KEY_SECRET
EOF

# Restrict file permissions
chmod 600 packages/quicui_backend/.env.production
```

## Deployment Methods

### Method 1: Local Server Deployment

Suitable for small-scale deployments or testing environments.

#### Prerequisites
- Dart 3.0+ installed
- PostgreSQL accessible from the server
- TLS certificates installed on the server

#### Steps

```bash
# 1. Clone repository
git clone https://github.com/Ikolvi/QuicUICodepush.git
cd QuicUICodepush

# 2. Navigate to backend directory
cd packages/quicui_backend

# 3. Set environment variables
source .env.production

# 4. Verify configuration
dart run bin/verify_security_config.dart

# 5. Get dependencies
dart pub get

# 6. Run tests
dart test

# 7. Start backend
dart run

# The server will start on port 8080 with HTTPS enabled
```

#### Running as a Service

For long-term production deployments, run the backend as a systemd service:

```bash
# Create systemd service file
sudo cat > /etc/systemd/system/quicui-backend.service <<EOF
[Unit]
Description=QuicUI Code Push Backend
After=network.target

[Service]
Type=simple
User=quicui
WorkingDirectory=/opt/quicui-backend
EnvironmentFile=/opt/quicui-backend/.env.production
ExecStart=/opt/quicui-backend/dart-3.0/bin/dart run quicui_backend
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable quicui-backend
sudo systemctl start quicui-backend

# Check status
sudo systemctl status quicui-backend

# View logs
sudo journalctl -u quicui-backend -f
```

### Method 2: Docker Deployment

Containerized deployment for scalability and consistency.

#### Prerequisites
- Docker installed
- Docker registry (Docker Hub, AWS ECR, etc.)
- Container orchestration platform (optional: Kubernetes)

#### Dockerfile

```dockerfile
# Dockerfile.production
FROM google/dart:3.0 as builder

WORKDIR /app
COPY . .

RUN cd packages/quicui_backend && \
    dart pub get && \
    dart test

# Production runtime
FROM google/dart:3.0-runtime

WORKDIR /app
COPY --from=builder /app/packages/quicui_backend /app

EXPOSE 8080

# Load environment variables and start
ENV QUICUI_ENVIRONMENT=production
CMD ["dart", "run"]
```

#### Building and Running Docker Image

```bash
# 1. Build Docker image
docker build -f Dockerfile.production -t quicui-backend:1.0.0 .

# 2. Tag for registry
docker tag quicui-backend:1.0.0 myregistry.azurecr.io/quicui-backend:1.0.0

# 3. Push to registry
docker push myregistry.azurecr.io/quicui-backend:1.0.0

# 4. Run container locally
docker run \
  --env-file .env.production \
  -v /path/to/certs:/etc/ssl/certs:ro \
  -v /path/to/keys:/etc/ssl/private:ro \
  -p 8080:8080 \
  quicui-backend:1.0.0

# 5. Run with Docker Compose
cat > docker-compose.yml <<EOF
version: '3.8'

services:
  backend:
    image: myregistry.azurecr.io/quicui-backend:1.0.0
    ports:
      - "8080:8080"
    environment:
      QUICUI_ENVIRONMENT: production
      DATABASE_HOST: postgres
      DATABASE_USER: quicui_user
    volumes:
      - /etc/ssl/certs:/etc/ssl/certs:ro
      - /etc/ssl/private:/etc/ssl/private:ro
    depends_on:
      - postgres

  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: quicui_production
      POSTGRES_USER: quicui_user
      POSTGRES_PASSWORD: ${DATABASE_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
EOF

# Start with Docker Compose
docker-compose up -d
```

### Method 3: Kubernetes Deployment

Enterprise-grade cloud-native deployment with auto-scaling and high availability.

#### ConfigMap for Non-Sensitive Data

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: quicui-backend-config
  namespace: quicui
data:
  QUICUI_ENVIRONMENT: "production"
  QUICUI_ALLOWED_ORIGINS: "https://app.example.com,https://api.example.com"
  DATABASE_HOST: "postgres.quicui.svc.cluster.local"
  DATABASE_PORT: "5432"
  DATABASE_NAME: "quicui_production"
  DATABASE_USER: "quicui_user"
  SERVER_PORT: "8080"
```

#### Secret for Sensitive Data

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: quicui-backend-secrets
  namespace: quicui
type: Opaque
stringData:
  DATABASE_PASSWORD: "<base64-encoded-password>"
  JWT_SECRET_KEY: "<base64-encoded-jwt-secret>"
  API_KEY_SECRET: "<base64-encoded-api-key>"
```

#### TLS Certificate Secret

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: quicui-tls-certs
  namespace: quicui
type: kubernetes.io/tls
data:
  tls.crt: <base64-encoded-certificate>
  tls.key: <base64-encoded-key>
```

#### Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: quicui-backend
  namespace: quicui
spec:
  replicas: 3
  selector:
    matchLabels:
      app: quicui-backend
  template:
    metadata:
      labels:
        app: quicui-backend
    spec:
      containers:
      - name: backend
        image: myregistry.azurecr.io/quicui-backend:1.0.0
        ports:
        - containerPort: 8080
          name: http
        envFrom:
        - configMapRef:
            name: quicui-backend-config
        - secretRef:
            name: quicui-backend-secrets
        env:
        - name: QUICUI_TLS_CERT_PATH
          value: /etc/tls/certs/tls.crt
        - name: QUICUI_TLS_KEY_PATH
          value: /etc/tls/certs/tls.key
        volumeMounts:
        - name: tls-certs
          mountPath: /etc/tls/certs
          readOnly: true
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
            scheme: HTTPS
          initialDelaySeconds: 10
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 8080
            scheme: HTTPS
          initialDelaySeconds: 5
          periodSeconds: 5
      volumes:
      - name: tls-certs
        secret:
          secretName: quicui-tls-certs
```

#### Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: quicui-backend
  namespace: quicui
spec:
  type: LoadBalancer
  ports:
  - port: 443
    targetPort: 8080
    protocol: TCP
    name: https
  selector:
    app: quicui-backend
```

#### Deploy to Kubernetes

```bash
# Create namespace
kubectl create namespace quicui

# Create ConfigMap
kubectl apply -f configmap.yaml

# Create Secret
kubectl apply -f secret.yaml

# Create TLS Certificate Secret
kubectl create secret tls quicui-tls-certs \
  --cert=path/to/server.crt \
  --key=path/to/server.key \
  -n quicui

# Deploy
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml

# Check deployment status
kubectl get pods -n quicui
kubectl get svc -n quicui

# Check logs
kubectl logs -n quicui -l app=quicui-backend
```

## Post-Deployment Verification

### 1. Verify Configuration

```bash
# Run security configuration check
curl -X POST https://your-domain.com/health

# Should return 200 OK with health check response
```

### 2. Test HTTPS

```bash
# Verify HTTPS is working
curl -vI https://your-domain.com/health

# Should show TLS handshake and valid certificate
```

### 3. Test CORS Headers

```bash
# Test CORS preflight
curl -X OPTIONS https://your-domain.com/api/v1/auth/login \
  -H "Origin: https://app.example.com" \
  -H "Access-Control-Request-Method: POST" \
  -vI

# Should return 200 with CORS headers
```

### 4. Verify Security Headers

```bash
# Check security headers
curl -I https://your-domain.com/api/v1/auth/login

# Should include:
# Strict-Transport-Security: max-age=31536000
# X-Content-Type-Options: nosniff
# X-Frame-Options: DENY
# Content-Security-Policy: ...
```

### 5. Database Connectivity

```bash
# Check database logs for connection attempts
# From backend container/pod logs, should see successful DB connection
```

## Monitoring and Logging

### Structured Logging

The backend outputs JSON-formatted logs. Example:

```json
{
  "timestamp": "2024-11-02T12:34:56.789Z",
  "level": "INFO",
  "message": "Request received",
  "method": "POST",
  "path": "/api/v1/auth/login",
  "statusCode": 200,
  "duration": "125ms"
}
```

### Log Aggregation

Configure log shipping to centralized logging:

- **ELK Stack**: Elasticsearch, Logstash, Kibana
- **Splunk**: Enterprise logging and monitoring
- **CloudWatch**: AWS native logging
- **Azure Monitor**: Azure native monitoring

### Health Checks

The backend provides health check endpoints:

```bash
# Health check endpoint (always available)
GET /health

# Kubernetes-specific
livenessProbe: /health
readinessProbe: /health
```

## Backup and Recovery

### Database Backup

```bash
# Daily automated backup (add to crontab)
0 2 * * * pg_dump -Fc postgresql://user:pass@db.example.com/quicui_prod > /backups/quicui_$(date +\%Y\%m\%d).dump

# Restore from backup
pg_restore -d quicui_production /backups/quicui_20241102.dump
```

### Secret Backup

```bash
# Backup secrets in vault (e.g., Vault, Azure Key Vault)
# Never commit secrets to version control
```

## Scaling and Performance

### Horizontal Scaling

```bash
# Docker: Run multiple containers behind a load balancer
docker run -d --name backend-1 quicui-backend:1.0.0
docker run -d --name backend-2 quicui-backend:1.0.0
docker run -d --name backend-3 quicui-backend:1.0.0

# Kubernetes: Increase replicas
kubectl scale deployment quicui-backend --replicas=5 -n quicui
```

### Load Balancing

- **Nginx**: Reverse proxy with SSL termination
- **HAProxy**: High performance load balancer
- **Cloud LB**: AWS ELB, Azure LB, GCP Load Balancer
- **Kubernetes Ingress**: Native K8s ingress controller

### Caching

- Use Redis for session caching
- Implement CDN for static content
- Cache JWT validation results

## Troubleshooting

### Common Issues

#### Issue: CORS Origin Not Allowed

**Solution**: Verify `QUICUI_ALLOWED_ORIGINS` environment variable:
```bash
echo $QUICUI_ALLOWED_ORIGINS
# Should match your frontend domain
```

#### Issue: TLS Certificate Not Found

**Solution**: Verify certificate paths:
```bash
ls -la /etc/ssl/certs/server.crt
ls -la /etc/ssl/private/server.key

# Check file permissions
# Should be readable by the application process user
```

#### Issue: Database Connection Refused

**Solution**: Check database connectivity:
```bash
# From backend container
nc -zv $DATABASE_HOST $DATABASE_PORT

# Or use psql to test
psql -h $DATABASE_HOST -U $DATABASE_USER -d $DATABASE_NAME
```

#### Issue: High Memory Usage

**Solution**: Check for connection leaks:
```bash
# Monitor connections
docker stats

# Or in Kubernetes
kubectl top pods -n quicui
```

## Maintenance

### Security Updates

```bash
# Check for dependency updates
dart pub upgrade

# Review and test before deploying
dart test

# Deploy updated version
# Follow deployment procedure above
```

### Certificate Renewal

```bash
# Set up automatic renewal (e.g., with certbot for Let's Encrypt)
# Certificates should be renewed 30 days before expiration

# Manual renewal example:
certbot renew --force-renewal

# Restart backend after certificate renewal
systemctl restart quicui-backend
```

### Log Rotation

```bash
# Configure logrotate for application logs
cat > /etc/logrotate.d/quicui-backend <<EOF
/var/log/quicui-backend/*.log {
    daily
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 quicui quicui
    sharedscripts
    postrotate
        systemctl reload quicui-backend > /dev/null 2>&1 || true
    endscript
}
EOF
```

## Support and Documentation

- **Repository**: https://github.com/Ikolvi/QuicUICodepush
- **Issues**: https://github.com/Ikolvi/QuicUICodepush/issues
- **Wiki**: https://github.com/Ikolvi/QuicUICodepush/wiki
- **Dart Documentation**: https://dart.dev/guides
- **Shelf Framework**: https://pub.dev/packages/shelf
- **PostgreSQL**: https://www.postgresql.org/docs/

## Version History

- **v1.0.0** (2024-11-02): Initial production release with critical security hardening
  - HTTPS/TLS enforcement
  - CORS configuration
  - Security headers middleware
  - Environment-based configuration
  - Comprehensive deployment documentation
