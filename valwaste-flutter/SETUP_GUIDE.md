# ValWaste Setup Guide

This guide will help you set up the complete ValWaste waste management system with both the Flutter mobile app and PHP backend.

## Prerequisites

### For Flutter App
- Flutter SDK 3.8.1 or higher
- Dart SDK 3.0.0 or higher
- Android Studio / VS Code
- Android SDK (for Android development)
- Xcode (for iOS development, macOS only)

### For PHP Backend
- PHP 8.0 or higher
- MySQL 8.0 or higher
- Apache/Nginx web server
- Composer (optional, for dependency management)

## Setup Instructions

### 1. Flutter App Setup

#### Step 1: Clone and Install Dependencies
```bash
# Navigate to the Flutter project directory
cd valwaste

# Install Flutter dependencies
flutter pub get
```

#### Step 2: Configure Backend URL
1. Open `lib/services/api_service.dart`
2. Update the `baseUrl` constant with your PHP backend URL:
   ```dart
   static const String baseUrl = 'http://your-domain.com/api';
   ```
   or for local development:
   ```dart
   static const String baseUrl = 'http://localhost/valwaste/php-backend';
   ```

#### Step 3: Run the App
```bash
# For Android
flutter run

# For iOS (macOS only)
flutter run -d ios

# For web
flutter run -d chrome
```

### 2. PHP Backend Setup

#### Step 1: Database Setup
1. Create a MySQL database:
   ```sql
   CREATE DATABASE valwaste_db;
   ```

2. Import the database schema:
   ```bash
   mysql -u root -p valwaste_db < php-backend/database.sql
   ```

#### Step 2: Configure Database Connection
1. Open `php-backend/index.php`
2. Update the database configuration:
   ```php
   $host = 'localhost';
   $dbname = 'valwaste_db';
   $username = 'your_username';
   $password = 'your_password';
   ```

#### Step 3: Web Server Configuration

##### For Apache:
1. Copy the `php-backend` folder to your web server directory
2. Create a `.htaccess` file in the `php-backend` directory:
   ```apache
   RewriteEngine On
   RewriteCond %{REQUEST_FILENAME} !-f
   RewriteCond %{REQUEST_FILENAME} !-d
   RewriteRule ^(.*)$ index.php [QSA,L]
   ```

##### For Nginx:
Add this configuration to your nginx site:
```nginx
location /api {
    try_files $uri $uri/ /index.php?$query_string;
}
```

#### Step 4: Test the Backend
1. Access the admin panel: `http://your-domain.com/php-backend/admin/`
2. Test API endpoints:
   ```bash
   curl -X POST http://your-domain.com/php-backend/register \
     -H "Content-Type: application/json" \
     -d '{"name":"Test User","email":"test@example.com","password":"password123","phone":"1234567890","address":"Test Address"}'
   ```

### 3. Environment Configuration

#### Flutter Environment Variables
Create a `.env` file in the Flutter project root:
```env
API_BASE_URL=http://your-domain.com/php-backend
```

#### PHP Environment Variables
Create a `config.php` file in the `php-backend` directory:
```php
<?php
define('DB_HOST', 'localhost');
define('DB_NAME', 'valwaste_db');
define('DB_USER', 'your_username');
define('DB_PASS', 'your_password');
define('JWT_SECRET', 'your-secret-key');
?>
```

## Testing the Setup

### 1. Test Flutter App
1. Run the app: `flutter run`
2. Try to register a new user
3. Test login functionality
4. Navigate through different screens

### 2. Test PHP Backend
1. Test user registration:
   ```bash
   curl -X POST http://localhost/php-backend/register \
     -H "Content-Type: application/json" \
     -d '{"name":"John Doe","email":"john@example.com","password":"password123","phone":"1234567890","address":"123 Main St"}'
   ```

2. Test user login:
   ```bash
   curl -X POST http://localhost/php-backend/login \
     -H "Content-Type: application/json" \
     -d '{"email":"john@example.com","password":"password123"}'
   ```

3. Test getting user profile (with token):
   ```bash
   curl -X GET http://localhost/php-backend/user/profile \
     -H "Authorization: Bearer YOUR_TOKEN_HERE"
   ```

## Troubleshooting

### Common Flutter Issues

#### 1. Dependencies not found
```bash
flutter clean
flutter pub get
```

#### 2. Build errors
```bash
flutter doctor
flutter analyze
```

#### 3. Network errors
- Check if the backend URL is correct
- Ensure the backend is running
- Check CORS settings

### Common PHP Issues

#### 1. Database connection failed
- Verify database credentials
- Ensure MySQL service is running
- Check if the database exists

#### 2. 404 errors
- Verify .htaccess file is present
- Check Apache/Nginx configuration
- Ensure mod_rewrite is enabled (Apache)

#### 3. CORS errors
- The backend already includes CORS headers
- If using a different domain, update the Access-Control-Allow-Origin header

### Common Database Issues

#### 1. Table not found
```bash
mysql -u root -p valwaste_db < php-backend/database.sql
```

#### 2. Permission denied
```sql
GRANT ALL PRIVILEGES ON valwaste_db.* TO 'your_username'@'localhost';
FLUSH PRIVILEGES;
```

## Development Workflow

### 1. Making Changes to Flutter App
1. Make your changes in the Flutter code
2. Test locally: `flutter run`
3. Build for production: `flutter build apk` or `flutter build ios`

### 2. Making Changes to PHP Backend
1. Make your changes in the PHP code
2. Test API endpoints using curl or Postman
3. Deploy to production server

### 3. Database Changes
1. Make changes to `database.sql`
2. Apply changes to your database
3. Update any related PHP code

## Production Deployment

### Flutter App
1. Build the app:
   ```bash
   # Android
   flutter build apk --release
   
   # iOS
   flutter build ios --release
   ```

2. Upload to app stores or distribute APK/IPA files

### PHP Backend
1. Upload files to production server
2. Configure production database
3. Update environment variables
4. Set up SSL certificate
5. Configure backup system

## Security Considerations

### Flutter App
- Store sensitive data securely using encrypted storage
- Implement proper input validation
- Use HTTPS for all API calls

### PHP Backend
- Use prepared statements to prevent SQL injection
- Implement proper authentication and authorization
- Validate all input data
- Use HTTPS in production
- Regularly update dependencies

## Support

If you encounter any issues during setup:

1. Check the troubleshooting section above
2. Review the error logs
3. Ensure all prerequisites are met
4. Verify network connectivity
5. Check file permissions

For additional support, please refer to the main README.md file or create an issue in the project repository.
