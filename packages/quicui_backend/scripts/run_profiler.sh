#!/bin/bash
# QuicUI Backend Performance Profiling Script
# Analyzes CPU, memory, and performance characteristics

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$SCRIPT_DIR/../.."

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║   QuicUI Backend Performance Profiling Tool                    ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

echo "🚀 Running performance analysis..."
echo ""

cd "$BACKEND_DIR"

# Run profiler
dart run lib/src/performance_profiler.dart

echo ""
echo "✅ Performance profiling complete!"
echo ""
echo "📊 Reports generated in current directory:"
ls -lh profiling_report_*.txt 2>/dev/null || echo "   (Reports will be saved after analysis)"
