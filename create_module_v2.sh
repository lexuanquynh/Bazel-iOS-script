#!/bin/bash

# =============================================================================
# iOS Module Generator for Bazel + Clean Architecture (Simplified Version)
# Usage: ./create_module_v2.sh <module_type> <module_name>
# Example: ./create_module_v2.sh core Authentication
# Example: ./create_module_v2.sh feature Login
# =============================================================================

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 <module_type> <module_name>"
    echo ""
    echo "Module types:"
    echo "  core      - Core business logic module (Domain layer)"
    echo "  data      - Data layer module (Repository implementations)"
    echo "  feature   - Feature module (Presentation layer)"
    echo "  common    - Shared utilities module"
    echo ""
    echo "Examples:"
    echo "  $0 core Authentication"
    echo "  $0 feature Login"
    exit 1
}

# Validate inputs
if [ $# -lt 2 ]; then
    show_usage
fi

MODULE_TYPE=$1
MODULE_NAME=$2

# Validate module type
if [[ ! "$MODULE_TYPE" =~ ^(core|data|feature|common)$ ]]; then
    print_color "$RED" "Error: Invalid module type '$MODULE_TYPE'"
    show_usage
fi

# Set module path based on type
case "$MODULE_TYPE" in
    core)
        MODULE_PATH="Core/${MODULE_NAME}"
        ;;
    data)
        MODULE_PATH="Data/${MODULE_NAME}"
        ;;
    feature)
        MODULE_PATH="Features/${MODULE_NAME}"
        ;;
    common)
        MODULE_PATH="Common/${MODULE_NAME}"
        ;;
esac

print_color "$BLUE" "========================================="
print_color "$BLUE" "Creating module: ${MODULE_NAME}"
print_color "$BLUE" "Type: ${MODULE_TYPE}"
print_color "$BLUE" "Path: ${MODULE_PATH}"
print_color "$BLUE" "========================================="

# =============================================================================
# Create directory structure
# =============================================================================

print_color "$YELLOW" "📁 Creating directory structure..."

case "$MODULE_TYPE" in
    core)
        mkdir -p "${MODULE_PATH}/Sources/Entities"
        mkdir -p "${MODULE_PATH}/Sources/UseCases"
        mkdir -p "${MODULE_PATH}/Sources/Repositories"
        mkdir -p "${MODULE_PATH}/Tests"
        ;;
    data)
        mkdir -p "${MODULE_PATH}/Sources/Repositories"
        mkdir -p "${MODULE_PATH}/Sources/DataSources/Remote"
        mkdir -p "${MODULE_PATH}/Sources/DataSources/Local"
        mkdir -p "${MODULE_PATH}/Sources/Models"
        mkdir -p "${MODULE_PATH}/Tests"
        ;;
    feature)
        mkdir -p "${MODULE_PATH}/Sources/Views"
        mkdir -p "${MODULE_PATH}/Sources/ViewModels"
        mkdir -p "${MODULE_PATH}/Sources/Coordinators"
        mkdir -p "${MODULE_PATH}/Resources"
        mkdir -p "${MODULE_PATH}/Tests"
        ;;
    common)
        mkdir -p "${MODULE_PATH}/Sources/Extensions"
        mkdir -p "${MODULE_PATH}/Sources/Utils"
        mkdir -p "${MODULE_PATH}/Tests"
        ;;
esac

# =============================================================================
# Create BUILD.bazel file based on module type
# =============================================================================

print_color "$YELLOW" "📝 Creating BUILD.bazel file..."

BUILD_FILE="${MODULE_PATH}/BUILD.bazel"

# Create BUILD.bazel with proper content based on module type
case "$MODULE_TYPE" in
    core)
        cat > "$BUILD_FILE" << EOF
load("@rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "${MODULE_NAME}",
    srcs = glob(["Sources/**/*.swift"]),
    module_name = "${MODULE_NAME}",
    visibility = ["//visibility:public"],
    deps = [
        # Core layer has no external dependencies
    ],
)
EOF
        ;;
    
    data)
        cat > "$BUILD_FILE" << EOF
load("@rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "${MODULE_NAME}",
    srcs = glob(["Sources/**/*.swift"]),
    module_name = "${MODULE_NAME}",
    visibility = ["//visibility:public"],
    deps = [
        "//Core/Domain:CoreDomain",  # Data depends on Core Domain
    ],
)
EOF
        ;;
    
    feature)
        cat > "$BUILD_FILE" << EOF
load("@rules_swift//swift:swift.bzl", "swift_library")
load("@rules_apple//apple:ios.bzl", "ios_application")

swift_library(
    name = "${MODULE_NAME}",
    srcs = glob(["Sources/**/*.swift"]),
    module_name = "${MODULE_NAME}",
    visibility = ["//visibility:public"],
    deps = [
        "//Core/Domain:CoreDomain",
        "//Core/Presentation:CorePresentation",
        # Add other dependencies as needed
    ],
)

# Development app for testing this feature in isolation
ios_application(
    name = "${MODULE_NAME}DevApp",
    bundle_id = "com.example.dev.${MODULE_NAME}",
    families = ["iphone", "ipad"],
    infoplists = ["Info.plist"],
    minimum_os_version = "16.0",
    resources = glob(["Resources/**"], allow_empty = True),
    visibility = ["//visibility:public"],
    deps = [":${MODULE_NAME}"],
)
EOF
        ;;
    
    common)
        cat > "$BUILD_FILE" << EOF
load("@rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "${MODULE_NAME}",
    srcs = glob(["Sources/**/*.swift"]),
    module_name = "${MODULE_NAME}",
    visibility = ["//visibility:public"],
    deps = [
        # Common utilities have minimal dependencies
    ],
)
EOF
        ;;
esac

# =============================================================================
# Create sample Swift files
# =============================================================================

print_color "$YELLOW" "🔨 Creating sample Swift files..."

case "$MODULE_TYPE" in
    core)
        # Entity
        cat > "${MODULE_PATH}/Sources/Entities/${MODULE_NAME}.swift" << EOF
import Foundation

public struct ${MODULE_NAME} {
    public let id: String
    public let createdAt: Date
    
    public init(id: String = UUID().uuidString, createdAt: Date = Date()) {
        self.id = id
        self.createdAt = createdAt
    }
}
EOF
        
        # Repository Protocol
        cat > "${MODULE_PATH}/Sources/Repositories/${MODULE_NAME}Repository.swift" << EOF
import Foundation

public protocol ${MODULE_NAME}Repository {
    func fetchAll() async throws -> [${MODULE_NAME}]
    func fetch(id: String) async throws -> ${MODULE_NAME}?
    func save(_ item: ${MODULE_NAME}) async throws
    func delete(id: String) async throws
}
EOF
        
        # Use Case
        cat > "${MODULE_PATH}/Sources/UseCases/${MODULE_NAME}UseCase.swift" << EOF
import Foundation

public struct ${MODULE_NAME}UseCase {
    private let repository: ${MODULE_NAME}Repository
    
    public init(repository: ${MODULE_NAME}Repository) {
        self.repository = repository
    }
    
    public func execute() async throws -> [${MODULE_NAME}] {
        return try await repository.fetchAll()
    }
}
EOF
        
        # Test file
        cat > "${MODULE_PATH}/Tests/${MODULE_NAME}Tests.swift" << EOF
import XCTest
@testable import ${MODULE_NAME}

final class ${MODULE_NAME}Tests: XCTestCase {
    func test${MODULE_NAME}Creation() {
        let item = ${MODULE_NAME}()
        XCTAssertNotNil(item.id)
        XCTAssertNotNil(item.createdAt)
    }
}
EOF
        ;;
    
    data)
        # Repository Implementation
        cat > "${MODULE_PATH}/Sources/Repositories/${MODULE_NAME}RepositoryImpl.swift" << EOF
import Foundation
// import Core // Uncomment when Core module exists

public final class ${MODULE_NAME}RepositoryImpl {
    public init() {}
    
    // TODO: Implement repository methods
}
EOF
        
        # Model
        cat > "${MODULE_PATH}/Sources/Models/${MODULE_NAME}Model.swift" << EOF
import Foundation

struct ${MODULE_NAME}Model: Codable {
    let id: String
    let createdAt: Date
}
EOF
        
        # Remote Data Source
        cat > "${MODULE_PATH}/Sources/DataSources/Remote/${MODULE_NAME}RemoteDataSource.swift" << EOF
import Foundation

protocol ${MODULE_NAME}RemoteDataSource {
    func fetchAll() async throws -> [${MODULE_NAME}Model]
}

final class ${MODULE_NAME}RemoteDataSourceImpl: ${MODULE_NAME}RemoteDataSource {
    func fetchAll() async throws -> [${MODULE_NAME}Model] {
        // TODO: Implement API call
        return []
    }
}
EOF
        
        # Test file
        cat > "${MODULE_PATH}/Tests/${MODULE_NAME}RepositoryTests.swift" << EOF
import XCTest
@testable import ${MODULE_NAME}

final class ${MODULE_NAME}RepositoryTests: XCTestCase {
    func testRepository() {
        let repository = ${MODULE_NAME}RepositoryImpl()
        XCTAssertNotNil(repository)
    }
}
EOF
        ;;
    
    feature)
        # View
        cat > "${MODULE_PATH}/Sources/Views/${MODULE_NAME}View.swift" << EOF
import SwiftUI

public struct ${MODULE_NAME}View: View {
    @StateObject private var viewModel = ${MODULE_NAME}ViewModel()
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            VStack {
                Text("${MODULE_NAME} Feature")
                    .font(.title)
                
                if viewModel.isLoading {
                    ProgressView()
                }
                
                Button("Load Data") {
                    Task {
                        await viewModel.loadData()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .navigationTitle("${MODULE_NAME}")
        }
    }
}

struct ${MODULE_NAME}View_Previews: PreviewProvider {
    static var previews: some View {
        ${MODULE_NAME}View()
    }
}
EOF
        
        # ViewModel
        cat > "${MODULE_PATH}/Sources/ViewModels/${MODULE_NAME}ViewModel.swift" << EOF
import Foundation
import Combine

@MainActor
public final class ${MODULE_NAME}ViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var items: [String] = []
    
    public init() {}
    
    func loadData() async {
        isLoading = true
        defer { isLoading = false }
        
        // TODO: Load actual data
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        items = ["Item 1", "Item 2", "Item 3"]
    }
}
EOF
        
        # Coordinator
        cat > "${MODULE_PATH}/Sources/Coordinators/${MODULE_NAME}Coordinator.swift" << EOF
import UIKit
import SwiftUI

public final class ${MODULE_NAME}Coordinator {
    private weak var navigationController: UINavigationController?
    
    public init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    public func start() {
        let view = ${MODULE_NAME}View()
        let hostingController = UIHostingController(rootView: view)
        navigationController?.pushViewController(hostingController, animated: true)
    }
}
EOF
        
        # Info.plist for Dev App
        cat > "${MODULE_PATH}/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>${MODULE_NAME} Dev</string>
    <key>CFBundleDisplayName</key>
    <string>${MODULE_NAME} Dev</string>
    <key>UILaunchStoryboardName</key>
    <string>LaunchScreen</string>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
    </array>
    <key>UIApplicationSceneManifest</key>
    <dict>
        <key>UIApplicationSupportsMultipleScenes</key>
        <false/>
    </dict>
</dict>
</plist>
EOF
        
        # Test file
        cat > "${MODULE_PATH}/Tests/${MODULE_NAME}ViewModelTests.swift" << EOF
import XCTest
@testable import ${MODULE_NAME}

final class ${MODULE_NAME}ViewModelTests: XCTestCase {
    @MainActor
    func testViewModel() async {
        let viewModel = ${MODULE_NAME}ViewModel()
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertTrue(viewModel.items.isEmpty)
        
        await viewModel.loadData()
        
        XCTAssertFalse(viewModel.items.isEmpty)
    }
}
EOF
        ;;
    
    common)
        # Extension
        cat > "${MODULE_PATH}/Sources/Extensions/String+Extensions.swift" << EOF
import Foundation

public extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
EOF
        
        # Utility
        cat > "${MODULE_PATH}/Sources/Utils/Logger.swift" << EOF
import Foundation

public struct Logger {
    public static func log(_ message: String) {
        #if DEBUG
        print("[LOG] \(message)")
        #endif
    }
}
EOF
        
        # Test file
        cat > "${MODULE_PATH}/Tests/${MODULE_NAME}Tests.swift" << EOF
import XCTest
@testable import ${MODULE_NAME}

final class ${MODULE_NAME}Tests: XCTestCase {
    func testStringExtension() {
        let text = "  Hello  "
        XCTAssertEqual(text.trimmed, "Hello")
    }
}
EOF
        ;;
esac

# =============================================================================
# Create or update root BUILD.bazel
# =============================================================================

print_color "$YELLOW" "📋 Creating/Updating root BUILD.bazel..."

ROOT_BUILD="BUILD.bazel"

if [ ! -f "$ROOT_BUILD" ]; then
    print_color "$YELLOW" "Creating root BUILD.bazel..."
    cat > "$ROOT_BUILD" << 'EOF'
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
fi

# =============================================================================
# Create MODULE.bazel for bzlmod (Bazel 8.x)
# =============================================================================

if [ ! -f "MODULE.bazel" ]; then
    print_color "$YELLOW" "📦 Creating MODULE.bazel file for bzlmod..."
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
fi

# =============================================================================
# Create .bazelversion
# =============================================================================

if [ ! -f ".bazelversion" ]; then
    print_color "$YELLOW" "📌 Creating .bazelversion file..."
    echo "8.4.1" > .bazelversion
fi

# =============================================================================
# Create .bazelrc if it doesn't exist
# =============================================================================

if [ ! -f ".bazelrc" ]; then
    print_color "$YELLOW" "⚙️  Creating .bazelrc file..."
    cat > ".bazelrc" << 'EOF'
# Enable bzlmod (default in Bazel 8.x)
common --enable_bzlmod

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
fi

# =============================================================================
# Success message
# =============================================================================

print_color "$GREEN" "✅ Module '${MODULE_NAME}' created successfully!"
print_color "$GREEN" "📁 Location: ${MODULE_PATH}"

# Auto-add modules to App dependencies
echo ""
print_color "$YELLOW" "🔗 Linking module to App..."

# Check if helper script exists in same directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [ -f "$SCRIPT_DIR/add_module_to_app.sh" ]; then
    chmod +x "$SCRIPT_DIR/add_module_to_app.sh"
    "$SCRIPT_DIR/add_module_to_app.sh" "${MODULE_PATH}" "${MODULE_NAME}" "${MODULE_TYPE}"
else
    print_color "$YELLOW" "⚠️  To link this module to App, manually add to App/BUILD.bazel deps:"
    echo "     \"//${MODULE_PATH}:${MODULE_NAME}\","
fi

echo ""
print_color "$BLUE" "Next steps:"
echo "  1. Generate Xcode project:"
echo "     bazelisk run //:xcodeproj"
echo ""
echo "  2. Build the module:"
echo "     bazelisk build //${MODULE_PATH}:${MODULE_NAME}"
echo ""
echo "  3. Build the app:"
echo "     bazelisk build //App:App --config=sim_debug"

if [ "$MODULE_TYPE" == "feature" ]; then
    echo ""
    echo "  4. Run development app:"
    echo "     bazelisk run //${MODULE_PATH}:${MODULE_NAME}DevApp"
fi

print_color "$GREEN" "🚀 Happy coding!"
