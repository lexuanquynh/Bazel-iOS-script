#!/bin/bash

# =============================================================================
# Fix Xcode Bazelisk Permission Issues
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

print_color "$BLUE" "🔧 Fixing Xcode Bazelisk Permission Issues..."
echo ""

# =============================================================================
# 1. Find and fix bazelisk permissions
# =============================================================================

print_color "$YELLOW" "1. Checking bazelisk installation..."

BAZELISK_PATH=$(which bazelisk 2>/dev/null || echo "")

if [ -z "$BAZELISK_PATH" ]; then
    print_color "$RED" "❌ bazelisk not found in PATH"
    print_color "$YELLOW" "Installing bazelisk..."
    brew install bazelisk
    BAZELISK_PATH=$(which bazelisk)
fi

print_color "$GREEN" "✅ bazelisk found at: $BAZELISK_PATH"

# Fix permissions
chmod +x "$BAZELISK_PATH"
print_color "$GREEN" "✅ Fixed bazelisk permissions"

# =============================================================================
# 2. Create bazel wrapper
# =============================================================================

print_color "$YELLOW" "2. Creating bazel wrapper script..."

mkdir -p tools

cat > tools/bazel << 'EOF'
#!/bin/bash
# Bazel wrapper script for Xcode

# Set environment
export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:$PATH"

# Find bazelisk
if command -v bazelisk &> /dev/null; then
    exec bazelisk "$@"
elif [ -f "/usr/local/bin/bazelisk" ]; then
    exec /usr/local/bin/bazelisk "$@"
elif [ -f "/opt/homebrew/bin/bazelisk" ]; then
    exec /opt/homebrew/bin/bazelisk "$@"
elif [ -f "$HOME/.bazelisk/bin/bazelisk" ]; then
    exec "$HOME/.bazelisk/bin/bazelisk" "$@"
else
    echo "Error: bazelisk not found"
    echo "Please install with: brew install bazelisk"
    exit 1
fi
EOF

chmod +x tools/bazel
print_color "$GREEN" "✅ Created tools/bazel wrapper"

# =============================================================================
# 3. Update .bazelrc
# =============================================================================

print_color "$YELLOW" "3. Updating .bazelrc with Xcode settings..."

# Backup existing .bazelrc
if [ -f ".bazelrc" ]; then
    cp .bazelrc .bazelrc.backup
fi

# Check if Xcode settings already exist
if ! grep -q "build:xcode" .bazelrc 2>/dev/null; then
    cat >> .bazelrc << 'EOF'

# ========== XCODE INTEGRATION ==========
# Settings for building from Xcode
build:xcode --spawn_strategy=local
build:xcode --genrule_strategy=local
build:xcode --compilation_mode=dbg
build:xcode --jobs=8
build:xcode --announce_rc

# Fix sandbox issues
build:xcode --sandbox_debug
build:xcode --incompatible_sandbox_hermetic_tmp=false

# Explicit PATH for Xcode
build:xcode --action_env=PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin

# Use local bazel wrapper
build:xcode --action_env=BAZELISK_HOME=/usr/local/bin

# Output settings
startup --output_user_root=/tmp/bazel-xcode
build --symlink_prefix=/tmp/bazel-xcode/
EOF
    print_color "$GREEN" "✅ Added Xcode settings to .bazelrc"
else
    print_color "$YELLOW" "⚠️  Xcode settings already in .bazelrc"
fi

# =============================================================================
# 4. Update BUILD.bazel to use wrapper
# =============================================================================

print_color "$YELLOW" "4. Updating BUILD.bazel to use wrapper..."

# Update root BUILD.bazel to use the wrapper
if [ -f "BUILD.bazel" ]; then
    # Check if bazel_path is already set
    if ! grep -q "bazel_path" BUILD.bazel; then
        # Add bazel_path to xcodeproj
        sed -i '' '/xcodeproj(/,/^)/ {
            /top_level_targets = \[/a\
    bazel_path = "tools/bazel",
        }' BUILD.bazel
        print_color "$GREEN" "✅ Updated BUILD.bazel to use wrapper"
    else
        print_color "$YELLOW" "⚠️  bazel_path already set in BUILD.bazel"
    fi
fi

# =============================================================================
# 5. Clear Xcode derived data
# =============================================================================

print_color "$YELLOW" "5. Clearing Xcode derived data..."

rm -rf ~/Library/Developer/Xcode/DerivedData/*
print_color "$GREEN" "✅ Cleared Xcode derived data"

# =============================================================================
# 6. Clean bazel cache
# =============================================================================

print_color "$YELLOW" "6. Cleaning bazel cache..."

if command -v bazelisk &> /dev/null; then
    bazelisk clean --expunge 2>/dev/null || true
fi
print_color "$GREEN" "✅ Cleaned bazel cache"

# =============================================================================
# 7. Regenerate Xcode project
# =============================================================================

print_color "$YELLOW" "7. Regenerating Xcode project..."

bazelisk run //:xcodeproj --config=xcode
print_color "$GREEN" "✅ Regenerated Xcode project"

# =============================================================================
# Success message
# =============================================================================

echo ""
print_color "$GREEN" "✅ All fixes applied successfully!"
echo ""
print_color "$BLUE" "Next steps:"
echo "1. Open the Xcode project:"
echo "   open BzlmodApp.xcodeproj"
echo ""
echo "2. In Xcode:"
echo "   - Select the App scheme"
echo "   - Choose your simulator"
echo "   - Press Cmd+B to build"
echo ""
print_color "$YELLOW" "If still having issues:"
echo "1. Grant Full Disk Access to Xcode:"
echo "   System Settings > Privacy & Security > Full Disk Access > Add Xcode.app"
echo ""
echo "2. Reset Xcode command line tools:"
echo "   sudo xcode-select --reset"
echo ""
echo "3. Check Console.app for detailed error messages"
echo ""
print_color "$GREEN" "The wrapper script at 'tools/bazel' will handle bazelisk execution."
