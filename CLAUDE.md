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
flutter packages pub run build_runner build

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
# Generate dependency injection code
flutter packages pub run build_runner build --delete-conflicting-outputs

# Watch for changes and auto-generate
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
- Configuration: `lib/core/di/injection_container.dart`
- Auto-generated bindings: `lib/core/di/injection_container.config.dart`
- Initialize with `configureDependencies()` in `main.dart`

## Navigation

Uses `go_router` for declarative navigation:
- Router configuration: `lib/core/widgets/app_router.dart`
- Shell route wrapper: `lib/core/widgets/main_navigation_wrapper.dart`
- Route paths: `/dashboard`, `/block-setup`, `/focus-sessions`, `/analytics`, `/settings`

## Platform-Specific Features

### Android
- **Device Admin**: Enhanced blocking capabilities
- **Accessibility Service**: App blocking detection
- **Usage Stats**: App usage monitoring
- **VPN Service**: Website blocking

### iOS
- **Screen Time API**: iOS 15.0+ integration
- **DeviceActivity**: App usage monitoring
- **Shield Configuration**: App blocking
- **Network Extension**: VPN-based blocking

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

- **State Management**: `flutter_bloc` (^8.1.3), `equatable` (^2.0.5)
- **Navigation**: `go_router` (^13.2.0)
- **Dependency Injection**: `get_it` (^7.6.7), `injectable` (^2.3.2)
- **Database**: `sqflite` (^2.3.0)
- **HTTP**: `dio` (^5.4.0), `retrofit` (^4.0.3)
- **Platform Services**: `usage_stats` (^1.3.0), `app_usage` (^3.0.0)
- **Firebase**: Core, Auth, Firestore, Analytics
- **UI Components**: `flutter_svg`, `lottie`, `flutter_animate`

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

## Security Considerations

- System-level blocking implementation requires careful permission handling
- VPN and accessibility services need security review
- User data should be encrypted and processed locally where possible
- Firebase integration for cloud sync with privacy protection