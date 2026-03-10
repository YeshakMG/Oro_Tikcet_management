# API Documentation

This document provides comprehensive documentation for the Oro Ticket App API integration.

## Table of Contents

1. [API Overview](#api-overview)
2. [Authentication](#authentication)
3. [Core Endpoints](#core-endpoints)
4. [Data Synchronization](#data-synchronization)
5. [Error Handling](#error-handling)
6. [Rate Limiting](#rate-limiting)
7. [API Versioning](#api-versioning)

## API Overview

### Base Configuration

- **Base URL**: `http://196.189.247.242:4501/api`
- **Protocol**: HTTP/HTTPS
- **Data Format**: JSON
- **Authentication**: JWT Bearer Token
- **Rate Limit**: 1000 requests per hour per user

### Request/Response Format

#### Request Headers
```http
Content-Type: application/json
Authorization: Bearer {jwt_token}
Accept: application/json
```

#### Response Format
```json
{
  "status": "success|error",
  "message": "Response message",
  "data": { ... },
  "pagination": { ... }
}
```

## Authentication

### Login Endpoint

**POST** `/auth/company-user/login`

Authenticates a company user and returns JWT token.

#### Request Body
```json
{
  "email": "user@company.com",
  "password": "secure_password"
}
```

#### Response
```json
{
  "status": "success",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": "user_123",
      "email": "user@company.com",
      "full_name": "John Doe",
      "role_id": "conductor",
      "company_id": "company_456",
      "company_name": "ABC Transport"
    }
  }
}
```

### Profile Endpoint

**GET** `/auth/company-user/profile`

Retrieves authenticated user's profile and associated data.

#### Response
```json
{
  "status": "success",
  "data": {
    "user": { ... },
    "terminal": {
      "id": "terminal_123",
      "name": "Main Station",
      "status": "active"
    },
    "permissions": ["ticket.create", "trip.record"]
  }
}
```

## Core Endpoints

### Vehicle Management

#### Get Company Vehicles

**GET** `/vehicles/company-user/my-vehicles`

Retrieves all vehicles assigned to the user's company.

##### Query Parameters
- `page` (optional): Page number for pagination
- `per_page` (optional): Items per page (default: 50)

##### Response
```json
{
  "status": "success",
  "data": {
    "vehicles": [
      {
        "id": "vehicle_123",
        "plate_number": "AA-1234",
        "plate_region": "Addis Ababa",
        "fleetType": {
          "name": "Bus"
        },
        "vehicleLevel": {
          "name": "Standard"
        },
        "association": {
          "name": "ABC Association"
        },
        "seat_capacity": 50,
        "status": "active",
        "vehicleTerminalDestinations": [
          {
            "terminalDestination": {
              "arrivalTerminal": {
                "id": "terminal_456",
                "name": "Destination City",
                "tariff": 150.00,
                "distance": 250.5
              }
            }
          }
        ]
      }
    ],
    "pagination": {
      "current_page": 1,
      "last_page": 5,
      "per_page": 50,
      "total": 250
    }
  }
}
```

### Trip Management

#### Create Trip

**POST** `/trips`

Records a completed trip with all associated data.

##### Request Body
```json
{
  "vehicle_id": "vehicle_123",
  "date_and_time": "2024-11-27T10:30:00Z",
  "km": 250.5,
  "tariff": 150.00,
  "service_charge": 15.00,
  "total_paid": 165.00,
  "departure_terminal_id": "terminal_123",
  "arrival_terminal_id": "terminal_456",
  "company_id": "company_456",
  "employee_id": "user_123"
}
```

##### Response
```json
{
  "status": "success",
  "data": {
    "trip": {
      "id": "trip_789",
      "vehicle_id": "vehicle_123",
      "created_at": "2024-11-27T10:35:00Z"
    }
  }
}
```

#### Get Company Trips

**GET** `/trips/company-user`

Retrieves trips for the user's company with filtering options.

##### Query Parameters
- `start_date` (optional): Filter by start date
- `end_date` (optional): Filter by end date
- `vehicle_id` (optional): Filter by specific vehicle
- `page` (optional): Page number

### Service Charge Management

#### Create Service Charge

**POST** `/service-charges`

Records service charges collected during ticket sales.

##### Request Body
```json
{
  "departure_terminal_id": "terminal_123",
  "date_and_time": "2024-11-27T10:30:00Z",
  "service_charge_amount": 15.00,
  "employee_id": "user_123",
  "company_id": "company_456"
}
```

### Commission Rules

#### Get Commission Rules

**GET** `/commission-rules`

Retrieves commission rules applicable to the company.

##### Response
```json
{
  "status": "success",
  "data": [
    {
      "id": "rule_123",
      "company_id": "company_456",
      "commission_rate": 0.10,
      "description": "Standard commission rate",
      "created_at": "2024-01-01T00:00:00Z"
    }
  ]
}
```

## Data Synchronization

### Synchronization Strategy

The app implements an offline-first architecture with the following sync patterns:

1. **Real-time Sync**: Immediate sync when online
2. **Batch Sync**: Manual bulk synchronization
3. **Background Sync**: Automated periodic sync

### Sync Endpoints

#### Bulk Trip Sync

**POST** `/trips/bulk`

Synchronizes multiple trips in a single request.

##### Request Body
```json
{
  "trips": [
    {
      "vehicle_id": "vehicle_123",
      "date_and_time": "2024-11-27T10:30:00Z",
      "km": 250.5,
      "tariff": 150.00,
      "service_charge": 15.00,
      "total_paid": 165.00,
      "departure_terminal_id": "terminal_123",
      "arrival_terminal_id": "terminal_456",
      "company_id": "company_456",
      "employee_id": "user_123"
    }
  ]
}
```

#### Bulk Service Charge Sync

**POST** `/service-charges/bulk`

Synchronizes multiple service charges.

##### Request Body
```json
{
  "service_charges": [
    {
      "departure_terminal_id": "terminal_123",
      "date_and_time": "2024-11-27T10:30:00Z",
      "service_charge_amount": 15.00,
      "employee_id": "user_123",
      "company_id": "company_456"
    }
  ]
}
```

## Error Handling

### HTTP Status Codes

- **200**: Success
- **201**: Created
- **400**: Bad Request
- **401**: Unauthorized
- **403**: Forbidden
- **404**: Not Found
- **422**: Validation Error
- **429**: Too Many Requests
- **500**: Internal Server Error

### Error Response Format

```json
{
  "status": "error",
  "message": "Validation failed",
  "errors": [
    {
      "field": "email",
      "message": "Email is required"
    }
  ]
}
```

### Common Error Scenarios

#### Authentication Errors

```json
{
  "status": "error",
  "message": "Invalid credentials",
  "code": "AUTH_INVALID_CREDENTIALS"
}
```

#### Validation Errors

```json
{
  "status": "error",
  "message": "Validation failed",
  "errors": [
    {
      "field": "plate_number",
      "message": "Plate number already exists"
    }
  ]
}
```

#### Network Errors

```json
{
  "status": "error",
  "message": "Service temporarily unavailable",
  "code": "SERVICE_UNAVAILABLE"
}
```

## Rate Limiting

### Rate Limit Headers

The API includes rate limiting information in response headers:

```
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1638360000
X-RateLimit-Retry-After: 3600
```

### Rate Limit Exceeded Response

```json
{
  "status": "error",
  "message": "Rate limit exceeded",
  "code": "RATE_LIMIT_EXCEEDED",
  "retry_after": 3600
}
```

## API Versioning

### Version Strategy

- **URL Path Versioning**: `/api/v1/endpoint`
- **Header Versioning**: `Accept: application/vnd.api.v1+json`
- **Current Version**: v1 (default)

### Version Compatibility

- **Backward Compatibility**: Maintained for 2 major versions
- **Deprecation Notices**: 3 months advance notice
- **Migration Guides**: Provided for breaking changes

### Version Headers

```http
Accept: application/vnd.oroticket.v1+json
X-API-Version: 1.0.0
```

## Data Types and Validation

### Common Data Types

#### DateTime Format
- **Format**: ISO 8601 (`YYYY-MM-DDTHH:mm:ssZ`)
- **Timezone**: UTC
- **Example**: `2024-11-27T10:30:00Z`

#### Currency Format
- **Currency**: Ethiopian Birr (ETB)
- **Format**: Decimal with 2 places
- **Example**: `150.00`

#### ID Format
- **Format**: `{resource_type}_{uuid}`
- **Example**: `vehicle_123e4567-e89b-12d3-a456-426614174000`

### Validation Rules

#### Vehicle Validation
- Plate number: Required, unique per company
- Seat capacity: Integer, 1-100
- Status: Enum [active, inactive, maintenance]

#### Trip Validation
- Vehicle ID: Must exist and be active
- Terminals: Must be valid route combination
- Amounts: Must be positive numbers
- Date/Time: Must be current or future

#### Service Charge Validation
- Amount: Must be positive
- Employee ID: Must be valid company user
- Terminal ID: Must be assigned to user

## Security Considerations

### Authentication Security

- **Token Expiry**: 24 hours
- **Refresh Tokens**: Not implemented (use re-login)
- **Secure Storage**: Tokens stored in encrypted storage

### Data Security

- **Encryption**: HTTPS required
- **Input Validation**: Server-side validation
- **SQL Injection**: Parameterized queries
- **XSS Protection**: Input sanitization

### API Security

- **CORS**: Configured for mobile app origins
- **CSRF**: Not applicable (JWT authentication)
- **Rate Limiting**: Per-user and per-IP limits
- **Logging**: All API calls logged for audit

## Testing and Development

### Sandbox Environment

- **Base URL**: `https://api-sandbox.oroticket.et/api`
- **Data**: Isolated test data
- **Rate Limits**: Relaxed for development

### API Testing Tools

#### Postman Collection
```json
{
  "info": {
    "name": "Oro Ticket API",
    "version": "1.0.0"
  },
  "variable": [
    {
      "key": "base_url",
      "value": "http://196.189.247.242:4501/api"
    },
    {
      "key": "token",
      "value": ""
    }
  ]
}
```

#### cURL Examples

```bash
# Login
curl -X POST http://196.189.247.242:4501/api/auth/company-user/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@company.com","password":"password"}'

# Get Vehicles
curl -X GET "http://196.189.247.242:4501/api/vehicles/company-user/my-vehicles" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Monitoring and Analytics

### API Metrics

- **Response Times**: Average and percentile metrics
- **Error Rates**: Per endpoint error tracking
- **Usage Patterns**: Request volume and patterns
- **Performance**: Database query performance

### Logging

- **Request Logs**: All API requests logged
- **Error Logs**: Detailed error information
- **Audit Logs**: Sensitive operation tracking
- **Performance Logs**: Slow query identification

---

**API Version**: v1.0.0
**Last Updated**: November 2024
**Contact**: api@orotransport.et