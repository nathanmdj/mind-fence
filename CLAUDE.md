# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Mind Fence is a Flutter-based social media blocking application designed to help users increase productivity by preventing doomscrolling and managing digital distractions. The app provides comprehensive blocking features with system-level integration for both Android and iOS platforms.

## Development Commands

### Core Development Commands
```bash
# Install dependencies
flutter pub get

# Run code generation for dependency injection and serialization
dart run build_runner build

# Run the app in development mode
flutter run

# Run tests
flutter test

# Run widget tests
flutter test test/widget/

# Run integration tests
flutter test test/integration/

# Build APK for Android
flutter build apk

# Build iOS app
flutter build ios

# Analyze code for issues
flutter analyze

# Format code
flutter format .

# Clean build files
flutter clean
```

### Code Generation Commands
```bash
# Generate dependency injection code (recommended)
dart run build_runner build --delete-conflicting-outputs

# Watch for changes and auto-generate
dart run build_runner watch

# Legacy commands (still supported)
flutter packages pub run build_runner build --delete-conflicting-outputs
flutter packages pub run build_runner watch
```

## Architecture Overview

The project follows Clean Architecture principles with clear separation of concerns:

### Layer Structure
- **Presentation Layer**: `lib/features/*/presentation/` - BLoC state management, UI pages, and widgets
- **Domain Layer**: `lib/features/*/domain/` & `lib/shared/domain/` - Business logic entities, repository contracts, and use cases
- **Data Layer**: `lib/features/*/data/` - Repository implementations, data sources, and data models
- **Core Layer**: `lib/core/` - Shared utilities, dependency injection, theme configuration, and common widgets

### Key Features
1. **Dashboard**: Main overview with blocking status, focus sessions, and productivity metrics
2. **Block Setup**: App selection and blocking configuration
3. **Focus Sessions**: Timed productivity sessions with complete social media lockdown
4. **Analytics**: Usage statistics and productivity insights
5. **Settings**: App configuration and preferences

## State Management

The app uses BLoC (Business Logic Component) pattern throughout:
- **BLoC**: For complex state management with events and states
- **Cubit**: For simpler state management scenarios
- **Repository Pattern**: For data access abstraction

Key BLoC components:
- `DashboardBloc`: Main dashboard state management at `lib/features/dashboard/presentation/bloc/dashboard_bloc.dart:3`
- State classes follow the pattern: `*Event`, `*State`, `*Bloc`

## Dependency Injection

The app uses `get_it` with `injectable` for dependency injection:

- Configuration: `lib/core/di/injection_container.dart:1`
- Auto-generated bindings: `lib/core/di/injection_container.config.dart:1`
- Initialize with `configureDependencies()` in `lib/main.dart:15`
- SharedPreferences and Dio instances are registered as singletons


## Navigation

Uses `go_router` for declarative navigation:

- Router configuration: `lib/core/widgets/app_router.dart:12`
- Shell route wrapper: `lib/core/widgets/main_navigation_wrapper.dart:17`
- Route paths: `/dashboard`, `/block-setup`, `/focus-sessions`, `/analytics`, `/settings`
- Initial route: `/dashboard`


## Platform-Specific Features

### Android

- **Device Admin**: Enhanced blocking capabilities (`android/app/src/main/res/xml/device_admin.xml`)
- **Accessibility Service**: App blocking detection (`android/app/src/main/res/xml/accessibility_service_config.xml`)
- **Usage Stats**: App usage monitoring and permission management
- **VPN Service**: Website blocking through system VPN integration
- **MainActivity**: Kotlin-based main activity with native method channels (`android/app/src/main/kotlin/com/mindfence/app/mind_fence/MainActivity.kt`)
- **Native Services**: DeviceAdminReceiver, AccessibilityService, VpnService, BlockingService
- **Permissions**: Comprehensive permission set including usage stats, device admin, accessibility, and VPN permissions
- **Method Channels**: Direct integration for app listing, permission management, and system-level blocking

### iOS
- **Screen Time API**: iOS 15.0+ integration with Family Controls framework
- **DeviceActivity**: Real-time app usage monitoring and intervention
- **Shield Configuration**: Dynamic app blocking interface
- **Network Extension**: VPN functionality for website blocking (packet-tunnel-provider, app-proxy-provider)
- **Family Controls**: System-level app blocking capabilities
- **Managed Settings**: Configuration management for blocking rules
- **Info.plist**: iOS configuration with comprehensive entitlements (`ios/Runner/Info.plist`)
- **Firebase**: Google services integration (`ios/Runner/GoogleService-Info.plist`)
- **Background Processing**: Support for background app refresh and processing


## Data Models

Core domain entities located in `lib/shared/domain/entities/`:
- `BlockedApp`: Represents blocked applications
- `FocusSession`: Manages focus session states and timing
- `UsageStats`: Tracks app usage statistics with time formatting

## Theme & Styling

- **Theme System**: `lib/core/theme/app_theme.dart`
- **Colors**: `lib/core/theme/app_colors.dart`
- **Design System**: Material Design 3 with dark mode support
- **Typography**: Inter font family with multiple weights

## Testing Structure

- **Unit Tests**: `test/unit/`
- **Widget Tests**: `test/widget/`
- **Integration Tests**: `test/integration/`
- **Testing Libraries**: `bloc_test`, `mocktail`, `flutter_test`

## Key Dependencies

- **State Management**: `flutter_bloc` (^8.1.3), `bloc` (^8.1.2), `equatable` (^2.0.5)
- **Navigation**: `go_router` (^13.2.0)
- **Dependency Injection**: `get_it` (^7.6.7), `injectable` (^2.3.2)
- **Database**: `sqflite` (^2.3.0), `path` (^1.8.3)
- **HTTP**: `dio` (^5.4.0), `retrofit` (^4.0.3), `pretty_dio_logger` (^1.3.1)
- **JSON Serialization**: `json_annotation` (^4.8.1), `json_serializable` (^6.7.1)
- **UI Components**: `flutter_svg` (^2.0.9), `lottie` (^2.7.0), `flutter_animate` (^4.3.0)
- **Utilities**: `shared_preferences` (^2.2.2), `device_info_plus` (^9.1.1), `package_info_plus` (^4.2.0), `permission_handler` (^11.1.0), `intl` (^0.19.0)
- **Testing**: `bloc_test` (^9.1.5), `mocktail` (^1.0.1), `flutter_lints` (^3.0.1), `integration_test` (SDK)

### Platform Services (Currently Disabled)
The following platform-specific dependencies are temporarily disabled in the current implementation:
- **Firebase**: `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_analytics`
- **Usage Monitoring**: `usage_stats`, `app_usage`
- **VPN Services**: `flutter_vpn`

Note: These services have comprehensive native implementations in Android (Kotlin) and iOS (Swift) through method channels.


## Development Guidelines

The project includes comprehensive development guidelines in `guides/` directory:
- All code must score 7/10 or higher on guideline criteria
- Security guidelines are mandatory for authentication and data protection
- Clean architecture patterns must be followed
- BLoC state management is required for complex state
- Accessibility standards (WCAG) must be met
- Performance optimization is critical for background services

## File Organization

- **Feature-based structure**: Each feature has its own folder with presentation, domain, and data layers
- **Shared components**: Common entities and utilities in `lib/shared/`
- **Core utilities**: Cross-cutting concerns in `lib/core/`
- **Assets**: Organized by type in `assets/` (images, icons, animations, fonts)
- **Guides**: Development guidelines in `guides/` directory
- **Platform**: Native code in `android/` and `ios/` directories
- **Main entry**: Application entry point at `lib/main.dart`


## Security Considerations

- System-level blocking implementation requires careful permission handling
- VPN and accessibility services need security review
- User data should be encrypted and processed locally where possible
- Firebase integration for cloud sync with privacy protection
- Native method channels require input validation and security checks
- Device admin permissions need user consent and proper revocation handling
- Accessibility services must comply with Android's accessibility guidelines
- iOS Family Controls require proper entitlements and user authorization

## Current Implementation Status

### Fully Implemented & Working
- **Core Flutter Architecture**: Clean architecture with feature-based structure
- **State Management**: BLoC pattern implementation across all features
- **Navigation**: Go Router with shell route navigation
- **Dependency Injection**: Full get_it and injectable setup
- **Block Setup Feature**: Complete UI and BLoC implementation with 11 event handlers
- **Android Permission Management**: Comprehensive permission handling with sequential flow
- **Android Platform Integration**: Method channels with 15+ platform methods
- **Android Native Services**: 
  - BlockingService with foreground service and real-time monitoring
  - AccessibilityService with window state detection
  - Complete MainActivity with all platform methods
- **Theme System**: Material Design 3 with dark mode support
- **Data Layer**: Repository pattern with platform service integration

### Partially Implemented
- **Dashboard Feature**: Complete UI with real blocking status, mock analytics data
- **Android App Blocking**: Core functionality working, advanced features incomplete
- **VPN Services**: Structure exists, implementation incomplete
- **Focus Sessions**: UI structure exists, logic incomplete

### Boilerplate/Structure Only
- **iOS Platform**: No iOS implementation - Android-only currently
- **Website Blocking**: Platform methods exist, VPN service incomplete
- **Advanced Analytics**: Mock data displayed, no real analytics implementation
- **Emergency Override**: Domain entities exist, no implementation
- **Focus Sessions Logic**: UI exists, business logic incomplete
- **Scheduling System**: Domain entities exist, no implementation

### Disabled/Prepared for Future
- **Firebase Services**: Configuration ready, dependencies commented out
- **Cloud Features**: Authentication, sync, cloud analytics disabled
- **Advanced Platform Services**: Usage stats and VPN packages disabled (replaced with native implementations)

## Troubleshooting

### Common Issues
1. **Build Runner Errors**: Use `dart run build_runner clean` followed by `dart run build_runner build`
2. **Platform Permissions**: Ensure proper AndroidManifest.xml and Info.plist configuration
3. **Method Channel Issues**: Verify native implementations in MainActivity.kt and iOS equivalents
4. **Firebase Integration**: Uncomment dependencies in pubspec.yaml when ready to enable

### Platform-Specific Issues
- **Android**: Ensure Google Services JSON is configured correctly
- **iOS**: Verify entitlements and capabilities are properly set
- **VPN Services**: Test on physical devices as emulators may not support VPN functionality