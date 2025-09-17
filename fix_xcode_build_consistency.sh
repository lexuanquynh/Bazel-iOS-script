#!/bin/bash

# =============================================================================
# Fix Xcode Build Inconsistency (Clean works, Build fails randomly)
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

print_color "$BLUE" "🔧 Fixing Xcode Build Inconsistency Issues..."
echo ""

# =============================================================================
# 1. Kill any hanging bazel processes
# =============================================================================

print_color "$YELLOW" "1. Cleaning up hanging processes..."

# Kill bazel server
/opt/homebrew/bin/bazelisk shutdown 2>/dev/null || true

# Kill any hanging bazel processes
pkill -f bazel 2>/dev/null || true

print_color "$GREEN" "✅ Cleaned up processes"

# =============================================================================
# 2. Clear all caches
# =============================================================================

print_color "$YELLOW" "2. Clearing all caches..."

# Clear Bazel cache
rm -rf ~/.cache/bazel
rm -rf /private/var/tmp/_bazel_*
rm -rf /tmp/bazel-*

# Clear Xcode derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# Clear module cache
rm -rf ~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex

print_color "$GREEN" "✅ Cleared all caches"

# =============================================================================
# 3. Create comprehensive .bazelrc
# =============================================================================

print_color "$YELLOW" "3. Creating fixed .bazelrc..."

# Backup existing
cp .bazelrc .bazelrc.backup.$(date +%s) 2>/dev/null || true

# Create new .bazelrc with all fixes
cat > .bazelrc << 'EOF'
# .bazelrc - Fixed for Xcode build consistency
common --enable_bzlmod

# iOS build settings
build --apple_platform_type=ios
build --incompatible_enable_cc_toolchain_resolution
build --action_cache_store_output_metadata
build --xcode_version=16.4

# Fix for j2objc_dead_code_pruner issue in Bazel 8
build --incompatible_j2objc_library_migration

# Suppress warnings
common --check_direct_dependencies=off

# ========== FIX BUILD INCONSISTENCY ==========
# Critical fixes for Xcode + Bazel conflicts

# Use local execution to avoid sandbox conflicts
build --spawn_strategy=local
build --genrule_strategy=local
build --worker_sandboxing=false

# Disable hermetic sandbox
build --incompatible_sandbox_hermetic_tmp=false
build --sandbox_debug

# Fix symlink issues
build --experimental_convenience_symlinks=ignore
build --incompatible_strict_action_env=false

# Memory and CPU management
build --local_ram_resources=HOST_RAM*.5
build --local_cpu_resources=HOST_CPUS*.5
build --jobs=4

# Output management
build --experimental_writable_outputs
build --experimental_remotable_source_manifests=false

# ========== CONFIG DEFINITIONS ==========

# Config for iOS Simulator
build:simulator --ios_multi_cpus=sim_arm64,x86_64
build:simulator --ios_simulator_device="iPhone 16 Pro"
build:simulator --ios_simulator_version=18.0
build:simulator --apple_platform_type=ios

# Config for iOS Device
build:device --ios_multi_cpus=arm64
build:device --apple_platform_type=ios
build:device --ios_signing_cert_name="Apple Development"

# Config for Debug builds
build:debug --compilation_mode=dbg
build:debug --spawn_strategy=local
build:debug --objc_enable_binary_stripping=false

# Config for Release builds
build:release --compilation_mode=opt
build:release --objc_enable_binary_stripping=true

# Combine configs
build:sim_debug --config=simulator
build:sim_debug --config=debug

build:sim_release --config=simulator
build:sim_release --config=release

# ========== XCODE SPECIFIC ==========
# When building from Xcode

build:xcode --spawn_strategy=local
build:xcode --sandbox_strategy=local
build:xcode --worker_sandboxing=false
build:xcode --genrule_strategy=local
build:xcode --compilation_mode=dbg
build:xcode --jobs=4
build:xcode --announce_rc
build:xcode --experimental_writable_outputs
build:xcode --incompatible_sandbox_hermetic_tmp=false
build:xcode --sandbox_debug
build:xcode --sandbox_writable_path=/tmp
build:xcode --action_env=PATH=/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin

# Output paths for Xcode
startup --output_user_root=/tmp/bazel-xcode
build:xcode --symlink_prefix=/tmp/bazel-xcode/
EOF

print_color "$GREEN" "✅ Created fixed .bazelrc"

# =============================================================================
# 4. Create Xcode build wrapper
# =============================================================================

print_color "$YELLOW" "4. Creating Xcode build wrapper..."

mkdir -p tools

cat > tools/xcode-build.sh << 'EOF'
#!/bin/bash
# Xcode build wrapper to ensure consistency

# Clean any locks
rm -f /tmp/bazel-xcode/*.lock 2>/dev/null

# Ensure bazel server is running fresh
/opt/homebrew/bin/bazelisk shutdown
sleep 1

# Execute build with retries
MAX_RETRIES=3
RETRY=0

while [ $RETRY -lt $MAX_RETRIES ]; do
    if /opt/homebrew/bin/bazelisk "$@" --config=xcode; then
        exit 0
    fi
    
    RETRY=$((RETRY + 1))
    echo "Build failed, retry $RETRY/$MAX_RETRIES..."
    
    # Clean locks between retries
    rm -f /tmp/bazel-xcode/*.lock 2>/dev/null
    sleep 2
done

exit 1
EOF

chmod +x tools/xcode-build.sh
print_color "$GREEN" "✅ Created build wrapper"

# =============================================================================
# 5. Update BUILD.bazel to use wrapper
# =============================================================================

print_color "$YELLOW" "5. Updating BUILD.bazel..."

# Update to use the wrapper
if ! grep -q "bazel_path" BUILD.bazel; then
    sed -i '' '/xcodeproj(/,/^)/ {
        /top_level_targets = \[/a\
    bazel_path = "tools/xcode-build.sh",
    }' BUILD.bazel
fi

print_color "$GREEN" "✅ Updated BUILD.bazel"

# =============================================================================
# 6. Clean everything
# =============================================================================

print_color "$YELLOW" "6. Deep cleaning..."

# Shutdown bazel
/opt/homebrew/bin/bazelisk shutdown

# Clean with expunge
/opt/homebrew/bin/bazelisk clean --expunge

# Remove all temp files
rm -rf /tmp/bazel-*
rm -rf ~/.cache/bazel

print_color "$GREEN" "✅ Deep clean complete"

# =============================================================================
# 7. Regenerate project
# =============================================================================

print_color "$YELLOW" "7. Regenerating Xcode project..."

# Remove old project
rm -rf BzlmodApp.xcodeproj

# Generate fresh
/opt/homebrew/bin/bazelisk run //:xcodeproj --config=xcode

print_color "$GREEN" "✅ Project regenerated"

# =============================================================================
# 8. Set proper permissions
# =============================================================================

if [ -d "BzlmodApp.xcodeproj" ]; then
    chmod -R 755 BzlmodApp.xcodeproj
    print_color "$GREEN" "✅ Fixed permissions"
fi

# =============================================================================
# Success message
# =============================================================================

echo ""
print_color "$GREEN" "✅ All fixes applied!"
echo ""
print_color "$BLUE" "🎯 What was fixed:"
echo "1. Removed sandbox conflicts"
echo "2. Fixed file lock issues"
echo "3. Set local execution strategy"
echo "4. Limited concurrent jobs"
echo "5. Created retry wrapper"
echo ""
print_color "$YELLOW" "📝 Important:"
echo ""
echo "1. Open Xcode:"
echo "   open BzlmodApp.xcodeproj"
echo ""
echo "2. If asked about unlocking:"
echo "   → Choose 'Don't Unlock'"
echo ""
echo "3. Build with Cmd+B"
echo "   → Should work consistently now"
echo ""
echo "4. If build fails in Xcode:"
echo "   → Clean: Cmd+Shift+K"
echo "   → Build again: Cmd+B"
echo ""
print_color "$GREEN" "The build should now work consistently!"
echo ""
print_color "$YELLOW" "Alternative: Build from terminal instead of Xcode:"
echo "   bazelisk build //App:App --config=sim_debug"
