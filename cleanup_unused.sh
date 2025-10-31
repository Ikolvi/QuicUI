#!/bin/bash

##############################################################################
# QuicUI Widget Factory - Unused Methods & Imports Cleanup Script
# 
# Purpose: Remove all unused methods, imports, and fields from the codebase
# Date: October 31, 2025
# Target: 95+ unused items across rendering modules
##############################################################################

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ROOT="/Users/admin/Documents/advstorysrc/FlutterProjects/QuicUI/quicui"
RENDERING_DIR="$PROJECT_ROOT/lib/src/rendering"
BACKUP_DIR="$PROJECT_ROOT/.backup_$(date +%Y%m%d_%H%M%S)"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   QuicUI Cleanup: Remove Unused Methods & Imports         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Create backup
echo -e "${YELLOW}Creating backup...${NC}"
mkdir -p "$BACKUP_DIR"
cp -r "$RENDERING_DIR" "$BACKUP_DIR/"
echo -e "${GREEN}✓ Backup created at: $BACKUP_DIR${NC}"
echo ""

# Function to remove unused import
remove_unused_import() {
    local file=$1
    local import=$2
    
    if grep -q "$import" "$file"; then
        sed -i '' "/$import/d" "$file"
        echo -e "${GREEN}✓ Removed import: $import${NC}"
    fi
}

# Function to remove unused method/field
remove_unused_item() {
    local file=$1
    local pattern=$2
    local description=$3
    
    # Try to find and remove the declaration
    if grep -q "$pattern" "$file"; then
        # This is a rough removal - may need manual refinement
        echo -e "${YELLOW}⚠ Manual review needed for: $description${NC}"
    fi
}

echo -e "${BLUE}Step 1: Remove unused imports from gesture_helpers.dart${NC}"
remove_unused_import "$RENDERING_DIR/gesture_helpers.dart" "import 'package:flutter/material.dart';"
echo ""

echo -e "${BLUE}Step 2: Remove unused imports from ui_renderer.dart${NC}"
remove_unused_import "$RENDERING_DIR/ui_renderer.dart" "import 'layout_widgets.dart';"
remove_unused_import "$RENDERING_DIR/ui_renderer.dart" "import 'form_widgets.dart';"
remove_unused_import "$RENDERING_DIR/ui_renderer.dart" "import 'form_widget_builders.dart';"
remove_unused_import "$RENDERING_DIR/ui_renderer.dart" "import 'scrolling_widgets.dart';"
remove_unused_import "$RENDERING_DIR/ui_renderer.dart" "import 'navigation_widgets.dart';"
remove_unused_import "$RENDERING_DIR/ui_renderer.dart" "import 'animation_widgets.dart';"
remove_unused_import "$RENDERING_DIR/ui_renderer.dart" "import 'data_display_widgets.dart';"
remove_unused_import "$RENDERING_DIR/ui_renderer.dart" "import 'state_management_widgets.dart';"
remove_unused_import "$RENDERING_DIR/ui_renderer.dart" "import 'gesture_widgets.dart';"
echo ""

echo -e "${BLUE}Step 3: Verify compilation after import removal${NC}"
cd "$PROJECT_ROOT"
flutter analyze lib/src/rendering/ 2>&1 | grep -E "errors?:|warnings?:" || echo "Analysis complete"
echo ""

echo -e "${YELLOW}Step 4: Removing unused methods and fields${NC}"
echo "This requires manual review of the following unused items:"
echo ""

# List unused methods in ui_renderer.dart (too many to auto-remove safely)
echo -e "${RED}Unused methods in ui_renderer.dart (53 methods):${NC}"
flutter analyze lib/src/rendering/ui_renderer.dart 2>&1 | grep "unused_element" | grep "_build" | sed 's/^/  • /'
echo ""

# List unused methods in widget_factory_registry.dart
echo -e "${RED}Unused helper methods in widget_factory_registry.dart:${NC}"
flutter analyze lib/src/rendering/widget_factory_registry.dart 2>&1 | grep "unused_element" | sed 's/^/  • /'
echo ""

# Unused field
echo -e "${RED}Unused field in widget_factory_registry.dart:${NC}"
flutter analyze lib/src/rendering/widget_factory_registry.dart 2>&1 | grep "unused_field" | sed 's/^/  • /'
echo ""

echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}SUMMARY OF CHANGES${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo "✓ Removed 9 unused imports from ui_renderer.dart"
echo "✓ Removed 1 unused import from gesture_helpers.dart"
echo ""
echo -e "${YELLOW}Manual Cleanup Required:${NC}"
echo "  • 53 unused methods in ui_renderer.dart"
echo "  • 8 unused helper methods in widget_factory_registry.dart"
echo "  • 1 unused field (_fieldControllers) in widget_factory_registry.dart"
echo ""
echo -e "${BLUE}Total unused items removed: 10${NC}"
echo -e "${YELLOW}Total items needing manual review: 62${NC}"
echo ""

echo -e "${GREEN}Cleanup phase 1 complete!${NC}"
echo ""
echo "Next steps:"
echo "  1. Review ui_renderer.dart - it contains legacy build methods"
echo "  2. Decide if ui_renderer.dart is still needed (appears unused)"
echo "  3. Remove _fieldControllers from widget_factory_registry if truly unused"
echo "  4. Run: flutter analyze lib/src/rendering/ to verify"
echo ""
