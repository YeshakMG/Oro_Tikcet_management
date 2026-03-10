# Development Guide

This guide provides technical documentation for developers working on the Oro Ticket App.

## Table of Contents

1. [Development Environment Setup](#development-environment-setup)
2. [Project Structure](#project-structure)
3. [Code Organization](#code-organization)
4. [Development Workflow](#development-workflow)
5. [Testing](#testing)
6. [Deployment](#deployment)
7. [Best Practices](#best-practices)
8. [Troubleshooting](#troubleshooting)

## Development Environment Setup

### Prerequisites

- **Flutter SDK**: 3.6.0 or higher
- **Dart SDK**: 3.6.0 or higher
- **Android Studio**: Latest stable version
- **Xcode**: 13.0 or higher (macOS only)
- **Git**: Latest version
- **Visual Studio Code**: Recommended IDE

### Environment Setup

1. **Install Flutter**
   ```bash
   # Download Flutter SDK
   git clone https://github.com/flutter/flutter.git -b stable

   # Add to PATH
   export PATH="$PATH:`pwd`/flutter/bin"

   # Verify installation
   flutter doctor
   ```

2. **Clone Repository**
   ```bash
   git clone <repository-url>
   cd oro_ticket_app
   ```

3. **Install Dependencies**
   ```bash
   flutter pub get
   ```

4. **Generate Hive Adapters**
   ```bash
   flutter pub run build_runner build
   ```

5. **Environment Configuration**
   ```bash
   cp .env.example .env
   # Edit .env with development settings
   ```

### IDE Configuration

#### Visual Studio Code

**Recommended Extensions:**
- Flutter
- Dart
- Awesome Flutter Snippets
- Hive Helper

**Settings:**
```json
{
  "dart.lineLength": 100,
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll": true
  }
}
```

## Project Structure

### Directory Layout

```
oro_ticket_app/
├── android/                 # Android platform code
├── ios/                     # iOS platform code
├── lib/                     # Main application code
│   ├── app/
│   │   ├── modules/         # Feature modules (MVC)
│   │   ├── routes/          # Navigation configuration
│   │   └── data/
│   │       └── models/      # UI-specific models
│   ├── data/
│   │   ├── locals/          # Local storage layer
│   │   └── repositories/    # Data access layer
│   ├── core/                # Shared utilities
│   └── widgets/             # Reusable components
├── assets/                  # Static assets
├── docs/                    # Documentation
├── test/                    # Unit tests
└── integration_test/        # Integration tests
```

### Module Structure

Each feature module follows MVC pattern:

```
lib/app/modules/[feature]/
├── bindings/
│   └── [feature]_binding.dart
├── controllers/
│   └── [feature]_controller.dart
├── views/
│   └── [feature]_view.dart
├── services/
│   └── [feature]_service.dart (optional)
└── models/
    └── [feature]_model.dart (optional)
```

## Code Organization

### Naming Conventions

#### Files and Directories
- **snake_case**: `user_model.dart`, `auth_service.dart`
- **PascalCase**: `UserModel`, `AuthService`
- **camelCase**: `userName`, `getUser()`

#### Classes and Types
```dart
// Classes
class UserModel extends HiveObject { ... }
class AuthService { ... }

// Enums
enum UserRole { admin, conductor, driver }

// Constants
const String API_BASE_URL = 'http://api.example.com';
```

### Import Organization

```dart
// 1. Dart imports
import 'dart:convert';
import 'dart:async';

// 2. Flutter imports
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

// 3. Third-party packages (alphabetical)
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

// 4. Project imports (relative)
import '../../../core/constants/colors.dart';
import '../../models/user_model.dart';
import '../services/auth_service.dart';
```

### Code Formatting

#### Flutter Analysis
```yaml
# analysis_options.yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    - always_declare_return_types
    - prefer_const_constructors
    - prefer_const_declarations
    - unnecessary_brace_in_string_interps
    - prefer_single_quotes
```

#### Code Style Guidelines

1. **Line Length**: Maximum 100 characters
2. **Indentation**: 2 spaces (Flutter default)
3. **Braces**: Same line for classes/functions
4. **Comments**: Document public APIs

## Development Workflow

### Feature Development

1. **Create Feature Branch**
   ```bash
   git checkout -b feature/user-authentication
   ```

2. **Implement Feature**
   - Create module structure
   - Implement MVC components
   - Add unit tests
   - Update documentation

3. **Code Review**
   - Run static analysis
   - Execute tests
   - Peer review

4. **Merge to Main**
   ```bash
   git checkout develop
   git merge feature/user-authentication
   ```

### Module Creation

#### Using GetX CLI (Recommended)

```bash
# Install GetX CLI
flutter pub global activate get_cli

# Create new module
get create page:auth

# Create new controller
get create controller:auth on auth
```

#### Manual Module Creation

1. **Create Directory Structure**
   ```bash
   mkdir -p lib/app/modules/auth/{bindings,controllers,views,services}
   ```

2. **Create Binding**
   ```dart
   // lib/app/modules/auth/bindings/auth_binding.dart
   import 'package:get/get.dart';
   import '../controllers/auth_controller.dart';

   class AuthBinding extends Bindings {
     @override
     void dependencies() {
       Get.lazyPut<AuthController>(() => AuthController());
     }
   }
   ```

3. **Create Controller**
   ```dart
   // lib/app/modules/auth/controllers/auth_controller.dart
   import 'package:get/get.dart';

   class AuthController extends GetxController {
     // Controller logic
   }
   ```

4. **Create View**
   ```dart
   // lib/app/modules/auth/views/auth_view.dart
   import 'package:flutter/material.dart';
   import 'package:get/get.dart';
   import '../controllers/auth_controller.dart';

   class AuthView extends GetView<AuthController> {
     @override
     Widget build(BuildContext context) {
       return Scaffold(
         // UI implementation
       );
     }
   }
   ```

### Data Model Creation

#### Hive Model Creation

1. **Create Model Class**
   ```dart
   import 'package:hive/hive.dart';

   part 'user_model.g.dart';

   @HiveType(typeId: 0)
   class UserModel extends HiveObject {
     @HiveField(0)
     String id;

     @HiveField(1)
     String email;

     UserModel({required this.id, required this.email});
   }
   ```

2. **Generate Adapter**
   ```bash
   flutter pub run build_runner build
   ```

3. **Register Adapter**
   ```dart
   // In hive_boxes.dart
   Hive.registerAdapter(UserModelAdapter());
   ```

## Testing

### Unit Testing

#### Controller Testing

```dart
// test/controllers/auth_controller_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:oro_ticket_app/app/modules/auth/controllers/auth_controller.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  test('AuthController login test', () async {
    final controller = AuthController();
    // Test implementation
  });
}
```

#### Widget Testing

```dart
// test/views/auth_view_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:oro_ticket_app/app/modules/auth/views/auth_view.dart';

void main() {
  testWidgets('AuthView renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        home: AuthView(),
      ),
    );

    expect(find.text('Login'), findsOneWidget);
  });
}
```

### Integration Testing

```dart
// integration_test/app_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:oro_ticket_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Full app integration test', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Test full user flow
  });
}
```

### Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/controllers/auth_controller_test.dart

# Run integration tests
flutter test integration_test/

# Run tests with coverage
flutter test --coverage
```

## Deployment

### Build Configuration

#### Android Build

```bash
# Debug APK
flutter build apk

# Release APK
flutter build apk --release

# App Bundle
flutter build appbundle --release
```

#### iOS Build

```bash
# Debug build
flutter build ios

# Release build
flutter build ios --release
```

### Environment Configuration

#### Development Environment

```env
API_BASE_URL=http://localhost:3000/api
DEBUG=true
ENV=development
```

#### Production Environment

```env
API_BASE_URL=https://api.oroticket.et/api
DEBUG=false
ENV=production
```

### CI/CD Pipeline

#### GitHub Actions Example

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v2
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.6.0'

    - run: flutter pub get
    - run: flutter test
    - run: flutter build apk --release
```

## Best Practices

### Code Quality

1. **SOLID Principles**
   - Single Responsibility
   - Open/Closed
   - Liskov Substitution
   - Interface Segregation
   - Dependency Inversion

2. **Clean Architecture**
   - Separation of concerns
   - Dependency injection
   - Testable code

3. **Performance**
   - Minimize rebuilds
   - Optimize list views
   - Use const constructors
   - Lazy loading

### State Management

#### GetX Best Practices

```dart
class UserController extends GetxController {
  // Reactive variables
  final Rx<UserModel?> user = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;

  // Computed properties
  bool get isLoggedIn => user.value != null;

  // Workers
  @override
  void onInit() {
    super.onInit();
    ever(user, _onUserChanged);
  }

  void _onUserChanged(UserModel? user) {
    if (user != null) {
      // Handle user change
    }
  }
}
```

### Error Handling

```dart
class ApiService {
  Future<T> apiCall<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on SocketException {
      throw NetworkException('No internet connection');
    } on TimeoutException {
      throw NetworkException('Request timeout');
    } catch (e) {
      throw UnknownException('Unknown error: $e');
    }
  }
}
```

### Security

1. **API Security**
   - JWT token validation
   - Request signing
   - Rate limiting

2. **Data Security**
   - Encrypted local storage
   - Secure key management
   - Input validation

## Troubleshooting

### Common Issues

#### Build Issues

**Issue**: "Hive adapter not generated"
**Solution**:
```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

**Issue**: "Platform not found"
**Solution**:
```bash
flutter config --enable-web  # For web
flutter config --enable-macos  # For macOS
```

#### Runtime Issues

**Issue**: "Binding not found"
**Solution**: Ensure proper binding registration in routes

**Issue**: "State not updating"
**Solution**: Use `.obs` for reactive variables and `.refresh()` for lists

#### Performance Issues

**Issue**: "UI freezing"
**Solution**: Move heavy operations to background isolates

**Issue**: "Memory leaks"
**Solution**: Properly dispose controllers and cancel subscriptions

### Debugging

#### Logging

```dart
class Logger {
  static void info(String message) {
    if (kDebugMode) {
      print('ℹ️ $message');
    }
  }

  static void error(String message, [Object? error]) {
    print('❌ $message');
    if (error != null) print('Error: $error');
  }
}
```

#### DevTools

```bash
# Run with DevTools
flutter run --debug

# Open DevTools in browser
# http://127.0.0.1:9100
```

### Getting Help

1. **Flutter Documentation**: https://flutter.dev/docs
2. **GetX Documentation**: https://pub.dev/packages/get
3. **Hive Documentation**: https://docs.hivedb.dev/
4. **Stack Overflow**: Tag with `flutter`, `getx`, `hive`

---

**Guide Version**: 1.0
**Last Updated**: November 2024
**Target Audience**: Flutter Developers
**Document Owner**: Oromia Transport Agency Development Team