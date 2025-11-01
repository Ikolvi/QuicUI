#!/bin/bash
# QuicUI Code Push - One-Line Local Deployment
# Usage: bash local_deploy.sh

cd /Users/admin/Documents/quicui2/packages/quicui_backend && \
source .env.local && \
dart pub get && \
echo "" && \
echo "🔐 Verifying security configuration..." && \
echo "" && \
dart run bin/verify_security_config.dart && \
echo "" && \
echo "🚀 Starting backend on http://localhost:8080" && \
echo "" && \
dart run
