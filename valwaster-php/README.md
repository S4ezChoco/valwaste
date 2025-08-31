# ValWaste Admin Panel

A PHP-based administration panel for the ValWaste waste management system.

## Features

- **Dashboard**: Overview with statistics, interactive map, recent reports, and announcements
- **User Management**: Manage administrators, residents, collectors, and drivers (placeholder)
- **Report Management**: View and respond to community reports (placeholder)
- **Truck Schedule**: Manage collection routes and schedules (placeholder)
- **Attendance**: Track staff attendance and working hours (placeholder)
- **Firebase Integration**: Authentication and Firestore database
- **Responsive Design**: Works on desktop and mobile devices

## Setup Instructions

1. **Server Requirements**:
   - PHP 7.4 or higher
   - Web server (Apache/Nginx)
   - HTTPS (required for Firebase)

2. **Installation**:
   - Copy the `valwaster-php` folder to your web server
   - Ensure the server supports HTTPS (Firebase requires it)
   - Configure your web server to serve the files

3. **Firebase Configuration**:
   - The Firebase configuration is already set up in the code
   - Authentication and Firestore are configured and ready to use

4. **Access the Application**:
   - Navigate to your domain/valwaster-php/
   - You'll be redirected to the login page
   - Register a new administrator account or login with existing credentials

## File Structure

```
valwaster-php/
├── assets/
│   ├── css/
│   │   └── styles.css          # Main stylesheet
│   └── js/
│       └── auth.js             # Firebase authentication
├── components/
│   └── sidebar.php             # Reusable sidebar component
├── config/
│   └── firebase-config.js      # Firebase configuration
├── attendance.php              # Attendance page (placeholder)
├── dashboard.php               # Main dashboard
├── index.php                   # Entry point (redirects to login)
├── login.php                   # Login page
├── register.php                # Registration page
├── report-management.php       # Report management (placeholder)
├── truck-schedule.php          # Truck schedule (placeholder)
├── user-management.php         # User management (placeholder)
└── README.md                   # This file
```

## Authentication

- Users register with first name, surname, email, and password
- All registered users automatically get "Administrator" role
- Firebase handles authentication and stores user data in Firestore
- Session management uses localStorage for client-side state

## Design

The design is based on the reference ValWaste admin interface with:
- Green color scheme (#3AC84D primary)
- Clean, modern card-based layout
- Responsive sidebar navigation
- Interactive OpenStreetMap integration
- Consistent typography and spacing

## Development Notes

- Uses ES6 modules for Firebase integration
- Responsive design works on mobile and desktop
- OpenStreetMap integration for truck tracking
- All placeholder pages are ready for future implementation
- Profile modal allows admins to update name and reset password

## Browser Compatibility

- Chrome 88+
- Firefox 78+
- Safari 14+
- Edge 88+

Requires modern browser support for ES6 modules and Firebase SDK.
