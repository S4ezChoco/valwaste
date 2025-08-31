# ValWaste - Smart Waste Management App

A modern Flutter application for efficient waste collection and recycling management. This app allows users to schedule waste collections, track their history, and learn about proper recycling practices.

## Features

### 🔐 Authentication
- User registration and login
- Secure token-based authentication
- Profile management

### 🗑️ Waste Collection
- Schedule waste collection requests
- Multiple waste type support (General, Recyclable, Organic, Hazardous, Electronic)
- Real-time collection status tracking
- Collection history and analytics

### 📚 Recycling Guide
- Comprehensive recycling information
- Search functionality for recycling tips
- Categorized waste disposal methods

### 📊 Dashboard
- Overview of recent collections
- Monthly statistics
- Quick action buttons
- Real-time status updates

### 👤 User Profile
- Personal information management
- Collection history
- Account settings

## Tech Stack

- **Frontend**: Flutter 3.8.1+
- **Backend**: PHP (Admin Panel)
- **State Management**: Provider
- **HTTP Client**: http package
- **Local Storage**: SharedPreferences
- **UI Components**: Material Design 3

## Project Structure

```
lib/
├── models/           # Data models
│   ├── user.dart
│   ├── waste_collection.dart
│   └── recycling_guide.dart
├── services/         # API and business logic
│   ├── api_service.dart
│   └── auth_service.dart
├── screens/          # UI screens
│   ├── auth/         # Authentication screens
│   ├── home/         # Dashboard and main screens
│   ├── schedule/     # Collection scheduling
│   ├── history/      # Collection history
│   ├── guide/        # Recycling guide
│   └── profile/      # User profile
├── utils/            # Utilities and constants
│   └── constants.dart
└── widgets/          # Reusable UI components
```

## Getting Started

### Prerequisites

- Flutter SDK 3.8.1 or higher
- Dart SDK 3.0.0 or higher
- Android Studio / VS Code
- Android SDK (for Android development)
- Xcode (for iOS development, macOS only)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd valwaste
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure backend URL**
   - Open `lib/services/api_service.dart`
   - Update the `baseUrl` constant with your PHP backend URL

4. **Run the app**
   ```bash
   flutter run
   ```

### Backend Setup

The Flutter app communicates with a PHP backend for data management. Ensure your PHP backend provides the following API endpoints:

#### Authentication
- `POST /api/login` - User login
- `POST /api/register` - User registration

#### User Management
- `GET /api/user/profile` - Get user profile
- `PUT /api/user/profile` - Update user profile

#### Waste Collections
- `GET /api/waste-collections` - Get user collections
- `POST /api/waste-collections` - Create new collection
- `PUT /api/waste-collections/{id}` - Update collection
- `DELETE /api/waste-collections/{id}` - Cancel collection

#### Recycling Guide
- `GET /api/recycling-guides` - Get all guides
- `GET /api/recycling-guides/search?q={query}` - Search guides

## API Response Format

### Authentication Response
```json
{
  "success": true,
  "token": "jwt_token_here",
  "user": {
    "id": "user_id",
    "name": "User Name",
    "email": "user@example.com",
    "phone": "1234567890",
    "address": "User Address",
    "created_at": "2024-01-01T00:00:00Z"
  }
}
```

### Waste Collection Response
```json
{
  "collections": [
    {
      "id": "collection_id",
      "user_id": "user_id",
      "waste_type": "recyclable",
      "quantity": 10.5,
      "unit": "kg",
      "description": "Plastic bottles and paper",
      "scheduled_date": "2024-01-15T10:00:00Z",
      "address": "Collection Address",
      "status": "scheduled",
      "created_at": "2024-01-10T00:00:00Z"
    }
  ]
}
```

## Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  http: ^1.1.0
  shared_preferences: ^2.2.2
  image_picker: ^1.0.4
  intl: ^0.18.1
  flutter_local_notifications: ^16.3.0
  geolocator: ^10.1.0
  permission_handler: ^11.0.1
  cached_network_image: ^3.3.0
  flutter_svg: ^2.0.9
  provider: ^6.1.1
```

## Features in Detail

### Waste Types Supported
- **General Waste**: Regular household waste
- **Recyclable**: Paper, plastic, glass, metal
- **Organic**: Food waste, garden waste
- **Hazardous**: Chemicals, batteries, electronics
- **Electronic**: E-waste, appliances

### Collection Status
- **Pending**: Request submitted, awaiting confirmation
- **Scheduled**: Collection confirmed and scheduled
- **In Progress**: Collection team en route
- **Completed**: Collection finished
- **Cancelled**: Collection cancelled

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For support and questions, please contact the development team or create an issue in the repository.

## Screenshots

[Add screenshots of the app here]

---

**Note**: This is a Flutter app that works in conjunction with a PHP backend admin panel. Make sure to set up the backend properly before running the app.
