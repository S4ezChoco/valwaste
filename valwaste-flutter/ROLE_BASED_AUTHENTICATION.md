# Role-Based Authentication System

This document explains the role-based authentication system implemented in the ValWaste Flutter app.

## Overview

The app now supports different user roles with specific features and access levels:

1. **Resident** - Regular users who can request waste collection
2. **Barangay Official** - Officials who can manage reports and schedules
3. **Driver** - Drivers who handle waste collection
4. **Collector** - Additional collection staff
5. **Administrator** - System administrators with full access

## User Roles and Features

### Resident
- **Dashboard**: Quick actions for collection requests, schedule viewing, recycling guide
- **Features**: 
  - Request waste collection
  - View collection schedule
  - Access recycling guide
  - View collection map
  - Check collection history
  - Receive notifications

### Barangay Official
- **Dashboard**: Statistics, request management, route planning
- **Features**:
  - Review collection requests
  - Manage collection schedules
  - Route planning and optimization
  - View collection reports
  - Monitor collection statistics

### Driver
- **Dashboard**: Route information, collection progress, status updates
- **Features**:
  - View assigned routes
  - Mark collections as complete
  - Report issues
  - View collection schedule
  - Track collection progress

### Collector
- **Dashboard**: Collection tasks, work progress, issue reporting
- **Features**:
  - Mark collections complete
  - View collection routes
  - Report issues
  - View work schedule
  - Track collection progress

### Administrator
- **Dashboard**: System overview, user management, analytics
- **Features**:
  - User management
  - System analytics
  - Review requests
  - System configuration
  - Full access to all features

## Implementation Details

### User Model
The `UserModel` class now includes a `role` field with the `UserRole` enum:

```dart
enum UserRole {
  resident,
  barangayOfficial,
  driver,
  collector,
  administrator,
}
```

### Authentication Service
The `FirebaseAuthService` has been updated to:
- Support role-based registration
- Validate user roles during login
- Store role information in Firestore

### Home Screen
The `HomeScreen` dynamically shows different dashboards based on user role:
- Different navigation items
- Role-specific features
- Customized UI elements

## Testing the System

### Creating Test Users
1. Use the "Create Test Users with Roles" button in the login screen
2. This creates test users for each role:
   - `resident@test.com` (Resident)
   - `official@test.com` (Barangay Official)
   - `driver@test.com` (Driver)
   - `collector@test.com` (Collector)

### Manual Registration
1. Go to the registration screen
2. Fill in user details
3. Select the appropriate role from the dropdown
4. Complete registration

### Login Testing
1. Login with any test user
2. The app will show the appropriate dashboard for that role
3. Navigation items will be customized based on the role

## Database Structure

Users are stored in Firestore with the following structure:

```json
{
  "name": "User Name",
  "email": "user@example.com",
  "phone": "1234567890",
  "address": "User Address",
  "barangay": "Valenzuela City",
  "role": "Resident",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

## Role Management

### Adding New Roles
1. Add the new role to the `UserRole` enum
2. Update the `_parseRole` method in `UserModel`
3. Update the `roleString` getter
4. Add role-specific screens and navigation
5. Update the home screen initialization

### Role Permissions
Role permissions are enforced at the UI level:
- Different navigation items for each role
- Role-specific dashboards
- Feature access based on role

## Security Considerations

- Role information is stored in Firestore
- Role validation happens during login
- UI elements are filtered based on user role
- Consider implementing server-side role validation for sensitive operations

## Future Enhancements

1. **Server-side Role Validation**: Implement role checks on the backend
2. **Role-based API Access**: Restrict API endpoints based on user role
3. **Dynamic Permissions**: Allow administrators to modify role permissions
4. **Audit Logging**: Track role-based actions for security
5. **Multi-role Support**: Allow users to have multiple roles

## Troubleshooting

### Common Issues

1. **Role not showing after login**
   - Check if the user document exists in Firestore
   - Verify the role field is properly set
   - Check the role parsing logic

2. **Wrong dashboard showing**
   - Verify the user's role in Firestore
   - Check the role enum values
   - Ensure the home screen initialization logic is correct

3. **Registration role not saving**
   - Check the registration form role selection
   - Verify the Firebase Auth Service registration method
   - Check Firestore write permissions

### Debug Tools

- Use the debug buttons in the login screen to test functionality
- Check Firebase console for user documents
- Use the "Check User in Firestore" button to verify user data




