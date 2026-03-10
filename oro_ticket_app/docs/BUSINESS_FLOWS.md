# Business Flows Documentation

This document outlines all major business processes and workflows in the Oro Ticket App system.

## Table of Contents

1. [User Authentication Flow](#1-user-authentication-flow)
2. [Ticket Booking and Issuance Flow](#2-ticket-booking-and-issuance-flow)
3. [Trip Management Flow](#3-trip-management-flow)
4. [Data Synchronization Flow](#4-data-synchronization-flow)
5. [Reporting and Analytics Flow](#5-reporting-and-analytics-flow)
6. [Fleet Management Flow](#6-fleet-management-flow)
7. [Service Charge Management Flow](#7-service-charge-management-flow)
8. [Commission Management Flow](#8-commission-management-flow)

## 1. User Authentication Flow

### Primary Flow: First-Time User Setup

```
App Installation → First Launch → Password Reset → Authentication → Dashboard Access
```

#### Detailed Steps:

1. **App Installation**
   - User downloads and installs Oro Ticket App
   - App detects first installation via Hive storage check

2. **Password Reset Screen**
   - App shows reset password screen for initial setup
   - User creates strong password
   - Password stored securely in device storage

3. **Authentication Screen**
   - User enters email and password
   - App validates credentials against API
   - JWT token received and stored securely

4. **Profile Synchronization**
   - Fetch user profile data from server
   - Load company information and permissions
   - Sync critical data (vehicles, terminals, commission rules)

5. **Dashboard Access**
   - User redirected to main dashboard
   - App loads user's assigned vehicles and routes

### Alternative Flow: Returning User

```
App Launch → Authentication Check → Dashboard (if valid) → Re-authentication (if expired)
```

#### Session Management:

- **Token Validation**: Automatic token expiry check
- **Offline Login**: Cached credentials for offline access
- **Forced Logout**: Unsynced data prevents logout

## 2. Ticket Booking and Issuance Flow

### Primary Flow: Standard Ticket Issuance

```
Dashboard → Vehicle Selection → Route Selection → Charge Calculation → Ticket Printing → Trip Recording
```

#### Detailed Steps:

1. **Vehicle Selection**
   - User selects from assigned company vehicles
   - App validates vehicle availability and status
   - Loads vehicle-specific tariffs and routes

2. **Route Configuration**
   - Select departure terminal (auto-assigned based on user profile)
   - Choose arrival terminal from available destinations
   - System validates route availability

3. **Dynamic Charge Calculation**
   ```
   Base Tariff = Distance × Rate per KM
   Service Charge = Base Tariff × Commission Rate
   Total Payment = Base Tariff + Service Charge
   ```

4. **Ticket Generation**
   - System generates unique ticket data
   - Formats ticket with Ethiopian date/time
   - Includes QR code for verification

5. **Thermal Printing**
   - Connects to Bluetooth thermal printer
   - Prints formatted ticket with company branding
   - Multiple copies based on seat count

6. **Trip Data Recording**
   - Stores trip details in local Hive database
   - Marks trip as pending synchronization
   - Updates daily service charge totals

### Edge Cases:

- **Offline Operation**: All steps work without internet
- **Printer Unavailable**: Manual ticket issuance with digital record
- **Invalid Route**: System prevents invalid terminal combinations
- **Vehicle Unavailable**: Real-time vehicle status checking

## 3. Trip Management Flow

### Daily Trip Operations

```
Pre-Trip Preparation → Trip Execution → Post-Trip Recording → Data Synchronization
```

#### Detailed Steps:

1. **Pre-Trip Preparation**
   - Driver checks assigned vehicle
   - Reviews scheduled routes and timings
   - Verifies vehicle condition and fuel

2. **Trip Execution**
   - Passenger boarding and ticket collection
   - Route navigation and timing adherence
   - Emergency handling procedures

3. **Post-Trip Recording**
   - Record actual trip metrics (distance, time, passengers)
   - Update vehicle status and maintenance needs
   - Calculate actual revenue vs. projected

4. **Data Synchronization**
   - Upload trip data to central server
   - Receive updated schedules and assignments
   - Sync with dispatch system

### Trip Status Management:

- **Scheduled**: Planned trips in system
- **In Progress**: Currently active trips
- **Completed**: Successfully finished trips
- **Cancelled**: Cancelled or aborted trips

## 4. Data Synchronization Flow

### Offline-First Synchronization Strategy

```
Local Operation → Connectivity Detection → Data Sync → Conflict Resolution → Confirmation
```

#### Synchronization Types:

1. **Real-time Sync** (When Online)
   - Automatic background synchronization
   - Immediate data upload/download
   - Real-time conflict detection

2. **Batch Sync** (Manual Trigger)
   - User-initiated synchronization
   - Bulk data transfer
   - Progress indicators and error handling

3. **Scheduled Sync** (Automated)
   - Regular interval synchronization
   - Low-priority background processing
   - Bandwidth-aware scheduling

#### Data Synchronization Categories:

- **Critical Data**: Vehicles, terminals, commission rules
- **Transactional Data**: Trips, service charges, tickets
- **Reference Data**: User profiles, company settings

#### Conflict Resolution Strategies:

- **Server Wins**: Server data takes precedence
- **Client Wins**: Local changes override server
- **Manual Resolution**: User intervention required
- **Merge Strategy**: Intelligent data merging

## 5. Reporting and Analytics Flow

### Report Generation Process

```
Data Collection → Filtering → Processing → PDF Generation → Export/Distribution
```

#### Report Types:

1. **Trip Reports**
   - Daily trip summaries
   - Route performance analysis
   - Revenue reports by vehicle/route

2. **Service Charge Reports**
   - Daily service charge summaries
   - Employee performance tracking
   - Commission calculations

3. **Fleet Utilization Reports**
   - Vehicle usage statistics
   - Maintenance scheduling
   - Fuel consumption analysis

4. **Financial Reports**
   - Revenue analysis
   - Commission payouts
   - Profit/loss statements

#### Report Generation Steps:

1. **Data Aggregation**
   - Collect data from local storage
   - Apply date/time filters
   - Group by relevant categories

2. **Data Processing**
   - Calculate totals and averages
   - Apply business rules
   - Format for presentation

3. **PDF Generation**
   - Create formatted PDF documents
   - Include charts and tables
   - Add company branding

4. **Export Options**
   - Save to device storage
   - Email distribution
   - Cloud storage upload

## 6. Fleet Management Flow

### Vehicle Lifecycle Management

```
Vehicle Acquisition → Registration → Assignment → Operation → Maintenance → Decommissioning
```

#### Detailed Steps:

1. **Vehicle Registration**
   - Enter vehicle details (plate number, capacity, type)
   - Associate with transport company
   - Configure available routes and terminals

2. **Route Assignment**
   - Assign departure terminals
   - Configure arrival destinations
   - Set tariff rates per route

3. **Operational Management**
   - Track daily assignments
   - Monitor vehicle status
   - Record maintenance schedules

4. **Performance Tracking**
   - Monitor fuel efficiency
   - Track revenue generation
   - Analyze route profitability

5. **Maintenance Management**
   - Schedule regular maintenance
   - Track repair history
   - Monitor vehicle health

## 7. Service Charge Management Flow

### Commission Calculation and Tracking

```
Trip Completion → Charge Calculation → Daily Aggregation → Synchronization → Payout Processing
```

#### Service Charge Components:

1. **Base Calculation**
   ```
   Service Charge = Trip Tariff × Commission Rate
   ```

2. **Aggregation Levels**
   - Per trip charges
   - Daily totals per employee
   - Weekly/monthly summaries

3. **Tracking and Auditing**
   - Real-time charge updates
   - Historical data preservation
   - Audit trail maintenance

4. **Payout Processing**
   - Commission calculation
   - Payment scheduling
   - Financial reporting

## 8. Commission Management Flow

### Commission Rule Administration

```
Rule Definition → Employee Assignment → Application → Monitoring → Adjustment
```

#### Commission Rule Types:

1. **Percentage-based**: Fixed percentage of ticket price
2. **Tiered**: Different rates based on volume/sales
3. **Route-based**: Different rates per route or terminal
4. **Time-based**: Seasonal or time-specific rates

#### Rule Management Process:

1. **Rule Creation**
   - Define commission parameters
   - Set applicability criteria
   - Configure calculation methods

2. **Employee Assignment**
   - Link rules to user roles
   - Set effective dates
   - Configure overrides

3. **Application and Calculation**
   - Automatic rule application
   - Real-time commission calculation
   - Transparent fee disclosure

4. **Monitoring and Adjustment**
   - Performance tracking
   - Rule effectiveness analysis
   - Periodic adjustments

## Business Rules and Constraints

### Ticket Issuance Rules

- **Vehicle Capacity**: Cannot exceed registered seat capacity
- **Route Validation**: Only predefined routes allowed
- **Time Windows**: Tickets valid for scheduled trip times
- **Duplicate Prevention**: Unique ticket numbers per trip

### Financial Rules

- **Commission Limits**: Maximum commission rates enforced
- **Tax Calculations**: Automatic tax application where required
- **Currency Handling**: Ethiopian Birr (ETB) as base currency
- **Rounding Rules**: Consistent rounding for financial calculations

### Operational Rules

- **Session Management**: Automatic logout after inactivity
- **Data Retention**: Configurable data retention periods
- **Backup Requirements**: Regular data backup procedures
- **Audit Requirements**: Complete audit trail for all transactions

## Error Handling and Recovery

### Common Error Scenarios

1. **Network Failures**
   - Automatic retry mechanisms
   - Offline mode activation
   - Data queuing for later sync

2. **Printer Errors**
   - Alternative ticket formats
   - Digital ticket options
   - Error logging and reporting

3. **Data Conflicts**
   - Conflict detection algorithms
   - User notification and resolution
   - Automatic merge strategies

4. **Authentication Failures**
   - Token refresh mechanisms
   - Offline authentication fallback
   - Secure credential recovery

## Performance Considerations

### System Performance Requirements

- **Response Times**: < 2 seconds for UI interactions
- **Sync Performance**: < 30 seconds for data synchronization
- **Storage Efficiency**: Optimized local data storage
- **Battery Usage**: Minimal impact on device battery

### Scalability Considerations

- **Data Volume**: Support for large vehicle fleets
- **Concurrent Users**: Multi-user operation support
- **Network Efficiency**: Bandwidth-optimized synchronization
- **Storage Management**: Automatic data cleanup and archiving

---

**Document Version**: 1.0
**Last Updated**: November 2024
**Business Owner**: Oromia Transport Agency Operations Department