# Oro Ticket App - User Guide

This comprehensive user guide provides step-by-step instructions for using the Oro Ticket App effectively.

## Table of Contents

1. [Getting Started](#getting-started)
2. [First-Time Setup](#first-time-setup)
3. [Daily Operations](#daily-operations)
4. [Ticket Management](#ticket-management)
5. [Trip Recording](#trip-recording)
6. [Reporting](#reporting)
7. [Data Synchronization](#data-synchronization)
8. [Troubleshooting](#troubleshooting)
9. [Best Practices](#best-practices)

## Getting Started

### System Requirements

- **Android Device**: Version 6.0 or higher
- **iOS Device**: Version 11.0 or higher
- **Storage**: Minimum 100MB free space
- **Network**: Internet connection for synchronization
- **Bluetooth**: For thermal printer connectivity

### App Installation

1. Download the Oro Ticket App from your company's app store
2. Install the application on your device
3. Grant necessary permissions when prompted:
   - Location access
   - Bluetooth connectivity
   - Storage access
   - Camera (for QR code scanning)

## First-Time Setup

### Initial Password Setup

When launching the app for the first time:

1. **Password Reset Screen**
   - Enter a strong password (minimum 8 characters)
   - Confirm your password
   - Tap "Reset Password"

2. **Login Screen**
   - Enter your company email address
   - Enter your password
   - Tap "Sign In"

### Profile Synchronization

After successful login, the app will:

- Download your user profile
- Sync company information
- Load assigned vehicles and routes
- Download commission rules
- Update local data

**Note**: This process requires an internet connection. If offline, you'll be prompted to connect.

## Daily Operations

### Morning Setup

1. **Launch the App**
   - Open Oro Ticket App
   - Authenticate if required

2. **Check Dashboard**
   - Review today's service charges
   - Check assigned vehicles
   - Verify data synchronization status

3. **Prepare Equipment**
   - Ensure thermal printer is connected
   - Check printer paper supply
   - Verify Bluetooth connectivity

### Ticket Sales Process

#### Step 1: Access Ticket Creation

1. From the dashboard, tap "New Ticket" or navigate to the Ticket module
2. The app will display available options

#### Step 2: Select Vehicle

1. Choose from your assigned vehicles
2. The app will load vehicle-specific information:
   - Seat capacity
   - Available routes
   - Current tariffs

#### Step 3: Configure Route

1. **Departure Terminal**: Automatically set based on your assignment
2. **Arrival Terminal**: Select from available destinations
3. **Passenger Count**: Enter number of passengers (1-50)

#### Step 4: Review Charges

The app automatically calculates:

- **Base Tariff**: Distance-based pricing
- **Service Charge**: Commission-based fee
- **Total Payment**: Sum of tariff and service charge

#### Step 5: Print Ticket

1. Connect to thermal printer via Bluetooth
2. Tap "Print Ticket"
3. The system generates and prints:
   - Company header
   - Ticket details
   - QR code for verification
   - Ethiopian date/time

#### Step 6: Record Trip

1. After printing, tap "Record Trip"
2. Confirm trip details
3. Data is stored locally and marked for synchronization

### End-of-Day Procedures

1. **Sync All Data**
   - Navigate to Sync module
   - Tap "Sync All Data"
   - Wait for confirmation

2. **Generate Reports**
   - Access Reports section
   - Generate daily summary
   - Export or share as needed

3. **Secure Logout**
   - Ensure all data is synced
   - Tap logout (app prevents logout with unsynced data)

## Ticket Management

### Ticket Information Display

Each ticket contains:

- **Company Information**: Logo, name, contact details
- **Travel Details**: From, To, Date, Time
- **Vehicle Information**: Plate number, level, capacity
- **Pricing**: Tariff, service charge, total
- **Verification**: QR code and unique ticket number

### Ticket Formats

#### Standard Ticket Format
```
OROMIA TRANSPORT AGENCY
===============================
Company: [Company Name]
Phone: [Contact Number]
Date: [Ethiopian Date] [Time]
From: [Departure City]
To: [Arrival City]
Vehicle: [Plate Number] ([Region])
Level: [Vehicle Level]
Seat: [Seat Number]
Distance: [Distance] km
Tariff: [Amount] ETB
Service Charge: [Amount] ETB
Total: [Total] ETB
===============================
Free-call: 8556
```

### Offline Ticket Issuance

When internet is unavailable:

1. All ticket creation works normally
2. Tickets are stored locally
3. Synchronization occurs when online
4. Digital receipts available if printing fails

## Trip Recording

### Manual Trip Entry

1. **Access Trip Module**
   - Navigate to Trip section
   - Tap "Add Trip"

2. **Enter Trip Details**
   - Select vehicle
   - Choose route (departure/arrival)
   - Enter actual distance traveled
   - Record passenger count
   - Enter revenue collected

3. **Save and Sync**
   - Save trip locally
   - Sync when online

### Automatic Trip Recording

For integrated systems:

- GPS tracking (future feature)
- Automatic route detection
- Real-time revenue calculation

## Reporting

### Available Reports

#### Daily Trip Report

1. **Access**: Reports → Trip Reports → Daily
2. **Filters**: Date range, vehicle, route
3. **Content**:
   - Trip count
   - Total revenue
   - Distance traveled
   - Service charges collected

#### Service Charge Report

1. **Access**: Reports → Service Charges → Daily
2. **Filters**: Date range, employee
3. **Content**:
   - Total service charges
   - Commission earned
   - Payment summaries

#### Vehicle Utilization Report

1. **Access**: Reports → Fleet → Utilization
2. **Filters**: Date range, vehicle
3. **Content**:
   - Trips completed
   - Revenue generated
   - Distance traveled
   - Fuel efficiency

### Report Generation

#### PDF Export

1. Apply desired filters
2. Tap "Generate PDF"
3. Choose save location
4. PDF includes:
   - Company header
   - Report data in tabular format
   - Summary statistics
   - Generation timestamp

#### Data Export

1. Select export format (CSV, Excel)
2. Choose date range
3. Export includes raw data for analysis

## Data Synchronization

### Manual Synchronization

1. **Access Sync Module**
   - Navigate to Sync section
   - View synchronization status

2. **Sync Options**
   - **Sync All**: Complete data synchronization
   - **Sync Trips**: Upload trip data only
   - **Sync Charges**: Upload service charges only
   - **Download Data**: Refresh local data

3. **Monitor Progress**
   - Progress indicators
   - Success/error notifications
   - Retry failed operations

### Automatic Synchronization

- **Background Sync**: Occurs when app is online
- **Login Sync**: Data refresh after authentication
- **Periodic Sync**: Regular data updates (configurable)

### Sync Status Indicators

- **🟢 Green**: Fully synchronized
- **🟡 Yellow**: Partial synchronization
- **🔴 Red**: Synchronization failed
- **⚪ Gray**: Offline mode

## Troubleshooting

### Common Issues and Solutions

#### Login Problems

**Issue**: "Invalid credentials"
**Solution**:
- Verify email and password
- Check internet connection
- Contact administrator for password reset

**Issue**: "Account locked"
**Solution**:
- Wait 30 minutes for automatic unlock
- Contact IT support

#### Printing Issues

**Issue**: "Printer not found"
**Solution**:
- Check Bluetooth is enabled
- Ensure printer is powered on
- Verify printer compatibility
- Try reconnecting device

**Issue**: "Paper jam"
**Solution**:
- Clear paper jam
- Check paper quality
- Realign paper

#### Synchronization Problems

**Issue**: "Sync failed"
**Solution**:
- Check internet connection
- Verify server availability
- Retry synchronization
- Contact technical support

**Issue**: "Data conflicts"
**Solution**:
- Review conflicting data
- Choose appropriate resolution
- Save changes

#### App Performance

**Issue**: "App running slow"
**Solution**:
- Close other applications
- Clear app cache
- Restart device
- Update app to latest version

### Error Messages

#### Authentication Errors

- **"Token expired"**: Re-login required
- **"Invalid session"**: Restart app and login
- **"Account suspended"**: Contact administrator

#### Network Errors

- **"No internet connection"**: Work offline, sync later
- **"Server timeout"**: Retry operation
- **"Service unavailable"**: Try again later

#### Data Errors

- **"Validation failed"**: Check entered data
- **"Duplicate entry"**: Verify unique constraints
- **"Data corrupted"**: Clear cache and re-sync

## Best Practices

### Daily Operations

1. **Morning Preparation**
   - Charge device fully
   - Test printer connectivity
   - Sync data before starting

2. **During Operations**
   - Keep device secure
   - Backup important data
   - Monitor battery level

3. **End of Day**
   - Sync all transactions
   - Generate daily reports
   - Secure logout

### Data Management

1. **Regular Synchronization**
   - Sync data multiple times daily
   - Don't accumulate unsynced data
   - Verify sync completion

2. **Data Backup**
   - Export important reports
   - Keep physical records
   - Use secure storage

### Security Practices

1. **Device Security**
   - Use strong passwords
   - Enable device lock
   - Don't share login credentials

2. **Data Security**
   - Handle customer data carefully
   - Report security incidents
   - Follow company policies

### Performance Optimization

1. **App Maintenance**
   - Keep app updated
   - Clear cache regularly
   - Restart app daily

2. **Device Maintenance**
   - Keep sufficient storage space
   - Close unused applications
   - Regular device restarts

## Advanced Features

### Ethiopian Calendar Integration

- **Date Display**: All dates shown in Ethiopian calendar
- **Day Names**: Afaan Oromo day names used
- **Time Format**: 12-hour format with AM/PM

### Multi-language Support

- **Primary Language**: English
- **Secondary Language**: Afaan Oromo
- **Language Switching**: Settings → Language

### Offline Capabilities

- **Full Functionality**: All features work offline
- **Data Queuing**: Operations queued for sync
- **Conflict Resolution**: Automatic conflict handling

### Integration Features

- **GPS Tracking**: Location-based features (future)
- **QR Code Scanning**: Ticket verification
- **NFC Support**: Contactless operations (future)

## Support and Contact

### Technical Support

- **Email**: support@orotransport.et
- **Phone**: +251-XXX-XXXX
- **Hours**: Monday-Friday, 8:00 AM - 5:00 PM EAT

### Emergency Support

- **Critical Issues**: Call emergency hotline
- **System Down**: Contact IT immediately
- **Data Loss**: Report within 24 hours

### Training Resources

- **User Manual**: This document
- **Video Tutorials**: Available on company portal
- **Live Training**: Scheduled sessions available

---

**Guide Version**: 1.0
**Last Updated**: November 2024
**Target Audience**: Transport Company Staff
**Document Owner**: Oromia Transport Agency Training Department