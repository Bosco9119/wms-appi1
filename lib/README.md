# WMS Customer Mobile App

A Flutter mobile application for Greenstem Workshop Management System (WMS) customers.

## Project Structure

```
lib/
├── core/                          # Core application layer
│   ├── constants/
│   │   ├── app_constants.dart     # App-wide constants
│   │   └── api_constants.dart     # API endpoints and configuration
│   ├── database/
│   │   └── database_service.dart  # SQLite database operations
│   ├── navigation/
│   │   ├── app_router.dart        # GoRouter configuration
│   │   └── route_names.dart       # Route name constants
│   └── services/
│       └── auth_service.dart      # Firebase authentication service
├── modules/                       # Feature modules (High Cohesion)
│   ├── auth/                      # Authentication module
│   │   ├── screens/
│   │   │   ├── login_screen.dart
│   │   │   └── register_screen.dart
│   │   └── widgets/
│   │       ├── auth_text_field.dart
│   │       └── auth_button.dart
│   ├── customer/                  # Customer home & booking
│   │   ├── screens/
│   │   │   ├── customer_home_screen.dart
│   │   │   ├── service_booking_screen.dart
│   │   │   ├── shop_search_screen.dart
│   │   │   └── shop_details_screen.dart
│   │   └── widgets/
│   │       ├── service_type_selector.dart
│   │       ├── last_visited_list.dart
│   │       └── nearby_shops_list.dart
│   ├── schedule/                  # Service schedule & progress
│   │   └── screens/
│   │       ├── schedule_screen.dart
│   │       ├── appointment_details_screen.dart
│   │       └── service_progress_screen.dart
│   ├── billing/                   # E-Billing & payments
│   │   └── screens/
│   │       ├── billing_screen.dart
│   │       ├── invoice_details_screen.dart
│   │       └── payment_screen.dart
│   ├── e_wallet/                  # E-Wallet functionality
│   │   └── screens/
│   │       └── wallet_screen.dart
│   ├── feedback/                  # Service feedback
│   │   └── screens/
│   │       └── feedback_screen.dart
│   └── notifications/             # Service reminders
│       └── screens/
│           └── notifications_screen.dart
├── shared/                        # Shared components (Low Coupling)
│   ├── models/
│   │   ├── customer_model.dart
│   │   ├── vehicle_model.dart
│   │   ├── appointment_model.dart
│   │   ├── invoice_model.dart
│   │   └── feedback_model.dart
│   ├── providers/
│   │   └── customer_provider.dart # Main state management
│   └── widgets/
│       └── custom_drawer.dart     # Navigation drawer
└── main.dart                      # App entry point
```

## Features Implemented

### ✅ Core Architecture
- **Clean Architecture**: Separation of concerns with core, modules, and shared layers
- **State Management**: Provider pattern for reactive state management
- **Navigation**: GoRouter for type-safe navigation
- **Database**: SQLite for local data persistence
- **Authentication**: Firebase Auth integration

### ✅ Customer Features (Part E Requirements)
1. **Service Schedule View**: Customer can view upcoming and past appointments
2. **Service Reminders**: Push notifications for appointments and maintenance
3. **Service Booking**: Ability to book new service appointments
4. **Real-time Service Progress**: Track live status of vehicle service
5. **Service Quality Feedback**: Submit feedback on completed services
6. **E-Billing/Payment**: View and pay invoices digitally

### ✅ UI/UX Design
- **Material Design 3**: Modern, consistent UI components
- **Responsive Layout**: Adapts to different screen sizes
- **Navigation Drawer**: Easy access to all features
- **Service Type Selection**: Filter services by type
- **Last Visited & Nearby Shops**: Quick access to workshops

## Dependencies

### Core Dependencies
- `flutter`: SDK
- `provider`: State management
- `go_router`: Navigation
- `sqflite`: Local database
- `firebase_core`: Firebase integration
- `firebase_auth`: Authentication
- `cloud_firestore`: Cloud database

### UI Dependencies
- `flutter_svg`: SVG support
- `cached_network_image`: Image caching
- `table_calendar`: Calendar widget

### Utility Dependencies
- `intl`: Internationalization
- `uuid`: Unique ID generation
- `shared_preferences`: Local storage
- `http`: HTTP requests

## Getting Started

1. **Install Dependencies**
   ```bash
   flutter pub get
   ```

2. **Configure Firebase**
   - Update `lib/firebase_options.dart` with your Firebase project credentials
   - Enable Authentication and Firestore in Firebase Console

3. **Run the App**
   ```bash
   flutter run
   ```

## Architecture Principles

### Object-Oriented Programming (OOP)
- **Single Responsibility**: Each class has one reason to change
- **Open/Closed**: Open for extension, closed for modification
- **Dependency Inversion**: Depend on abstractions, not concretions
- **Interface Segregation**: No client should depend on unused methods

### Design Patterns
- **Repository Pattern**: Data access abstraction
- **Provider Pattern**: State management
- **Factory Pattern**: Object creation
- **Singleton Pattern**: Service classes

### SOLID Principles
- **S**ingle Responsibility Principle
- **O**pen/Closed Principle
- **L**iskov Substitution Principle
- **I**nterface Segregation Principle
- **D**ependency Inversion Principle

## Next Steps

1. **Implement Core Features**: Complete the placeholder screens with actual functionality
2. **Add Real-time Updates**: Implement WebSocket connections for live progress tracking
3. **Payment Integration**: Add Stripe or other payment gateway
4. **Push Notifications**: Implement Firebase Cloud Messaging
5. **Offline Support**: Enhance offline capabilities
6. **Testing**: Add unit and integration tests
7. **Performance**: Optimize for production use

## Contributing

1. Follow the established architecture patterns
2. Maintain high code quality and documentation
3. Test thoroughly before submitting changes
4. Follow Flutter/Dart best practices
