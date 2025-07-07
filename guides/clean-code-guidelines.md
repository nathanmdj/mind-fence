# Clean Code Guidelines

## Overview

Clean code is essential for maintainability, collaboration, and long-term project success. These guidelines ensure that Mind Fence codebase remains readable, maintainable, and scalable as the project grows.

## Code Organization and Structure

### 1. File and Directory Structure (Score: 8-10)
- **Logical Grouping**: Organize files by feature or layer
- **Consistent Naming**: Use consistent naming conventions
- **Proper Imports**: Organize imports logically
- **Single Responsibility**: One primary responsibility per file

**Good Example:**
```
lib/
├── core/
│   ├── constants/
│   ├── errors/
│   ├── utils/
│   └── network/
├── features/
│   ├── blocking/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── analytics/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   └── settings/
│       ├── data/
│       ├── domain/
│       └── presentation/
└── main.dart
```

**Good Import Organization:**
```dart
// External packages
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

// Internal core
import 'package:mind_fence/core/errors/failures.dart';
import 'package:mind_fence/core/utils/constants.dart';

// Internal features
import 'package:mind_fence/features/blocking/domain/entities/blocked_app.dart';
import 'package:mind_fence/features/blocking/domain/repositories/blocking_repository.dart';

// Relative imports (only for same feature)
import '../entities/blocking_session.dart';
import '../repositories/session_repository.dart';
```

### 2. Class Design (Score: 8-10)
- **Single Responsibility**: Each class has one reason to change
- **Composition over Inheritance**: Prefer composition
- **Immutable Objects**: Use immutable data structures
- **Proper Encapsulation**: Hide internal implementation details

**Good Example:**
```dart
// Well-designed entity class
class BlockedApp extends Equatable {
  final String id;
  final String name;
  final String packageName;
  final bool isBlocked;
  final DateTime? lastBlocked;
  final Duration totalBlockedTime;

  const BlockedApp({
    required this.id,
    required this.name,
    required this.packageName,
    required this.isBlocked,
    this.lastBlocked,
    required this.totalBlockedTime,
  });

  BlockedApp copyWith({
    String? id,
    String? name,
    String? packageName,
    bool? isBlocked,
    DateTime? lastBlocked,
    Duration? totalBlockedTime,
  }) {
    return BlockedApp(
      id: id ?? this.id,
      name: name ?? this.name,
      packageName: packageName ?? this.packageName,
      isBlocked: isBlocked ?? this.isBlocked,
      lastBlocked: lastBlocked ?? this.lastBlocked,
      totalBlockedTime: totalBlockedTime ?? this.totalBlockedTime,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    packageName,
    isBlocked,
    lastBlocked,
    totalBlockedTime,
  ];
}
```

**Bad Example:**
```dart
// Poor class design
class BlockingManager {
  String? appName;
  bool? blocked;
  DateTime? time;
  
  // Mutable state, no validation, unclear responsibility
  void setBlocked(bool value) {
    blocked = value;
    time = DateTime.now();
  }
  
  void updateApp(String name) {
    appName = name;
  }
  
  // Mixed concerns - this class does too much
  void saveToDatabase() { /* ... */ }
  void sendAnalytics() { /* ... */ }
  void updateUI() { /* ... */ }
}
```

## Naming Conventions

### 1. Clear and Descriptive Names (Score: 8-10)
- **Self-Documenting**: Names should explain purpose
- **Avoid Abbreviations**: Use full words
- **Context-Appropriate**: Names fit their context
- **Consistent Terminology**: Use consistent vocabulary

**Good Example:**
```dart
// Clear, descriptive naming
class BlockingScheduleService {
  final BlockingRepository _blockingRepository;
  final NotificationService _notificationService;
  
  Future<void> scheduleBlockingSession({
    required List<String> appPackageNames,
    required DateTime startTime,
    required Duration duration,
    String? sessionName,
  }) async {
    final session = BlockingSession(
      id: _generateSessionId(),
      appPackageNames: appPackageNames,
      startTime: startTime,
      duration: duration,
      name: sessionName ?? 'Focus Session',
    );
    
    await _blockingRepository.scheduleSession(session);
    await _notificationService.scheduleSessionReminder(session);
  }
  
  Future<bool> isCurrentlyInFocusSession() async {
    final activeSessions = await _blockingRepository.getActiveSessions();
    return activeSessions.any((session) => session.isActive);
  }
}
```

**Bad Example:**
```dart
// Poor naming
class BlkMgr {
  final BlkRepo _repo;
  final NotifSvc _notif;
  
  Future<void> schBlk(List<String> apps, DateTime st, Duration dur) async {
    final s = BlkSess(apps, st, dur);
    await _repo.save(s);
    await _notif.set(s);
  }
  
  Future<bool> chkAct() async {
    final acts = await _repo.getActs();
    return acts.any((s) => s.act);
  }
}
```

### 2. Naming Patterns (Score: 7-10)
- **Variables**: camelCase, descriptive
- **Functions**: camelCase, verb-based
- **Classes**: PascalCase, noun-based
- **Constants**: UPPER_SNAKE_CASE
- **Private Members**: Leading underscore

**Good Example:**
```dart
// Proper naming patterns
class FocusSessionManager {
  static const int MAX_SESSION_DURATION_MINUTES = 480; // 8 hours
  static const String DEFAULT_SESSION_NAME = 'Focus Session';
  
  final SessionRepository _sessionRepository;
  final TimerService _timerService;
  
  late final StreamSubscription _sessionStatusSubscription;
  
  Future<void> startFocusSession(FocusSessionConfig config) async {
    final session = _createSessionFromConfig(config);
    await _sessionRepository.saveSession(session);
    _timerService.startTimer(session.duration);
  }
  
  Stream<SessionStatus> get sessionStatusStream => _sessionRepository.sessionStatusStream;
  
  bool get isSessionActive => _timerService.isRunning;
  
  FocusSession _createSessionFromConfig(FocusSessionConfig config) {
    return FocusSession(
      id: _generateUniqueSessionId(),
      name: config.name ?? DEFAULT_SESSION_NAME,
      blockedAppIds: config.blockedAppIds,
      startTime: DateTime.now(),
      duration: config.duration,
    );
  }
}
```

## Documentation Standards

### 1. Code Comments (Score: 8-10)
- **Why, Not What**: Explain reasoning, not implementation
- **Complex Logic**: Document complex algorithms
- **Public APIs**: Document all public interfaces
- **TODOs**: Use structured TODO comments

**Good Example:**
```dart
/// Service responsible for managing app blocking functionality.
/// 
/// This service coordinates between the native platform channels and
/// the Flutter layer to provide comprehensive app blocking capabilities.
/// It handles both schedule-based and manual blocking operations.
class AppBlockingService {
  final PlatformChannelService _platformChannel;
  final BlockingRepository _repository;
  
  /// Blocks the specified apps immediately.
  /// 
  /// This method will:
  /// 1. Update the blocking state in the repository
  /// 2. Send blocking commands to the native platform
  /// 3. Schedule periodic checks to ensure blocking remains active
  /// 
  /// Returns `true` if all apps were successfully blocked, `false` otherwise.
  /// 
  /// Throws [BlockingException] if the platform doesn't support blocking
  /// or if required permissions are not granted.
  Future<bool> blockApps(List<String> packageNames) async {
    // Validate that we have necessary permissions before attempting to block
    if (!await _hasRequiredPermissions()) {
      throw BlockingException('Insufficient permissions for app blocking');
    }
    
    // TODO(security): Implement integrity check to prevent bypass attempts
    // TODO(performance): Batch blocking operations for better performance
    
    try {
      // Update repository first to ensure state consistency
      await _repository.updateBlockingState(packageNames, isBlocked: true);
      
      // Send blocking command to native platform
      final blockingResults = await _platformChannel.blockApps(packageNames);
      
      // Verify that blocking was successful for all apps
      return blockingResults.every((result) => result.isSuccess);
    } catch (e) {
      // Rollback repository changes if platform blocking failed
      await _repository.updateBlockingState(packageNames, isBlocked: false);
      throw BlockingException('Failed to block apps: $e');
    }
  }
  
  /// Checks if the service has all required permissions for blocking.
  /// 
  /// This includes device admin permissions on Android and ScreenTime
  /// permissions on iOS.
  Future<bool> _hasRequiredPermissions() async {
    // Implementation depends on platform-specific permission checks
    return await _platformChannel.hasBlockingPermissions();
  }
}
```

### 2. API Documentation (Score: 8-10)
- **Comprehensive Docs**: Document all public methods
- **Parameter Descriptions**: Explain all parameters
- **Return Value Docs**: Document return types
- **Exception Documentation**: List possible exceptions

**Good Example:**
```dart
/// Repository interface for managing blocked apps data.
/// 
/// This repository provides methods to store, retrieve, and manipulate
/// information about blocked applications and their blocking states.
abstract class BlockingRepository {
  /// Retrieves all blocked apps for the current user.
  /// 
  /// Returns a list of [BlockedApp] objects representing apps that are
  /// currently configured for blocking. The list may be empty if no apps
  /// are blocked.
  /// 
  /// Throws [DatabaseException] if there's an error accessing the database.
  Future<List<BlockedApp>> getBlockedApps();
  
  /// Updates the blocking state for a specific app.
  /// 
  /// [packageName] - The package name of the app to update
  /// [isBlocked] - Whether the app should be blocked or unblocked
  /// [blockingReason] - Optional reason for the blocking state change
  /// 
  /// Returns `true` if the update was successful, `false` otherwise.
  /// 
  /// Throws [ValidationException] if the package name is invalid.
  /// Throws [DatabaseException] if there's an error updating the database.
  Future<bool> updateBlockingState(
    String packageName,
    bool isBlocked, {
    String? blockingReason,
  });
  
  /// Streams blocking state changes for real-time updates.
  /// 
  /// This stream emits a [BlockingStateChange] event whenever any app's
  /// blocking state is modified. Useful for updating UI in real-time.
  /// 
  /// The stream will emit an error if the database connection is lost.
  Stream<BlockingStateChange> get blockingStateChanges;
}
```

## Error Handling

### 1. Exception Handling (Score: 8-10)
- **Specific Exceptions**: Use specific exception types
- **Graceful Degradation**: Handle errors gracefully
- **Proper Logging**: Log errors appropriately
- **User-Friendly Messages**: Provide helpful error messages

**Good Example:**
```dart
// Custom exception hierarchy
abstract class MindFenceException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  
  const MindFenceException(this.message, {this.code, this.originalError});
}

class BlockingException extends MindFenceException {
  const BlockingException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

class PermissionException extends MindFenceException {
  const PermissionException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

// Proper error handling in service
class BlockingService {
  Future<Result<bool, BlockingException>> blockApp(String packageName) async {
    try {
      // Validate input
      if (packageName.isEmpty) {
        return Result.failure(
          BlockingException('Package name cannot be empty', code: 'INVALID_PACKAGE_NAME'),
        );
      }
      
      // Check permissions
      if (!await _hasPermissions()) {
        return Result.failure(
          PermissionException('Blocking permissions not granted', code: 'MISSING_PERMISSIONS'),
        );
      }
      
      // Perform blocking
      final success = await _platformChannel.blockApp(packageName);
      
      if (success) {
        _logger.info('Successfully blocked app: $packageName');
        return Result.success(true);
      } else {
        return Result.failure(
          BlockingException('Failed to block app', code: 'BLOCKING_FAILED'),
        );
      }
    } catch (e) {
      _logger.error('Unexpected error blocking app: $packageName', error: e);
      return Result.failure(
        BlockingException('Unexpected error occurred', originalError: e),
      );
    }
  }
}
```

### 2. Result Pattern (Score: 7-10)
- **Explicit Error Handling**: Use Result types for operations that can fail
- **No Exceptions for Control Flow**: Avoid using exceptions for normal flow
- **Clear Success/Failure**: Make success and failure states explicit
- **Composable Operations**: Allow chaining of operations

**Good Example:**
```dart
// Result type for explicit error handling
sealed class Result<T, E> {
  const Result();
  
  factory Result.success(T value) = Success<T, E>;
  factory Result.failure(E error) = Failure<T, E>;
  
  bool get isSuccess => this is Success<T, E>;
  bool get isFailure => this is Failure<T, E>;
  
  T? get value => switch (this) {
    Success<T, E>(value: final v) => v,
    Failure<T, E>() => null,
  };
  
  E? get error => switch (this) {
    Success<T, E>() => null,
    Failure<T, E>(error: final e) => e,
  };
  
  Result<U, E> map<U>(U Function(T) transform) => switch (this) {
    Success<T, E>(value: final v) => Result.success(transform(v)),
    Failure<T, E>(error: final e) => Result.failure(e),
  };
  
  Result<U, E> flatMap<U>(Result<U, E> Function(T) transform) => switch (this) {
    Success<T, E>(value: final v) => transform(v),
    Failure<T, E>(error: final e) => Result.failure(e),
  };
}

final class Success<T, E> extends Result<T, E> {
  final T value;
  const Success(this.value);
}

final class Failure<T, E> extends Result<T, E> {
  final E error;
  const Failure(this.error);
}
```

## Testing and Testability

### 1. Testable Code Design (Score: 8-10)
- **Dependency Injection**: Use dependency injection
- **Pure Functions**: Write pure functions where possible
- **Mockable Dependencies**: Make dependencies easily mockable
- **Small Functions**: Keep functions small and focused

**Good Example:**
```dart
// Testable service with dependency injection
class FocusSessionService {
  final SessionRepository _sessionRepository;
  final TimerService _timerService;
  final NotificationService _notificationService;
  final DateTimeProvider _dateTimeProvider;
  
  FocusSessionService({
    required SessionRepository sessionRepository,
    required TimerService timerService,
    required NotificationService notificationService,
    required DateTimeProvider dateTimeProvider,
  }) : _sessionRepository = sessionRepository,
       _timerService = timerService,
       _notificationService = notificationService,
       _dateTimeProvider = dateTimeProvider;
  
  /// Starts a focus session with the given configuration.
  /// 
  /// This is a pure function that doesn't depend on external state.
  Future<Result<FocusSession, SessionException>> startSession(
    SessionConfig config,
  ) async {
    // Validate configuration
    final validationResult = _validateSessionConfig(config);
    if (validationResult.isFailure) {
      return Result.failure(validationResult.error!);
    }
    
    // Create session
    final session = _createSession(config);
    
    // Save to repository
    final saveResult = await _sessionRepository.saveSession(session);
    if (saveResult.isFailure) {
      return Result.failure(SessionException('Failed to save session'));
    }
    
    // Start timer
    await _timerService.startTimer(session.duration);
    
    // Schedule notifications
    await _notificationService.scheduleSessionNotifications(session);
    
    return Result.success(session);
  }
  
  /// Pure function for validating session configuration.
  Result<void, SessionException> _validateSessionConfig(SessionConfig config) {
    if (config.duration.inMinutes < 1) {
      return Result.failure(
        SessionException('Session duration must be at least 1 minute'),
      );
    }
    
    if (config.blockedApps.isEmpty) {
      return Result.failure(
        SessionException('At least one app must be blocked'),
      );
    }
    
    return Result.success(null);
  }
  
  /// Pure function for creating a session from configuration.
  FocusSession _createSession(SessionConfig config) {
    return FocusSession(
      id: _generateSessionId(),
      name: config.name,
      blockedApps: config.blockedApps,
      startTime: _dateTimeProvider.now(),
      duration: config.duration,
    );
  }
}
```

## Code Review Guidelines

### 1. Review Checklist (Score: 8-10)
- **Functionality**: Does the code work as intended?
- **Readability**: Is the code easy to understand?
- **Performance**: Are there any performance issues?
- **Security**: Are there any security vulnerabilities?
- **Tests**: Are there adequate tests?

**Review Template:**
```markdown
## Code Review Checklist

### Functionality
- [ ] Code implements the required functionality
- [ ] Edge cases are handled appropriately
- [ ] Error conditions are properly managed

### Code Quality
- [ ] Code follows naming conventions
- [ ] Functions are appropriately sized
- [ ] Classes have single responsibilities
- [ ] Dependencies are properly injected

### Security
- [ ] No sensitive information exposed
- [ ] Input validation is implemented
- [ ] Authentication/authorization is correct
- [ ] Data is properly encrypted

### Performance
- [ ] No unnecessary computations
- [ ] Efficient data structures used
- [ ] Memory usage is reasonable
- [ ] Network calls are optimized

### Testing
- [ ] Unit tests are comprehensive
- [ ] Integration tests cover key flows
- [ ] Edge cases are tested
- [ ] Mock usage is appropriate

### Documentation
- [ ] Public APIs are documented
- [ ] Complex logic is explained
- [ ] TODOs are properly formatted
- [ ] Comments add value
```

## Scoring Criteria

### Score 9-10: Excellent
- Perfect code organization and structure
- Comprehensive documentation
- Exceptional error handling
- Highly testable design
- Excellent naming throughout

### Score 7-8: Good
- Good code organization with minor issues
- Adequate documentation
- Proper error handling
- Generally testable
- Good naming conventions

### Score 5-6: Acceptable
- Basic code organization
- Some documentation
- Basic error handling
- Somewhat testable
- Acceptable naming

### Score 3-4: Below Standard
- Poor code organization
- Minimal documentation
- Poor error handling
- Difficult to test
- Inconsistent naming

### Score 1-2: Poor
- No organization
- No documentation
- No error handling
- Not testable
- Poor naming throughout

## Common Anti-Patterns to Avoid

1. **God Classes**: Classes that do too much
2. **Magic Numbers**: Hardcoded values without explanation
3. **Deep Nesting**: Excessive indentation levels
4. **Long Methods**: Methods that do too much
5. **Primitive Obsession**: Overusing primitive types
6. **Feature Envy**: Methods that use more from other classes
7. **Duplicate Code**: Repeated code blocks
8. **Dead Code**: Unused code that should be removed

Remember: Clean code is not just about following rules—it's about writing code that other developers (including your future self) can easily understand, maintain, and extend.