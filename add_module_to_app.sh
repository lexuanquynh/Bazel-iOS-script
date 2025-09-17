#!/bin/bash

# =============================================================================
# Add Module to App - Helper Script
# This script adds a created module to App dependencies
# Usage: ./add_module_to_app.sh <module_path> <module_name> [module_type]
# Example: ./add_module_to_app.sh Features/Login Login feature
# Example: ./add_module_to_app.sh Data/NetworkClient NetworkClient data
# =============================================================================

set -e

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

print_color() {
    echo -e "$1$2${NC}"
}

# Check arguments
if [ $# -lt 2 ]; then
    print_color "$RED" "Usage: $0 <module_path> <module_name> [module_type]"
    print_color "$RED" "Example: $0 Features/Login Login feature"
    print_color "$RED" "Example: $0 Data/NetworkClient NetworkClient data"
    exit 1
fi

MODULE_PATH=$1
MODULE_NAME=$2
MODULE_TYPE=${3:-""}

# Detect module type from path if not provided
if [ -z "$MODULE_TYPE" ]; then
    if [[ "$MODULE_PATH" == Features/* ]]; then
        MODULE_TYPE="feature"
    elif [[ "$MODULE_PATH" == Data/* ]]; then
        MODULE_TYPE="data"
    elif [[ "$MODULE_PATH" == Common/* ]]; then
        MODULE_TYPE="common"
    elif [[ "$MODULE_PATH" == Core/* ]]; then
        MODULE_TYPE="core"
    fi
fi

print_color "$BLUE" "🔗 Adding ${MODULE_TYPE} module '${MODULE_NAME}' to App..."

# =============================================================================
# Update App/BUILD.bazel
# =============================================================================

APP_BUILD="App/BUILD.bazel"

if [ ! -f "$APP_BUILD" ]; then
    print_color "$RED" "Error: App/BUILD.bazel not found!"
    exit 1
fi

# Check if module already exists in deps
if grep -q "//${MODULE_PATH}:${MODULE_NAME}" "$APP_BUILD"; then
    print_color "$YELLOW" "Module already in App/BUILD.bazel"
else
    print_color "$YELLOW" "Adding to App/BUILD.bazel deps..."
    
    # Find the right place to insert based on module type
    case "$MODULE_TYPE" in
        core)
            # Add after Core modules comment
            sed -i '' "/# Core modules/a\\
        \"//${MODULE_PATH}:${MODULE_NAME}\"," "$APP_BUILD"
            ;;
        data)
            # Add after Core modules or create Data section
            if grep -q "# Data modules" "$APP_BUILD"; then
                sed -i '' "/# Data modules/a\\
        \"//${MODULE_PATH}:${MODULE_NAME}\"," "$APP_BUILD"
            else
                # Add Data section after Core modules
                sed -i '' "/# Core modules/,/# Feature modules/{
                    /# Feature modules/i\\
        \\
        # Data modules\\
        \"//${MODULE_PATH}:${MODULE_NAME}\",
                }" "$APP_BUILD"
            fi
            ;;
        common)
            # Add after Core modules or create Common section
            if grep -q "# Common modules" "$APP_BUILD"; then
                sed -i '' "/# Common modules/a\\
        \"//${MODULE_PATH}:${MODULE_NAME}\"," "$APP_BUILD"
            else
                # Add Common section after Core modules
                sed -i '' "/# Core modules/,/# Feature modules/{
                    /# Feature modules/i\\
        \\
        # Common modules\\
        \"//${MODULE_PATH}:${MODULE_NAME}\",
                }" "$APP_BUILD"
            fi
            ;;
        feature)
            # Add after Feature modules comment
            sed -i '' "/# Feature modules/a\\
        \"//${MODULE_PATH}:${MODULE_NAME}\"," "$APP_BUILD"
            ;;
        *)
            # Default: add before the closing bracket
            awk -v module="//${MODULE_PATH}:${MODULE_NAME}" '
            /deps = \[/ { 
                print
                in_deps = 1
                next
            }
            in_deps && /\]/ {
                print "        \"" module "\","
                in_deps = 0
            }
            { print }
            ' "$APP_BUILD" > "${APP_BUILD}.tmp"
            
            mv "${APP_BUILD}.tmp" "$APP_BUILD"
            ;;
    esac
    
    print_color "$GREEN" "✅ Added to App dependencies"
fi

# =============================================================================
# Handle top_level_targets for DevApp (features only)
# =============================================================================

if [ "$MODULE_TYPE" == "feature" ]; then
    ROOT_BUILD="BUILD.bazel"
    DEV_APP_TARGET="//${MODULE_PATH}:${MODULE_NAME}DevApp"
    
    if [ -f "$ROOT_BUILD" ]; then
        # Check if DevApp exists in the module's BUILD file
        if [ -f "${MODULE_PATH}/BUILD.bazel" ] && grep -q "${MODULE_NAME}DevApp" "${MODULE_PATH}/BUILD.bazel"; then
            # Check if DevApp is already in top_level_targets
            if ! grep -q "$DEV_APP_TARGET" "$ROOT_BUILD"; then
                print_color "$YELLOW" "Adding ${MODULE_NAME}DevApp to xcodeproj targets..."
                
                # Add DevApp to top_level_targets
                awk -v devapp="$DEV_APP_TARGET" '
                /top_level_targets = \[/ { 
                    print
                    in_targets = 1
                    next
                }
                in_targets && /\]/ {
                    print "        \"" devapp "\","
                    in_targets = 0
                }
                { print }
                ' "$ROOT_BUILD" > "${ROOT_BUILD}.tmp"
                
                mv "${ROOT_BUILD}.tmp" "$ROOT_BUILD"
                print_color "$GREEN" "✅ Added ${MODULE_NAME}DevApp to xcodeproj targets"
            fi
        fi
    fi
else
    print_color "$YELLOW" "ℹ️  ${MODULE_TYPE} modules are included in Xcode through App dependencies"
fi

# =============================================================================
# Success message
# =============================================================================

print_color "$GREEN" "✅ Module ${MODULE_NAME} successfully linked to App!"
echo ""
print_color "$YELLOW" "Next steps:"
echo "1. Regenerate Xcode project to see the module:"
echo "   bazelisk run //:xcodeproj"
echo ""
echo "2. Build the app with the new module:"
echo "   bazelisk build //App:App --config=sim_debug"
echo ""
echo "3. Or build the module directly:"
echo "   bazelisk build //${MODULE_PATH}:${MODULE_NAME}"

if [ "$MODULE_TYPE" == "feature" ]; then
    echo ""
    echo "4. Run the development app:"
    echo "   bazelisk run //${MODULE_PATH}:${MODULE_NAME}DevApp"
fi
