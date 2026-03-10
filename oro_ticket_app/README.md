# Oro Ticket App

A comprehensive Flutter-based ticket management system for Oromia Transport Agency, designed for bus ticket booking, fleet management, and operational reporting in Ethiopia.

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Business Flows](#business-flows)
- [Architecture](#architecture)
- [Technology Stack](#technology-stack)
- [Installation & Setup](#installation--setup)
- [Configuration](#configuration)
- [Usage Guide](#usage-guide)
- [API Integration](#api-integration)
- [Data Models](#data-models)
- [Development](#development)
- [Deployment](#deployment)
- [Contributing](#contributing)
- [License](#license)

## 🎯 Overview

Oro Ticket App is a mobile application that streamlines bus ticket operations for transport companies in Ethiopia. The app supports offline-first functionality, thermal ticket printing, Ethiopian calendar integration, and comprehensive fleet management.

### Key Capabilities

- **Offline-First Design**: Full functionality without internet connectivity
- **Multi-language Support**: English and Afaan Oromo interfaces
- **Thermal Printing**: Direct ticket printing via Bluetooth thermal printers
- **Ethiopian Calendar**: Native support for Ethiopian date/time systems
- **Real-time Synchronization**: Automatic data sync when online
- **Comprehensive Reporting**: PDF reports and analytics

## ✨ Features

### Core Functionality

- 🔐 **Secure Authentication**: Company user login with JWT tokens
- 🎫 **Ticket Management**: Create, print, and manage bus tickets
- 🚍 **Fleet Management**: Vehicle registration and tracking
- 🛣️ **Route Management**: Departure/arrival terminal configuration
- 💰 **Pricing System**: Dynamic tariff and service charge calculation
- 📊 **Reporting**: Local and synchronized trip reports
- 🔄 **Data Synchronization**: Offline/online data management
- 🖨️ **Thermal Printing**: Bluetooth-enabled ticket printing

### Advanced Features

- 📅 **Ethiopian Calendar Integration**: Native Ethiopian date/time support
- 🌐 **Offline Mode**: Full functionality without internet
- 📱 **Responsive Design**: Optimized for mobile devices
- 🔍 **Search & Filter**: Advanced data filtering capabilities
- 📈 **Analytics Dashboard**: Service charge and trip analytics
- 🔒 **Secure Storage**: Encrypted local data storage

## 🔄 Business Flows

### 1. User Authentication Flow

```
First App Launch → Reset Password → Sign In → Dashboard
     ↓
Existing User → Sign In → Dashboard
```

**Process:**
1. **First Install**: User sets initial password
2. **Authentication**: Email/password login with JWT
3. **Profile Sync**: Fetch user profile and company data
4. **Data Initialization**: Sync vehicles, terminals, commission rules

### 2. Ticket Booking Flow

```
Dashboard → Select Vehicle → Select Route → Calculate Charges → Print Ticket → Record Trip
```

**Process:**
1. **Vehicle Selection**: Choose from assigned fleet
2. **Route Selection**: Pick departure and arrival terminals
3. **Charge Calculation**:
   - Base tariff (distance-based)
   - Service charge (commission-based)
   - Total payment
4. **Ticket Printing**: Thermal printer output
5. **Trip Recording**: Store trip data locally

### 3. Data Synchronization Flow

```
Offline Operations → Detect Connectivity → Sync Data → Update Local Storage
```

**Process:**
1. **Offline Mode**: All operations work locally
2. **Connectivity Check**: Automatic network detection
3. **Data Sync**:
   - Upload trips to server
   - Download updated fleet data
   - Sync service charges
4. **Conflict Resolution**: Handle data conflicts

### 4. Reporting Flow

```
Dashboard → Reports → Filter Data → Generate PDF → Export/Share
```

**Process:**
1. **Data Aggregation**: Collect trip and service charge data
2. **Filtering**: Date, route, vehicle-based filters
3. **PDF Generation**: Create formatted reports
4. **Export Options**: Save to device or share

### 5. Fleet Management Flow

```
Dashboard → Fleet → Add Vehicle → Configure Routes → Assign Terminals
```

**Process:**
1. **Vehicle Registration**: Plate number, capacity, type
2. **Route Assignment**: Configure available routes
3. **Terminal Association**: Link to departure/arrival points
4. **Status Management**: Track vehicle availability

## 🏗️ Architecture

### Application Structure

```
lib/
├── app/
│   ├── modules/          # Feature modules (MVC pattern)
│   ├── routes/           # Navigation configuration
│   └── data/
│       └── models/       # UI-specific models
├── data/
│   ├── locals/           # Local storage layer
│   │   ├── models/       # Hive data models
│   │   ├── service/      # Storage services
│   │   └── hive_boxes.dart
│   └── repositories/     # Data access layer
├── core/                 # Shared utilities
│   ├── constants/        # App constants
│   ├── theme/           # UI theming
│   └── utils/           # Helper utilities
└── widgets/             # Reusable UI components
```

### Architectural Patterns

#### MVC Pattern Implementation

Each module follows Model-View-Controller pattern:

```
modules/[feature]/
├── bindings/           # Dependency injection
├── controllers/        # Business logic
├── views/             # UI components
└── services/          # Feature-specific services
```

#### State Management

- **GetX**: Reactive state management
- **Hive**: Local data persistence
- **Streams**: Real-time data updates

#### Data Flow

```
API ↔ Repository ↔ Storage Service ↔ Hive Boxes ↔ Controllers ↔ Views
```

### Key Components

#### Data Layer

- **Models**: Hive-compatible data structures
- **Repositories**: API communication and data synchronization
- **Storage Services**: Local data management
- **Sync Repository**: Offline/online data coordination

#### Business Logic Layer

- **Controllers**: Feature-specific business logic
- **Services**: Authentication, printing, utilities
- **Bindings**: Dependency injection configuration

#### Presentation Layer

- **Views**: UI screens and components
- **Widgets**: Reusable UI elements
- **Theme**: Consistent styling and branding

## 🛠️ Technology Stack

### Core Framework
- **Flutter**: 3.6.0+ (UI framework)
- **Dart**: 3.6.0+ (Programming language)

### State Management & Storage
- **GetX**: ^4.7.2 (State management, routing, DI)
- **Hive**: ^2.2.3 (Local database)
- **Hive Flutter**: ^1.1.0 (Flutter integration)

### Networking & API
- **HTTP**: ^1.4.0 (REST API communication)
- **Connectivity Plus**: ^6.1.5 (Network monitoring)

### UI & Design
- **Flutter ScreenUtil**: ^5.9.3 (Responsive design)
- **Bubble Chart**: ^0.4.0 (Data visualization)
- **QR Flutter**: ^4.1.0 (QR code generation)

### Printing & Documents
- **Blue Thermal Printer**: ^1.2.3 (Thermal printing)
- **PDF**: ^3.10.4 (PDF generation)
- **Printing**: ^5.14.2 (Print services)

### Utilities
- **Ethiopian Datetime**: ^1.0.3 (Ethiopian calendar)
- **Flutter DotEnv**: ^5.2.1 (Environment variables)
- **Flutter Secure Storage**: ^9.2.4 (Secure data storage)
- **Permission Handler**: ^11.0.1 (Device permissions)
- **Barcode Widget**: ^2.0.1 (Barcode generation)

## 🚀 Installation & Setup

### Prerequisites

- **Flutter SDK**: 3.6.0 or higher
- **Dart SDK**: 3.6.0 or higher
- **Android Studio**: For Android development
- **Xcode**: For iOS development (macOS only)
- **Git**: Version control

### Installation Steps

1. **Clone Repository**
   ```bash
   git clone <repository-url>
   cd oro_ticket_app
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate Hive Adapters**
   ```bash
   flutter pub run build_runner build
   ```

4. **Environment Setup**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

5. **Run Application**
   ```bash
   flutter run
   ```

### Build Commands

```bash
# Debug build
flutter run

# Release build for Android
flutter build apk --release

# Release build for iOS
flutter build ios --release
```

## ⚙️ Configuration

### Environment Variables (.env)

```env
API_BASE_URL=http://196.189.247.242:4501/api
APP_ENV=production
DEBUG=false
```

### App Configuration

Key configuration files:
- `pubspec.yaml`: Dependencies and app metadata
- `android/app/build.gradle`: Android-specific settings
- `ios/Runner/Info.plist`: iOS configuration
- `lib/core/constants/`: App constants and settings

## 📱 Usage Guide

### For Transport Company Staff

#### Daily Operations

1. **Morning Setup**
   - Launch app and sign in
   - Sync data with server
   - Check assigned vehicles and routes

2. **Ticket Sales**
   - Select vehicle and route
   - Calculate fares automatically
   - Print tickets via thermal printer
   - Record trip details

3. **End of Day**
   - Sync all trip data
   - Generate daily reports
   - Review service charges

#### Key Workflows

**Ticket Issuance:**
1. Open app → Home Dashboard
2. Tap "New Ticket"
3. Select vehicle from dropdown
4. Choose departure and arrival terminals
5. Review calculated charges
6. Print ticket
7. Confirm trip recording

**Data Synchronization:**
1. Ensure internet connectivity
2. Navigate to Sync section
3. Tap "Sync All Data"
4. Wait for completion confirmation
5. Continue with offline operations

## 🔌 API Integration

### Base Configuration

- **Base URL**: Configurable via environment variables
- **Authentication**: JWT Bearer tokens
- **Content-Type**: application/json

### Key Endpoints

#### Authentication
```
POST /api/auth/company-user/login
GET  /api/auth/company-user/profile
```

#### Fleet Management
```
GET  /api/vehicles/company-user/my-vehicles
POST /api/vehicles
PUT  /api/vehicles/{id}
```

#### Trip Management
```
POST /api/trips
GET  /api/trips/company-user
```

#### Service Charges
```
POST /api/service-charges
GET  /api/service-charges/company-user
```

#### Commission Rules
```
GET  /api/commission-rules
```

### Synchronization Strategy

- **Offline-First**: All operations work without internet
- **Background Sync**: Automatic data synchronization
- **Conflict Resolution**: Server-side conflict handling
- **Retry Logic**: Failed sync automatic retry

## 📊 Data Models

### Core Entities

#### User Model
```dart
class UserModel {
  String id;
  String email;
  String fullName;
  String roleId;
  String companyId;
  String? companyName;
  String? logoUrl;
  String? companyPhoneNo;
}
```

#### Vehicle Model
```dart
class VehicleModel {
  String id;
  String plateNumber;
  String plateRegion;
  String fleetType;
  String vehicleLevel;
  String associationName;
  int seatCapacity;
  String status;
  String? assignedTerminalId;
  List<String>? arrivalTerminals;
  List<String>? tariffs;
}
```

#### Trip Model
```dart
class TripModel {
  String vehicleId;
  DateTime dateAndTime;
  double km;
  double tariff;
  double serviceCharge;
  double totalPaid;
  String departureTerminalId;
  String arrivalTerminalId;
  String companyId;
  String employeeId;
  String departureName;
  String arrivalName;
  bool isSynced;
}
```

#### Service Charge Model
```dart
class ServiceChargeModel {
  String departureTerminal;
  DateTime dateTime;
  double serviceChargeAmount;
  String employeeName;
  String employeeId;
  String companyId;
}
```

### Data Relationships

```
Company → Users (1:many)
Company → Vehicles (1:many)
Company → Terminals (1:many)
Vehicle → Trips (1:many)
Terminal → Trips (departure/arrival)
User → ServiceCharges (1:many)
```

## 💻 Development

### Code Organization

#### Module Structure
```
lib/app/modules/[feature]/
├── bindings/[feature]_binding.dart
├── controllers/[feature]_controller.dart
├── views/[feature]_view.dart
├── services/[feature]_service.dart (optional)
└── models/[feature]_model.dart (optional)
```

#### Naming Conventions

- **Files**: snake_case (e.g., `user_model.dart`)
- **Classes**: PascalCase (e.g., `UserModel`)
- **Variables**: camelCase (e.g., `userName`)
- **Constants**: SCREAMING_SNAKE_CASE (e.g., `API_BASE_URL`)

### Development Workflow

1. **Feature Development**
   ```bash
   # Create new module
   flutter pub run get_cli:create page:feature_name

   # Generate Hive adapters
   flutter pub run build_runner build
   ```

2. **Testing**
   ```bash
   flutter test
   ```

3. **Code Analysis**
   ```bash
   flutter analyze
   ```

### Key Development Commands

```bash
# Clean and rebuild
flutter clean && flutter pub get

# Run with hot reload
flutter run --hot

# Build for specific platform
flutter build apk --target-platform android-arm64

# Generate localization files
flutter gen-l10n
```

## 🚀 Deployment

### Android Deployment

1. **Generate Signed APK**
   ```bash
   flutter build apk --release
   ```

2. **Generate App Bundle**
   ```bash
   flutter build appbundle --release
   ```

3. **Play Store Deployment**
   - Upload bundle to Google Play Console
   - Configure store listing
   - Set up beta testing

### iOS Deployment

1. **Build for iOS**
   ```bash
   flutter build ios --release
   ```

2. **Archive in Xcode**
   - Open `ios/Runner.xcworkspace`
   - Product → Archive
   - Upload to App Store Connect

### CI/CD Pipeline

Recommended CI/CD setup:
- **GitHub Actions**: Automated testing and building
- **Fastlane**: iOS deployment automation
- **Firebase App Distribution**: Beta testing

## 🤝 Contributing

### Development Guidelines

1. **Code Style**
   - Follow Flutter/Dart best practices
   - Use meaningful variable names
   - Add documentation comments

2. **Git Workflow**
   ```bash
   # Create feature branch
   git checkout -b feature/feature-name

   # Commit changes
   git commit -m "feat: add feature description"

   # Push and create PR
   git push origin feature/feature-name
   ```

3. **Testing**
   - Write unit tests for business logic
   - Test offline functionality
   - Verify printing capabilities

### Pull Request Process

1. Create feature branch from `develop`
2. Implement changes with tests
3. Ensure all tests pass
4. Update documentation
5. Create pull request with description

## 📄 License

This project is proprietary software owned by Oromia Transport Agency.

## 📞 Support

For technical support or questions:
- **Email**: support@orotransport.et
- **Documentation**: [Internal Wiki]
- **Issue Tracker**: [Git Repository Issues]

---

**Version**: 1.0.0
**Last Updated**: November 2024
**Maintained by**: Oromia Transport Agency IT Department
