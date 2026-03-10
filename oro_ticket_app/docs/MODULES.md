# Module Documentation

This document provides detailed documentation for each module in the Oro Ticket App, including business logic explanations and implementation details.

## Table of Contents

1. [Authentication Module](#authentication-module)
2. [Home/Dashboard Module](#homedashboard-module)
3. [Ticket Management Module](#ticket-management-module)
4. [Trip Management Module](#trip-management-module)
5. [Fleet Management Module](#fleet-management-module)
6. [Reporting Module](#reporting-module)
7. [Synchronization Module](#synchronization-module)
8. [Settings Module](#settings-module)

## Authentication Module

### Overview

The authentication module handles user login, session management, and secure token storage.

### Structure

```
lib/app/modules/sign_in/
├── bindings/sign_in_binding.dart
├── controllers/sign_in_controller.dart
├── views/sign_in_view.dart
└── services/auth_service.dart
```

### Business Logic

#### Login Flow

1. **Input Validation**
   - Email format validation
   - Password presence check
   - Form state management

2. **Authentication Process**
   ```dart
   // Controller logic
   Future<void> login() async {
     // Validate inputs
     if (!isValidInput()) return;

     // Call authentication service
     final result = await _authService.login(email, password);

     // Handle response
     if (result.success) {
       await syncUserData();
       navigateToHome();
     } else {
       showError(result.message);
     }
   }
   ```

3. **Session Management**
   - JWT token storage in secure storage
   - Automatic token refresh
   - Session timeout handling

#### Offline Authentication

- **Fallback Mechanism**: Cached credentials for offline login
- **Token Validation**: Local token expiry checks
- **Data Synchronization**: Background sync after reconnection

### Key Components

#### AuthService

**Responsibilities:**
- API communication for authentication
- Token management
- Profile data synchronization
- Logout handling with data validation

**Key Methods:**
```dart
Future<Map<String, dynamic>> login(String email, String password)
Future<void> logout()
Future<String?> getToken()
Future<UserModel?> getUser()
Future<void> fetchAndStoreProfileData()
```

#### SignInController

**State Management:**
```dart
final emailController = TextEditingController();
final passwordController = TextEditingController();
final isPasswordVisible = false.obs;
final isLoading = false.obs;
final loginError = ''.obs;
```

**Business Rules:**
- Password visibility toggle
- Form validation
- Error handling and user feedback
- Navigation after successful login

## Home/Dashboard Module

### Overview

The home module serves as the main dashboard displaying key metrics and providing navigation to all features.

### Structure

```
lib/app/modules/home/
├── bindings/home_binding.dart
├── controllers/home_controller.dart
└── views/home_view.dart
```

### Business Logic

#### Dashboard Metrics

1. **Service Charge Tracking**
   ```dart
   // Daily service charge calculation
   void addOrUpdateServiceCharge({
     required double baseCharge,
     required int seatCount,
     required String departureTerminal,
   }) async {
     final newChargeAmount = baseCharge * seatCount;
     // Update or create daily entry
   }
   ```

2. **Ethiopian Date Display**
   ```dart
   void updateEthiopianDate() {
     final now = DateTime.now();
     final ethDate = now.convertToEthiopian();
     ethiopianDate.value = formatEthiopianDate(ethDate);
   }
   ```

3. **Real-time Updates**
   - Service charge totals update after each ticket
   - Ethiopian date updates automatically
   - User profile information display

### Key Features

#### Navigation Drawer

- **Menu Items**: All major app functions
- **User Profile**: Company information and user details
- **Quick Actions**: Direct access to common tasks

#### Dashboard Cards

- **Today's Service Charges**: Running total for current day
- **Quick Stats**: Trip count, revenue summary
- **Recent Activity**: Latest transactions

## Ticket Management Module

### Overview

The ticket module handles ticket creation, pricing calculation, and thermal printing.

### Structure

```
lib/app/modules/ticket/
├── bindings/ticket_binding.dart
├── controllers/ticket_controller.dart
└── views/ticket_view.dart
```

### Business Logic

#### Ticket Creation Flow

1. **Vehicle Selection**
   - Load assigned vehicles from local storage
   - Validate vehicle availability
   - Retrieve vehicle-specific tariffs

2. **Route Configuration**
   ```dart
   // Populate ticket data
   void populateFromModels(VehicleModel vehicle, ArrivalTerminalModel arrival,
       DepartureTerminalModel departure, UserModel user) {
     // Set vehicle information
     selectedVehicle.value = vehicle;
     plateNumber.value = vehicle.plateNumber;

     // Set route information
     locationFrom.value = departure.name;
     locationTo.value = arrival.id;

     // Calculate pricing
     calculateCharges(arrival.tariff);
   }
   ```

3. **Dynamic Pricing Calculation**
   ```dart
   void calculateCharges(double baseTariff) async {
     // Get commission rate from local storage
     final rule = await getCommissionRule();
     double rate = rule?.commissionRate ?? 0.0;

     // Calculate charges
     double serviceCharge = baseTariff * rate;
     double totalPayment = baseTariff + serviceCharge;

     // Update reactive variables
     tariff.value = "${baseTariff.toStringAsFixed(2)} ETB";
     serviceChargeText.value = "${serviceCharge.toStringAsFixed(2)} ETB";
     totalPaymentText.value = "${totalPayment.toStringAsFixed(2)} ETB";
   }
   ```

4. **Ticket Generation**
   - Unique ticket numbering
   - Ethiopian date/time formatting
   - QR code generation for verification
   - Company branding inclusion

#### Printing Integration

- **Bluetooth Connection**: Automatic printer detection
- **Format Optimization**: Thermal printer-specific formatting
- **Error Handling**: Print failure recovery
- **Offline Capability**: Digital ticket storage

### Key Components

#### Ticket Data Structure

```dart
class Ticket {
  String plateNumber;
  String region;
  String level;
  int seatCapacity;
  String tripId;
  String departure;
  String destination;
  String date;
  String time;
  String status;
  String employeeName;
}
```

#### Business Rules

- **Capacity Limits**: Cannot exceed vehicle seat capacity
- **Route Validation**: Only predefined routes allowed
- **Time Constraints**: Tickets valid for scheduled times
- **Duplicate Prevention**: Unique ticket identification

## Trip Management Module

### Overview

The trip module manages trip recording, synchronization, and historical data.

### Structure

```
lib/app/modules/sync/
├── bindings/sync_binding.dart
├── controllers/sync_controller.dart
└── views/sync_view.dart
```

### Business Logic

#### Trip Recording

1. **Data Collection**
   - Vehicle and route information
   - Passenger count and revenue
   - Actual distance traveled
   - Timestamp recording

2. **Local Storage**
   ```dart
   Future<void> saveTrip(TripModel trip) async {
     final box = Hive.box<TripModel>(HiveBoxes.tripBox);
     await box.add(trip);
     updateLocalTotals();
   }
   ```

3. **Synchronization Process**
   ```dart
   Future<void> syncTripsToServer() async {
     final trips = getUnsyncedTrips();
     for (final trip in trips) {
       await uploadTrip(trip);
       markAsSynced(trip);
     }
   }
   ```

#### Data Validation

- **Completeness Check**: All required fields present
- **Logical Validation**: Distance and time reasonable
- **Duplicate Prevention**: Prevent duplicate trip entries
- **Business Rules**: Revenue matches expected calculations

### Key Features

#### Filtering and Search

- **Vehicle-based filtering**
- **Date range selection**
- **Route-based search**
- **Status filtering (synced/unsynced)**

#### Bulk Operations

- **Batch synchronization**
- **Bulk deletion**
- **Export capabilities**

## Fleet Management Module

### Overview

The fleet module manages vehicle information, assignments, and maintenance tracking.

### Structure

```
lib/app/modules/vehicles/
├── bindings/vehicles_bindings.dart
├── controllers/vehicles_controllers.dart
└── views/vehicles_view.dart
```

### Business Logic

#### Vehicle Data Management

1. **Vehicle Registration**
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
     List<String> arrivalTerminals;
     List<String> tariffs;
   }
   ```

2. **Route Assignment**
   - Departure terminal association
   - Arrival terminal configuration
   - Tariff rate assignment

3. **Status Management**
   - Active/Inactive status
   - Maintenance scheduling
   - Assignment tracking

#### Data Synchronization

- **Incremental Updates**: Only changed data synced
- **Conflict Resolution**: Server data takes precedence
- **Offline Access**: Full vehicle data available offline

### Key Features

#### Vehicle Search and Filter

- **Plate number search**
- **Status filtering**
- **Association-based grouping**
- **Capacity range filtering**

#### Assignment Management

- **Terminal assignments**
- **Driver assignments**
- **Route configurations**

## Reporting Module

### Overview

The reporting module provides comprehensive reporting capabilities with PDF generation.

### Structure

```
lib/app/modules/localReport/
├── bindings/local_report_binding.dart
├── controllers/local_report_controller.dart
└── views/local_report_view.dart
```

### Business Logic

#### Report Generation

1. **Data Aggregation**
   ```dart
   Future<void> loadTripsFromHive() async {
     final tripBox = Hive.box<TripModel>(HiveBoxes.tripBox);
     final vehicleBox = Hive.box<VehicleModel>(HiveBoxes.vehiclesBox);

     final loadedTrips = tripBox.values.map((trip) {
       final vehicle = vehicleBox.values
           .firstWhereOrNull((v) => v.id == trip.vehicleId);

       return TripReportItem(
         departureName: getTerminalName(trip.departureTerminalId),
         arrivalName: getTerminalName(trip.arrivalTerminalId),
         plateNumber: vehicle?.plateNumber ?? 'Unknown',
         price: trip.tariff,
         serviceCharge: trip.serviceCharge,
         totalPrice: trip.totalPaid,
       );
     }).toList();
   }
   ```

2. **PDF Generation**
   ```dart
   Future<void> generatePDFReport() async {
     final pdf = pw.Document();

     pdf.addPage(pw.MultiPage(
       build: (context) => [
         pw.Table.fromTextArray(
           headers: ['Departure', 'Arrival', 'Plate Number', 'Price', 'Total'],
           data: filteredTrips.map((trip) => [
             trip.departureName,
             trip.arrivalName,
             trip.plateNumber,
             trip.price.toStringAsFixed(2),
             trip.totalPrice.toStringAsFixed(2),
           ]).toList(),
         ),
       ],
     ));

     final file = await pdf.save();
     // Save to device
   }
   ```

#### Report Types

1. **Trip Reports**
   - Daily trip summaries
   - Revenue analysis
   - Route performance

2. **Service Charge Reports**
   - Commission tracking
   - Employee performance
   - Financial summaries

3. **Fleet Reports**
   - Vehicle utilization
   - Maintenance schedules
   - Fuel efficiency

### Key Features

#### Filtering Capabilities

- **Date Range**: Custom date selection
- **Vehicle Filter**: Specific vehicle reports
- **Route Filter**: Terminal-based filtering
- **Amount Ranges**: Revenue-based filtering

#### Export Options

- **PDF Generation**: Formatted reports
- **CSV Export**: Raw data export
- **Email Sharing**: Direct report distribution

## Synchronization Module

### Overview

The synchronization module manages data synchronization between local storage and remote servers.

### Structure

```
lib/data/repositories/
└── sync_repository.dart
```

### Business Logic

#### Synchronization Strategy

1. **Offline-First Approach**
   ```dart
   Future<List<VehicleModel>> getVehicles() async {
     // Return local data immediately
     final localVehicles = getLocalVehicles();
     if (localVehicles.isNotEmpty) {
       return localVehicles;
     }

     // Sync if online
     if (await _isOnline) {
       await syncAllCompanyUserVehicles();
       return getLocalVehicles();
     }

     return localVehicles;
   }
   ```

2. **Incremental Synchronization**
   - Only sync changed data
   - Version-based conflict resolution
   - Efficient bandwidth usage

3. **Error Handling**
   ```dart
   Future<void> syncWithRetry(Function operation, {int maxRetries = 3}) async {
     for (int i = 0; i < maxRetries; i++) {
       try {
         await operation();
         return;
       } catch (e) {
         if (i == maxRetries - 1) rethrow;
         await Future.delayed(Duration(seconds: i + 1));
       }
     }
   }
   ```

#### Data Types Synchronized

- **Master Data**: Vehicles, terminals, commission rules
- **Transactional Data**: Trips, service charges, tickets
- **Reference Data**: User profiles, company settings

### Key Features

#### Progress Tracking

- **Real-time Progress**: Synchronization progress indicators
- **Error Reporting**: Detailed error messages
- **Retry Mechanisms**: Automatic retry for failed operations

#### Conflict Resolution

- **Server Priority**: Server data takes precedence
- **Manual Resolution**: User intervention for conflicts
- **Audit Trail**: Synchronization history

## Settings Module

### Overview

The settings module manages application configuration and user preferences.

### Business Logic

#### Configuration Management

1. **Environment Settings**
   - API endpoint configuration
   - Debug mode settings
   - Feature flags

2. **User Preferences**
   - Language selection
   - Theme preferences
   - Notification settings

3. **Device Settings**
   - Printer configuration
   - Storage management
   - Permission management

### Key Features

#### App Configuration

- **Version Information**: App version and build details
- **Storage Management**: Cache clearing and data management
- **Permission Settings**: Device permission management

#### User Management

- **Profile Management**: User information updates
- **Password Management**: Password change functionality
- **Session Management**: Logout and session control

---

**Document Version**: 1.0
**Last Updated**: November 2024
**Document Owner**: Oromia Transport Agency Development Team