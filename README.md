# Mind Fence - Social Media Blocking App


A comprehensive Flutter application designed to help users increase productivity by blocking social media apps and managing digital distractions. Mind Fence provides system-level blocking capabilities with native integrations for both Android and iOS platforms.

## Features

- **Smart App Blocking**: Block specific social media apps with system-level integration through native services
- **Website Blocking**: Comprehensive website blocking using VPN technology and network extensions
- **Focus Sessions**: Timed productivity sessions with complete social media lockdown
- **Usage Analytics**: Track screen time, app usage, and productivity gains with detailed insights
- **Dashboard**: Real-time blocking status and productivity metrics with interactive widgets
- **Cross-Platform**: Native iOS and Android implementations with platform-specific APIs
- **Advanced Permissions**: Comprehensive permission management for device admin, accessibility, and VPN services
- **Background Processing**: Continuous monitoring and blocking even when the app is closed

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
   dart run build_runner build
   ```

4. Configure Firebase (Optional):
   - Add your `google-services.json` to `android/app/`
   - Add your `GoogleService-Info.plist` to `ios/Runner/`
   - Note: Firebase services are currently disabled in the pubspec.yaml but configuration files are prepared

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
- **VPN Service**: Website blocking through system VPN integration
- **Kotlin Integration**: Native Android code in Kotlin with method channels
- **Native Services**: DeviceAdminReceiver, AccessibilityService, VpnService, BlockingService
- **Comprehensive Permissions**: Usage stats, device admin, accessibility, system alert window, and VPN permissions

### iOS
- **Screen Time API**: iOS 15.0+ integration with Family Controls framework
- **DeviceActivity**: Real-time app usage monitoring and intervention
- **Shield Configuration**: Dynamic app blocking interface
- **Network Extension**: VPN functionality for website blocking (packet-tunnel-provider, app-proxy-provider)
- **Family Controls**: System-level app blocking capabilities
- **Managed Settings**: Configuration management for blocking rules
- **Background Processing**: Support for background app refresh and processing

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

# Generate code (dependency injection, serialization)
dart run build_runner build

# Build for release
flutter build apk  # Android
flutter build ios  # iOS

# Clean build files
flutter clean
```

## Contributing

Please read the development guidelines in the `guides/` directory before contributing. All code must meet the project's quality standards (7/10 minimum score).

Key guidelines:
- Follow Clean Architecture principles
- Use BLoC for state management
- Maintain 100% type safety
- Include comprehensive tests
- Follow security best practices
- Test platform-specific features on both Android and iOS
- Ensure proper permission handling for system-level integrations

## Technical Notes

### Current Implementation Status
- **Core Flutter App**: Fully implemented with clean architecture
- **Android Platform**: Complete implementation with working app blocking
- **Block Setup**: Full UI and BLoC implementation with comprehensive permission management
- **Dashboard**: Complete UI with real blocking status integration
- **Native Services**: Android BlockingService and AccessibilityService working
- **iOS Platform**: No implementation - Android-only currently
- **Firebase Integration**: Prepared but currently disabled in pubspec.yaml
- **Advanced Features**: Website blocking, analytics, focus sessions partially implemented

### Dependencies Status
Some advanced platform services are temporarily disabled in pubspec.yaml but have native implementations:
- Firebase services (prepared for future use)
- Usage stats packages (replaced with native implementations)
- VPN packages (replaced with native implementations)

## License

This project is licensed under the MIT License.
