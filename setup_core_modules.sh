#!/bin/bash

# =============================================================================
# Core Modules Setup Script
# Creates Core/Domain, Core/Data, Core/Presentation structure
# =============================================================================

set -e

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_color() {
    echo -e "$1$2${NC}"
}

print_color "$BLUE" "🏗️  Setting up Core modules structure"
echo ""

# =============================================================================
# Core/Domain Module
# =============================================================================

print_color "$YELLOW" "📦 Creating Core/Domain module..."

mkdir -p Core/Domain/Sources/Entities
mkdir -p Core/Domain/Sources/UseCases
mkdir -p Core/Domain/Sources/Repositories

# Core/Domain BUILD.bazel
cat > "Core/Domain/BUILD.bazel" << 'EOF'
load("@rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "CoreDomain",
    srcs = glob(["Sources/**/*.swift"]),
    module_name = "CoreDomain",
    visibility = ["//visibility:public"],
    deps = [],
)
EOF

# Sample Entity
cat > "Core/Domain/Sources/Entities/User.swift" << 'EOF'
import Foundation

public struct User {
    public let id: String
    public let name: String
    public let email: String
    public let createdAt: Date
    
    public init(id: String, name: String, email: String, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.email = email
        self.createdAt = createdAt
    }
}
EOF

# Repository Protocol
cat > "Core/Domain/Sources/Repositories/UserRepository.swift" << 'EOF'
import Foundation

public protocol UserRepository {
    func fetchUser(id: String) async throws -> User?
    func fetchAllUsers() async throws -> [User]
    func saveUser(_ user: User) async throws
    func deleteUser(id: String) async throws
}
EOF

# Use Case
cat > "Core/Domain/Sources/UseCases/GetUserUseCase.swift" << 'EOF'
import Foundation

public struct GetUserUseCase {
    private let repository: UserRepository
    
    public init(repository: UserRepository) {
        self.repository = repository
    }
    
    public func execute(userId: String) async throws -> User? {
        return try await repository.fetchUser(id: userId)
    }
}
EOF

# =============================================================================
# Core/Data Module
# =============================================================================

print_color "$YELLOW" "📦 Creating Core/Data module..."

mkdir -p Core/Data/Sources/Repositories
mkdir -p Core/Data/Sources/DataSources/Remote
mkdir -p Core/Data/Sources/DataSources/Local
mkdir -p Core/Data/Sources/Models

# Core/Data BUILD.bazel
cat > "Core/Data/BUILD.bazel" << 'EOF'
load("@rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "CoreData",
    srcs = glob(["Sources/**/*.swift"]),
    module_name = "CoreData",
    visibility = ["//visibility:public"],
    deps = [
        "//Core/Domain:CoreDomain",
    ],
)
EOF

# Repository Implementation
cat > "Core/Data/Sources/Repositories/UserRepositoryImpl.swift" << 'EOF'
import Foundation
import CoreDomain

public final class UserRepositoryImpl: UserRepository {
    private let remoteDataSource: UserRemoteDataSource
    private let localDataSource: UserLocalDataSource
    
    public init(
        remoteDataSource: UserRemoteDataSource,
        localDataSource: UserLocalDataSource
    ) {
        self.remoteDataSource = remoteDataSource
        self.localDataSource = localDataSource
    }
    
    public func fetchUser(id: String) async throws -> User? {
        // Try remote first, fallback to local
        if let remoteUser = try? await remoteDataSource.fetchUser(id: id) {
            try? await localDataSource.saveUser(remoteUser)
            return remoteUser
        }
        return try await localDataSource.fetchUser(id: id)
    }
    
    public func fetchAllUsers() async throws -> [User] {
        let users = try await remoteDataSource.fetchAllUsers()
        for user in users {
            try? await localDataSource.saveUser(user)
        }
        return users
    }
    
    public func saveUser(_ user: User) async throws {
        try await remoteDataSource.saveUser(user)
        try await localDataSource.saveUser(user)
    }
    
    public func deleteUser(id: String) async throws {
        try await remoteDataSource.deleteUser(id: id)
        try await localDataSource.deleteUser(id: id)
    }
}
EOF

# Remote Data Source
cat > "Core/Data/Sources/DataSources/Remote/UserRemoteDataSource.swift" << 'EOF'
import Foundation
import CoreDomain

public protocol UserRemoteDataSource {
    func fetchUser(id: String) async throws -> User?
    func fetchAllUsers() async throws -> [User]
    func saveUser(_ user: User) async throws
    func deleteUser(id: String) async throws
}

public final class UserRemoteDataSourceImpl: UserRemoteDataSource {
    private let baseURL: URL
    
    public init(baseURL: URL) {
        self.baseURL = baseURL
    }
    
    public func fetchUser(id: String) async throws -> User? {
        // TODO: Implement API call
        return User(id: id, name: "Mock User", email: "mock@example.com")
    }
    
    public func fetchAllUsers() async throws -> [User] {
        // TODO: Implement API call
        return [
            User(id: "1", name: "User 1", email: "user1@example.com"),
            User(id: "2", name: "User 2", email: "user2@example.com"),
        ]
    }
    
    public func saveUser(_ user: User) async throws {
        // TODO: Implement API call
    }
    
    public func deleteUser(id: String) async throws {
        // TODO: Implement API call
    }
}
EOF

# Local Data Source
cat > "Core/Data/Sources/DataSources/Local/UserLocalDataSource.swift" << 'EOF'
import Foundation
import CoreDomain

public protocol UserLocalDataSource {
    func fetchUser(id: String) async throws -> User?
    func fetchAllUsers() async throws -> [User]
    func saveUser(_ user: User) async throws
    func deleteUser(id: String) async throws
}

public final class UserLocalDataSourceImpl: UserLocalDataSource {
    private var cache: [String: User] = [:]
    
    public init() {}
    
    public func fetchUser(id: String) async throws -> User? {
        return cache[id]
    }
    
    public func fetchAllUsers() async throws -> [User] {
        return Array(cache.values)
    }
    
    public func saveUser(_ user: User) async throws {
        cache[user.id] = user
    }
    
    public func deleteUser(id: String) async throws {
        cache.removeValue(forKey: id)
    }
}
EOF

# =============================================================================
# Core/Presentation Module
# =============================================================================

print_color "$YELLOW" "📦 Creating Core/Presentation module..."

mkdir -p Core/Presentation/Sources/ViewModels
mkdir -p Core/Presentation/Sources/Coordinators
mkdir -p Core/Presentation/Sources/Views

# Core/Presentation BUILD.bazel
cat > "Core/Presentation/BUILD.bazel" << 'EOF'
load("@rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "CorePresentation",
    srcs = glob(["Sources/**/*.swift"]),
    module_name = "CorePresentation",
    visibility = ["//visibility:public"],
    deps = [
        "//Core/Domain:CoreDomain",
    ],
)
EOF

# Base ViewModel
cat > "Core/Presentation/Sources/ViewModels/BaseViewModel.swift" << 'EOF'
import Foundation
import Combine

@MainActor
open class BaseViewModel: ObservableObject {
    @Published public var isLoading = false
    @Published public var error: Error?
    
    public init() {}
    
    public func handleError(_ error: Error) {
        self.error = error
        print("Error: \(error.localizedDescription)")
    }
    
    public func clearError() {
        self.error = nil
    }
}
EOF

# Base Coordinator
cat > "Core/Presentation/Sources/Coordinators/Coordinator.swift" << 'EOF'
import UIKit

public protocol Coordinator: AnyObject {
    var navigationController: UINavigationController { get }
    func start()
}

public extension Coordinator {
    func push(_ viewController: UIViewController, animated: Bool = true) {
        navigationController.pushViewController(viewController, animated: animated)
    }
    
    func pop(animated: Bool = true) {
        navigationController.popViewController(animated: animated)
    }
    
    func popToRoot(animated: Bool = true) {
        navigationController.popToRootViewController(animated: animated)
    }
}
EOF

# Common Views
cat > "Core/Presentation/Sources/Views/LoadingView.swift" << 'EOF'
import SwiftUI

public struct LoadingView: View {
    public init() {}
    
    public var body: some View {
        VStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5)
            
            Text("Loading...")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
    }
}
EOF

cat > "Core/Presentation/Sources/Views/ErrorView.swift" << 'EOF'
import SwiftUI

public struct ErrorView: View {
    let error: Error
    let retry: () -> Void
    
    public init(error: Error, retry: @escaping () -> Void) {
        self.error = error
        self.retry = retry
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.red)
            
            Text("Error")
                .font(.headline)
            
            Text(error.localizedDescription)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("Retry") {
                retry()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
EOF

# =============================================================================
# Update App BUILD.bazel to use Core modules
# =============================================================================

if [ -f "App/BUILD.bazel" ]; then
    print_color "$YELLOW" "📝 Updating App/BUILD.bazel to include Core modules..."
    
    # Create backup
    cp App/BUILD.bazel App/BUILD.bazel.bak
    
    # Update the file
    cat > "App/BUILD.bazel" << 'EOF'
load("@rules_swift//swift:swift.bzl", "swift_library")
load("@rules_apple//apple:ios.bzl", "ios_application")

swift_library(
    name = "AppLib",
    srcs = glob(["Sources/**/*.swift"]),
    module_name = "App",
    visibility = ["//visibility:public"],
    deps = [
        # Core modules
        "//Core/Domain:CoreDomain",
        "//Core/Data:CoreData",
        "//Core/Presentation:CorePresentation",
        
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
fi

# =============================================================================
# Success message
# =============================================================================

echo ""
print_color "$GREEN" "✅ Core modules created successfully!"
echo ""
print_color "$BLUE" "📁 Structure created:"
echo "   Core/"
echo "   ├── Domain/"
echo "   │   ├── BUILD.bazel"
echo "   │   └── Sources/"
echo "   │       ├── Entities/"
echo "   │       ├── UseCases/"
echo "   │       └── Repositories/"
echo "   ├── Data/"
echo "   │   ├── BUILD.bazel"
echo "   │   └── Sources/"
echo "   │       ├── Repositories/"
echo "   │       └── DataSources/"
echo "   └── Presentation/"
echo "       ├── BUILD.bazel"
echo "       └── Sources/"
echo "           ├── ViewModels/"
echo "           ├── Coordinators/"
echo "           └── Views/"
echo ""
print_color "$YELLOW" "🚀 Build commands:"
echo "   bazelisk build //Core/Domain:CoreDomain"
echo "   bazelisk build //Core/Data:CoreData"
echo "   bazelisk build //Core/Presentation:CorePresentation"
echo ""
print_color "$GREEN" "📱 App now includes all Core modules!"
