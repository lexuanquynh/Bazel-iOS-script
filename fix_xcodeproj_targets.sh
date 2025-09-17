#!/bin/bash

# =============================================================================
# Fix xcodeproj targets - Remove swift_library from top_level_targets
# =============================================================================

echo "Fixing BUILD.bazel - removing swift_library targets from top_level_targets..."

# Backup the original file
cp BUILD.bazel BUILD.bazel.backup

# Remove feature library targets (keeping only App and DevApp targets)
cat BUILD.bazel | awk '
/top_level_targets = \[/ { 
    print
    in_targets = 1
    next
}
in_targets {
    # Keep App and DevApp targets
    if ($0 ~ /App:App/ || $0 ~ /DevApp"/) {
        print
    } else if ($0 ~ /\]/) {
        print
        in_targets = 0
    }
    # Skip swift_library targets (Features/*/Module)
    else if ($0 !~ /Features\/[^:]+:[^D]/) {
        print
    }
}
!in_targets {
    print
}
' > BUILD.bazel.fixed

mv BUILD.bazel.fixed BUILD.bazel

echo "✅ Fixed! Now only ios_application targets are in top_level_targets"
echo ""
echo "Current top_level_targets:"
grep -A 10 "top_level_targets = \[" BUILD.bazel | grep -B 10 "\]"
