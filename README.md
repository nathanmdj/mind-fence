# Mind Fence - Social Media Blocking App

A comprehensive Flutter application designed to help users increase productivity by blocking social media apps and managing digital distractions.

## Features

- **Smart App Blocking**: Block specific social media apps with system-level integration
- **Website Blocking**: Comprehensive website blocking using VPN technology
- **Focus Sessions**: Timed productivity sessions with complete social media lockdown
- **Usage Analytics**: Track screen time, app usage, and productivity gains
- **Dashboard**: Real-time blocking status and productivity metrics
- **Cross-Platform**: Native iOS and Android implementations with platform-specific APIs

## Getting Started

### Prerequisites

- Flutter SDK (>=3.16.0)
- Dart SDK (>=3.2.0)
- Android Studio / Xcode for platform-specific development
- Firebase project configured for iOS and Android

### Installation

1. Clone the repository
   ```bash
   git clone https://github.com/yourusername/mind-fence.git
   cd mind-fence
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Generate code:
   ```bash
   flutter packages pub run build_runner build
   ```

4. Configure Firebase:
   - Add your `google-services.json` to `android/app/`
   - Add your `GoogleService-Info.plist` to `ios/Runner/`

5. Run the app:
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
- **Device Admin**: Enhanced blocking capabilities with device administration
- **Accessibility Service**: Real-time app detection and blocking
- **Usage Stats Manager**: App usage monitoring and analytics
- **VPN Service**: Website blocking through VPN technology
- **Kotlin Integration**: Native Android code in Kotlin

### iOS
- **Screen Time API**: iOS 15.0+ integration for system-level blocking
- **DeviceActivity**: Real-time app usage monitoring
- **Shield Configuration**: Dynamic app blocking interface
- **Network Extension**: VPN functionality for website blocking

## Development

### Project Structure

```
lib/
├── core/                   # Core utilities and shared components
├── features/              # Feature-based modules
│   ├── dashboard/         # Main dashboard feature
│   ├── block_setup/       # App blocking configuration
│   ├── focus_sessions/    # Focus session management
│   ├── analytics/         # Usage analytics
│   └── settings/          # App settings
├── shared/                # Shared domain entities
└── main.dart             # Application entry point
```

### Key Commands

```bash
# Run tests
flutter test

# Analyze code
flutter analyze

# Format code
flutter format .

# Build for release
flutter build apk  # Android
flutter build ios  # iOS
```

## Contributing

Please read the development guidelines in the `guides/` directory before contributing. All code must meet the project's quality standards (7/10 minimum score).

Key guidelines:
- Follow Clean Architecture principles
- Use BLoC for state management
- Maintain 100% type safety
- Include comprehensive tests
- Follow security best practices

## License

This project is licensed under the MIT License.