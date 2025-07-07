# Mind Fence - Social Media Blocking App

A comprehensive Flutter application designed to help users increase productivity by blocking social media apps and managing digital distractions.

## Features

- **Smart App Blocking**: Block specific social media apps with system-level integration
- **Website Blocking**: Comprehensive website blocking using VPN technology
- **Focus Sessions**: Timed productivity sessions with complete social media lockdown
- **Advanced Scheduling**: Time-based, location-based, and Wi-Fi network blocking
- **Usage Analytics**: Track screen time, app usage, and productivity gains
- **Cross-Platform**: Native iOS and Android implementations

## Getting Started

### Prerequisites

- Flutter SDK (>=3.16.0)
- Dart SDK (>=3.2.0)
- Android Studio / Xcode for platform-specific development

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Generate code:
   ```bash
   flutter packages pub run build_runner build
   ```
4. Run the app:
   ```bash
   flutter run
   ```

## Architecture

The app follows Clean Architecture principles with:
- **BLoC Pattern**: For predictable state management
- **Dependency Injection**: Using get_it and injectable
- **Repository Pattern**: For data access abstraction
- **Feature-based Structure**: Modular and scalable codebase

## Platform Integration

### Android
- Device Admin for enhanced blocking
- Accessibility Service for app detection
- Usage Stats Manager integration
- VPN Service for website blocking

### iOS
- Screen Time API integration (iOS 15.0+)
- DeviceActivity monitoring
- Shield Configuration for app blocking
- Network Extension for VPN functionality

## Contributing

Please read the development guidelines in the `guides/` directory before contributing. All code must meet the project's quality standards (7/10 minimum score).

## License

This project is licensed under the MIT License.