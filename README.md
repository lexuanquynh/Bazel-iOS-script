# Bazel iOS Project Setup Package

Complete setup scripts for iOS project with Bazel 8.x, bzlmod, and Clean Architecture.

## 📦 Package Contents

1. **setup_ios_bazel_v2.sh** - Initial project setup script
2. **create_module_v2.sh** - Module creation script (core/data/feature/common)
3. **setup_core_modules.sh** - Core modules structure setup (Domain/Data/Presentation)

## ✅ Verified Configuration (Sept 2025)

- **Bazel**: 8.4.1
- **Xcode**: 16.4
- **iOS Simulator**: iPhone 16 Pro (iOS 18.0)
- **Minimum iOS**: 16.0
- **Dependencies**:
  - rules_apple: 4.2.0
  - rules_swift: 3.1.2
  - rules_xcodeproj: 3.2.0

## 🚀 Quick Start

### 1. Prerequisites

Install Bazelisk (Bazel version manager):
```bash
brew install bazelisk
```

### 2. Initial Setup

```bash
# Make scripts executable
chmod +x *.sh

# Run initial setup
./setup_ios_bazel_v2.sh

# Setup Core modules
./setup_core_modules.sh
```

### 3. Build & Test

```bash
# Build for simulator (debug)
bazelisk build //App:App --config=sim_debug

# Build for simulator (release)
bazelisk build //App:App --config=sim_release

# Build for device
bazelisk build //App:App --config=device

# Run tests
bazelisk test //...

# Run app trên simulator
bazelisk run //App:App --config=simulator

# Or debug config
bazelisk run //App:App --config=sim_debug
```

### 4. Generate Xcode Project

```bash
bazelisk run //:xcodeproj
open BzlmodApp.xcodeproj
```

## 📁 Project Structure

After running all setup scripts:

```
.
├── .bazelversion        # Bazel version (8.4.1)
├── .bazelrc            # Build configurations
├── MODULE.bazel        # Dependencies (bzlmod)
├── BUILD.bazel         # Root build config
├── App/
│   ├── BUILD.bazel
│   ├── Info.plist
│   ├── Sources/
│   └── Resources/
├── Core/
│   ├── Domain/
│   │   ├── BUILD.bazel
│   │   └── Sources/
│   ├── Data/
│   │   ├── BUILD.bazel
│   │   └── Sources/
│   └── Presentation/
│       ├── BUILD.bazel
│       └── Sources/
└── Features/
    └── [Your features here]
```

## 🔧 Build Configurations

### Simulator Builds
- `--config=simulator` - Base simulator configuration
- `--config=sim_debug` - Simulator + Debug symbols
- `--config=sim_release` - Simulator + Optimized

### Device Builds
- `--config=device` - Base device configuration
- `--config=debug` - Debug symbols
- `--config=release` - Optimized build

## 📝 Creating New Modules

### Feature Module
```bash
./create_module_v2.sh feature Login
./create_module_v2.sh feature HomeFeed
```

### Data Module
```bash
./create_module_v2.sh data NetworkClient
./create_module_v2.sh data DatabaseManager
```

### Common Module
```bash
./create_module_v2.sh common Utils
./create_module_v2.sh common Extensions
```

## 🏗️ Module Dependencies

### Core Modules
- `//Core/Domain:CoreDomain` - Business logic, entities, use cases
- `//Core/Data:CoreData` - Repository implementations, data sources
- `//Core/Presentation:CorePresentation` - Base ViewModels, Coordinators

### Feature Modules
Features depend on Core modules:
```python
deps = [
    "//Core/Domain:CoreDomain",
    "//Core/Presentation:CorePresentation",
]
```

## 🛠️ Useful Commands

```bash
# Clean build cache
bazelisk clean --expunge

# Show module dependency graph
bazelisk mod graph

# Query all targets
bazelisk query //...

# Build specific module
bazelisk build //Features/Login:Login

# Run specific tests
bazelisk test //Features/Login:LoginTests
```

## ⚠️ Troubleshooting

### Signing Certificate Issue
If building for device, update the signing certificate in `.bazelrc`:
```
build:device --ios_signing_cert_name="Your Certificate Name"
```

### Xcode Version
Update Xcode version in `.bazelrc` if needed:
```
build --xcode_version=16.4
```

### Cache Issues
If you encounter build errors:
```bash
bazelisk clean --expunge
bazelisk shutdown
```

## 📚 Clean Architecture

This setup follows Clean Architecture principles:

1. **Domain Layer** (`Core/Domain`)
   - Entities
   - Use Cases
   - Repository Protocols

2. **Data Layer** (`Core/Data`)
   - Repository Implementations
   - Remote Data Sources
   - Local Data Sources

3. **Presentation Layer** (`Core/Presentation` & `Features/*`)
   - ViewModels
   - Views (SwiftUI)
   - Coordinators

## 🎯 Best Practices

1. Always use `bazelisk` instead of `bazel`
2. Keep modules small and focused
3. Follow dependency rules (inward pointing)
4. Write tests for each module
5. Use development apps for feature isolation

## 📄 License

This setup package is provided as-is for educational and development purposes.

## 🤝 Support

For issues or questions, refer to:
- [Bazel Documentation](https://bazel.build)
- [rules_apple](https://github.com/bazelbuild/rules_apple)
- [rules_swift](https://github.com/bazelbuild/rules_swift)
- [rules_xcodeproj](https://github.com/MobileNativeFoundation/rules_xcodeproj)

## License

This project is licensed under the [MIT License](./LICENSE).

