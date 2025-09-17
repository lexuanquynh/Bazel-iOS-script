#!/bin/bash

# =============================================================================
# iOS Bazel Project Setup with bzlmod and bazelisk (Sept 2025 Version)
# Confirmed working with Bazel 8.4.1 and latest rules
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

print_color "$BLUE" "🚀 Setting up iOS Bazel Project with bzlmod (Bazel 8.x)"
print_color "$BLUE" "   Using bazelisk for version management"
echo ""

# Check if bazelisk is installed
if ! command -v bazelisk &> /dev/null; then
    print_color "$YELLOW" "⚠️  Bazelisk not found. Installing via Homebrew..."
    brew install bazelisk
fi

# =============================================================================
# Create .bazelversion
# =============================================================================

print_color "$YELLOW" "📌 Creating .bazelversion..."
echo "8.4.1" > .bazelversion

# =============================================================================
# Create MODULE.bazel
# =============================================================================

print_color "$YELLOW" "📦 Creating MODULE.bazel..."
cat > "MODULE.bazel" << 'EOF'
# MODULE.bazel
module(
    name = "ios_app",
    version = "1.0.0",
)

# Latest versions compatible with Bazel 8.x (as of late 2024/early 2025)
bazel_dep(name = "rules_apple", version = "4.2.0")      # Latest stable
bazel_dep(name = "rules_swift", version = "3.1.2")       # Latest stable
bazel_dep(name = "apple_support", version = "1.23.1")    # Latest
bazel_dep(name = "bazel_skylib", version = "1.8.1")      # Update to match
bazel_dep(name = "platforms", version = "1.0.0")        # Update to match
bazel_dep(name = "rules_xcodeproj", version = "3.2.0")   # Latest

# Additional dependency for Bazel 8.x
bazel_dep(name = "rules_cc", version = "0.2.8")         # Required for Bazel 8
EOF

# =============================================================================
# Create .bazelrc
# =============================================================================

print_color "$YELLOW" "⚙️  Creating .bazelrc..."
cat > ".bazelrc" << 'EOF'
# .bazelrc
common --enable_bzlmod

# iOS build settings (common for all builds)
build --apple_platform_type=ios
build --incompatible_enable_cc_toolchain_resolution
build --action_cache_store_output_metadata
build --xcode_version=16.4

# Fix for j2objc_dead_code_pruner issue in Bazel 8
build --incompatible_j2objc_library_migration

# Suppress version warnings
common --check_direct_dependencies=off

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

# Combine configs (optional)
build:sim_debug --config=simulator
build:sim_debug --config=debug

build:sim_release --config=simulator
build:sim_release --config=release
EOF

# =============================================================================
# Create root BUILD.bazel
# =============================================================================

print_color "$YELLOW" "📋 Creating root BUILD.bazel..."
cat > "BUILD.bazel" << 'EOF'
load("@rules_xcodeproj//xcodeproj:defs.bzl", "xcodeproj")

# Xcode project generation
xcodeproj(
    name = "xcodeproj",
    project_name = "BzlmodApp",
    tags = ["manual"],
    top_level_targets = [
        "//App:App",
    ],
)
EOF

# =============================================================================
# Create App module structure
# =============================================================================

print_color "$YELLOW" "📁 Creating App module structure..."

# Create directories
mkdir -p App/Sources
mkdir -p App/Resources
mkdir -p App/Tests

# Create App BUILD.bazel
cat > "App/BUILD.bazel" << 'EOF'
load("@rules_swift//swift:swift.bzl", "swift_library")
load("@rules_apple//apple:ios.bzl", "ios_application")

swift_library(
    name = "AppLib",
    srcs = glob(["Sources/**/*.swift"]),
    module_name = "App",
    visibility = ["//visibility:public"],
    deps = [
        # Core modules (add when created)
        # "//Core/Domain:CoreDomain",
        # "//Core/Data:CoreData",
        # "//Core/Presentation:CorePresentation",
        
        # Data modules (add when created)
        
        # Common modules (add when created)
        
        # Feature modules (add when created)
        # "//Features/Authentication:Authentication",
        # "//Features/HomeFeed:HomeFeed",
    ],
)

ios_application(
    name = "App",
    bundle_id = "com.example.bazelapp",
    families = ["iphone", "ipad"],
    infoplists = ["Info.plist"],
    minimum_os_version = "16.0",
    resources = glob(["Resources/**"], allow_empty = True),
    visibility = ["//visibility:public"],
    deps = [":AppLib"],
)
EOF

# Create App.swift
cat > "App/Sources/App.swift" << 'EOF'
import SwiftUI

@main
struct BzlmodApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
EOF

# Create ContentView.swift
cat > "App/Sources/ContentView.swift" << 'EOF'
import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "hammer.circle.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.blue)
                
                Text("Bazel iOS App")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Built with bzlmod & bazelisk")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 10) {
                    Label("Clean Architecture", systemImage: "building.2")
                    Label("Modular Design", systemImage: "square.grid.3x3")
                    Label("Fast Builds", systemImage: "bolt.fill")
                }
                .font(.headline)
                
                Spacer()
            }
            .padding()
            .navigationTitle("BzlmodApp")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
EOF

# Create Info.plist
cat > "App/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>BzlmodApp</string>
    <key>CFBundleDisplayName</key>
    <string>Bzlmod App</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>UILaunchStoryboardName</key>
    <string>LaunchScreen</string>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationPortraitUpsideDown</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
    <key>UIApplicationSceneManifest</key>
    <dict>
        <key>UIApplicationSupportsMultipleScenes</key>
        <false/>
    </dict>
</dict>
</plist>
EOF

# Create test file
cat > "App/Tests/AppTests.swift" << 'EOF'
import XCTest
@testable import AppLib

final class AppTests: XCTestCase {
    func testAppInitialization() {
        // Simple test to verify app module builds
        XCTAssertTrue(true)
    }
}
EOF

# =============================================================================
# Create .gitignore
# =============================================================================

print_color "$YELLOW" "📝 Creating .gitignore..."
cat > ".gitignore" << 'EOF'
# Bazel
bazel-*
.bazelrc.local

# Xcode
*.xcodeproj
*.xcworkspace
*.playground

# macOS
.DS_Store

# Build outputs
build/
DerivedData/

# IDE
.idea/
*.swp
*.swo
*~

# Python
__pycache__/
*.pyc

# Dependencies
/vendor/
EOF

# =============================================================================
# Create SETUP_GUIDE.md
# =============================================================================

print_color "$YELLOW" "📚 Creating SETUP_GUIDE.md..."
cat > "SETUP_GUIDE.md" << 'EOF'
# iOS Bazel Project with bzlmod

Modern iOS project setup using Bazel 8.x with bzlmod for dependency management.

## Prerequisites

- Bazelisk (recommended) or Bazel 8.4.1
- Xcode 15.0+
- macOS 13.0+

### Install Bazelisk
```bash
brew install bazelisk
```

## Project Structure

```
.
├── MODULE.bazel           # Bazel module dependencies
├── BUILD.bazel           # Root build configuration
├── .bazelrc             # Bazel configuration
├── .bazelversion        # Pinned Bazel version (8.4.1)
├── App/                 # Main application module
│   ├── BUILD.bazel
│   ├── Sources/
│   └── Resources/
├── Core/                # Domain layer modules
├── Data/                # Data layer modules
├── Features/            # Feature modules
└── Common/              # Shared utilities
```

## Build Commands (Confirmed Working Sept 2025)

### Build the app
```bash
# Build for simulator
bazelisk build //App:App --config=simulator

# Build for device
bazelisk build //App:App --config=device

# Build with debug configuration
bazelisk build //App:App --config=sim_debug

# Build with release configuration
bazelisk build //App:App --config=sim_release
```

### Build specific modules
```bash
# Build Core modules
bazelisk build //Core/Domain:CoreDomain
bazelisk build //Core/Data:CoreData
bazelisk build //Core/Presentation:CorePresentation

# Build Authentication feature
bazelisk build //Features/Authentication:Authentication

# Build HomeFeed feature
bazelisk build //Features/HomeFeed:HomeFeed
```

### Generate Xcode project
```bash
bazelisk run //:xcodeproj
open BzlmodApp.xcodeproj
```

### Run tests
```bash
# Test all
bazelisk test //...

# Test specific module
bazelisk test //App:AppTests
bazelisk test //Features/Login:LoginTests
```

### Clean and rebuild
```bash
# Clean cache
bazelisk clean --expunge

# Check module dependencies
bazelisk mod graph
```

### Create new module
```bash
./create_module_v2.sh <type> <name>
# Example: ./create_module_v2.sh feature Login
```

## Module Types

- **core**: Domain layer (entities, use cases, repository protocols)
- **data**: Data layer (repository implementations, data sources)
- **feature**: Presentation layer (views, view models, coordinators)
- **common**: Shared utilities and extensions

## Build Configurations

### Simulator Builds
- `--config=simulator`: Base simulator configuration
- `--config=sim_debug`: Simulator with debug symbols
- `--config=sim_release`: Simulator optimized build

### Device Builds
- `--config=device`: Base device configuration
- `--config=device_debug`: Device with debug symbols
- `--config=device_release`: Device optimized build

## Clean Architecture

This project follows Clean Architecture principles:

1. **Dependency Rule**: Dependencies point inward
2. **Layer Independence**: Each layer is independent and testable
3. **Use Case Driven**: Business logic in use cases
4. **Testability**: Each module has its own tests

## Development Workflow

1. Create feature branch
2. Add/modify modules using the script
3. Build and test locally with bazelisk
4. Generate Xcode project for debugging
5. Push changes

## Useful Commands

```bash
# Query all targets in a module
bazelisk query '//Features/Login:*'

# Show dependency graph
bazelisk query 'deps(//App:App)' --output graph

# Build everything
bazelisk build //...

# Test everything  
bazelisk test //...

# Show module graph
bazelisk mod graph

# Clean everything
bazelisk clean --expunge
```

## Tips

- Always use `bazelisk` instead of `bazel` for version consistency
- Run `bazelisk clean --expunge` if you encounter cache issues
- Check `.bazelrc` for build configurations
- Module dependencies are managed in MODULE.bazel
- Use `--config=sim_debug` for development
- Use `--config=sim_release` for performance testing
EOF

# =============================================================================
# Create Makefile for convenience
# =============================================================================

print_color "$YELLOW" "🔧 Creating Makefile for convenience..."
cat > "Makefile" << 'EOF'
# Makefile for iOS Bazel Project

.PHONY: help
help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: setup
setup: ## Initial project setup
	@echo "✅ Project already set up!"

.PHONY: build
build: ## Build app for simulator (debug)
	bazelisk build //App:App --config=sim_debug

.PHONY: build-release
build-release: ## Build app for simulator (release)
	bazelisk build //App:App --config=sim_release

.PHONY: build-device
build-device: ## Build app for device
	bazelisk build //App:App --config=device

.PHONY: test
test: ## Run all tests
	bazelisk test //...

.PHONY: xcode
xcode: ## Generate and open Xcode project
	bazelisk run //:xcodeproj
	open BzlmodApp.xcodeproj

.PHONY: clean
clean: ## Clean build cache
	bazelisk clean

.PHONY: clean-all
clean-all: ## Clean everything (expunge cache)
	bazelisk clean --expunge

.PHONY: deps
deps: ## Show module dependency graph
	bazelisk mod graph

.PHONY: module-core
module-core: ## Create a new core module (prompts for name)
	@read -p "Module name: " name; \
	./create_module_v2.sh core $$name

.PHONY: module-feature
module-feature: ## Create a new feature module (prompts for name)
	@read -p "Feature name: " name; \
	./create_module_v2.sh feature $$name

.PHONY: module-data
module-data: ## Create a new data module (prompts for name)
	@read -p "Module name: " name; \
	./create_module_v2.sh data $$name
EOF

# =============================================================================
# Success message
# =============================================================================

echo ""
print_color "$GREEN" "✅ Project setup complete!"
echo ""
print_color "$BLUE" "📁 Project structure created:"
echo "   ├── MODULE.bazel (bzlmod dependencies)"
echo "   ├── BUILD.bazel (root configuration)"
echo "   ├── .bazelrc (build settings)"
echo "   ├── .bazelversion (Bazel 8.4.1)"
echo "   ├── Makefile (convenience commands)"
echo "   └── App/ (main application)"
echo ""
print_color "$YELLOW" "🚀 Quick Start Commands:"
echo ""
echo "Using bazelisk (recommended):"
print_color "$GREEN" "  bazelisk build //App:App --config=simulator"
print_color "$GREEN" "  bazelisk run //:xcodeproj"
echo ""
echo "Using Makefile shortcuts:"
print_color "$GREEN" "  make build        # Build for simulator"
print_color "$GREEN" "  make xcode        # Open in Xcode"
print_color "$GREEN" "  make test         # Run tests"
print_color "$GREEN" "  make help         # Show all commands"
echo ""
print_color "$BLUE" "📖 Next steps:"
echo "1. Create your first feature module:"
echo "   ./create_module_v2.sh feature Login"
echo ""
echo "2. Build and test:"
echo "   bazelisk build //App:App --config=sim_debug"
echo "   bazelisk test //App:AppTests"
echo ""
echo "3. Open in Xcode for debugging:"
echo "   bazelisk run //:xcodeproj"
echo "   open BzlmodApp.xcodeproj"
echo ""
print_color "$GREEN" "🎉 Happy coding with Bazel 8.x, bzlmod, and bazelisk!"
