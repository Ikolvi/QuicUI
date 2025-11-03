#!/bin/bash

# Monitor host engine build progress

LOG_FILE="/tmp/host_build_proper.log"

echo "Monitoring host engine build..."
echo "Press Ctrl+C to stop monitoring"
echo ""

while true; do
    if [ -f "$LOG_FILE" ]; then
        # Get latest progress
        PROGRESS=$(tail -1 "$LOG_FILE" | grep -o "^\[[0-9]*/[0-9]*\]" || echo "")
        
        if [ -n "$PROGRESS" ]; then
            # Calculate percentage
            CURRENT=$(echo "$PROGRESS" | sed 's/\[//;s/\/.*//')
            TOTAL=$(echo "$PROGRESS" | sed 's/.*\///;s/\]//')
            PERCENT=$((CURRENT * 100 / TOTAL))
            
            clear
            echo "Host Engine Build Progress"
            echo "============================"
            echo ""
            echo "Status: $PROGRESS"
            echo "Progress: $PERCENT%"
            echo ""
            echo "Latest build steps:"
            tail -5 "$LOG_FILE" | grep "^\[" | tail -3
            echo ""
            echo "Estimated time remaining: ~$((6301 - CURRENT)) steps"
            
            # Check if build completed
            if grep -q "ninja: build stopped" "$LOG_FILE"; then
                echo ""
                echo "⚠️  Build stopped with errors!"
                tail -20 "$LOG_FILE" | grep -E "FAILED|ERROR"
                exit 1
            fi
            
            if [ "$CURRENT" -eq "$TOTAL" ]; then
                echo ""
                echo "✅ Build completed successfully!"
                echo ""
                echo "Next step: Run ./test_apps/test_app_fresh/build_with_local_engine.sh"
                exit 0
            fi
        else
            echo "Waiting for build to start..."
        fi
    else
        echo "Log file not found. Is the build running?"
    fi
    
    sleep 5
done
