# Architecture Guidelines

## Overview

Mind Fence follows Clean Architecture principles with BLoC pattern for state management. This ensures maintainability, testability, and scalability as the app grows. These guidelines define the architectural standards for all development.

## Clean Architecture Layers

### 1. Domain Layer (Score: 9-10)
- **Business Logic**: Contains all business rules and use cases
- **Entity Classes**: Core business entities
- **Repository Interfaces**: Abstract data access contracts
- **Platform Independence**: No Flutter or platform dependencies

**Good Example:**
```dart
// Domain entity - pure business logic
class BlockingSession extends Equatable {
  const BlockingSession({
    required this.id,
    required this.name,
    required this.blockedAppIds,
    required this.startTime,
    required this.duration,
    required this.status,
  });

  final String id;
  final String name;
  final List<String> blockedAppIds;
  final DateTime startTime;
  final Duration duration;
  final SessionStatus status;

  Duration get remainingTime {
    if (status != SessionStatus.active) {
      return Duration.zero;
    }
    
    final elapsed = DateTime.now().difference(startTime);
    final remaining = duration - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool get isActive => status == SessionStatus.active;
  bool get isExpired => remainingTime == Duration.zero;

  BlockingSession copyWith({
    String? id,
    String? name,
    List<String>? blockedAppIds,
    DateTime? startTime,
    Duration? duration,
    SessionStatus? status,
  }) {
    return BlockingSession(
      id: id ?? this.id,
      name: name ?? this.name,
      blockedAppIds: blockedAppIds ?? this.blockedAppIds,
      startTime: startTime ?? this.startTime,
      duration: duration ?? this.duration,
      status: status ?? this.status,
    );
  }

  @override
  List<Object> get props => [
    id,
    name,
    blockedAppIds,
    startTime,
    duration,
    status,
  ];
}

enum SessionStatus { pending, active, paused, completed, cancelled }
```

**Repository Interface:**
```dart
// Abstract repository - defines contract
abstract class BlockingRepository {
  Future<Result<List<BlockedApp>, RepositoryException>> getBlockedApps();
  
  Future<Result<void, RepositoryException>> updateBlockingState(
    String appId,
    bool isBlocked,
  );
  
  Future<Result<BlockingSession, RepositoryException>> createSession(
    SessionConfig config,
  );
  
  Future<Result<void, RepositoryException>> updateSession(
    BlockingSession session,
  );
  
  Stream<BlockingStateChange> get blockingStateStream;
  Stream<SessionStatusChange> get sessionStatusStream;
}
```

**Use Case Implementation:**
```dart
// Use case - encapsulates business logic
class StartBlockingSessionUseCase {
  const StartBlockingSessionUseCase({
    required BlockingRepository repository,
    required NotificationService notificationService,
    required PlatformBlockingService platformService,
  }) : _repository = repository,
       _notificationService = notificationService,
       _platformService = platformService;

  final BlockingRepository _repository;
  final NotificationService _notificationService;
  final PlatformBlockingService _platformService;

  Future<Result<BlockingSession, UseCaseException>> execute(
    SessionConfig config,
  ) async {
    // Validate configuration
    final validationResult = _validateConfig(config);
    if (validationResult.isFailure) {
      return Result.failure(validationResult.error!);
    }

    // Create session
    final sessionResult = await _repository.createSession(config);
    if (sessionResult.isFailure) {
      return Result.failure(
        UseCaseException('Failed to create session: ${sessionResult.error}'),
      );
    }

    final session = sessionResult.value!;

    // Start platform blocking
    final blockingResult = await _platformService.blockApps(
      session.blockedAppIds,
    );
    if (blockingResult.isFailure) {
      // Cleanup created session
      await _repository.deleteSession(session.id);
      return Result.failure(
        UseCaseException('Failed to start blocking: ${blockingResult.error}'),
      );
    }

    // Schedule notifications
    await _notificationService.scheduleSessionNotifications(session);

    return Result.success(session);
  }

  Result<void, UseCaseException> _validateConfig(SessionConfig config) {
    if (config.duration.inMinutes < 1) {
      return Result.failure(
        const UseCaseException('Session duration must be at least 1 minute'),
      );
    }

    if (config.blockedAppIds.isEmpty) {
      return Result.failure(
        const UseCaseException('At least one app must be blocked'),
      );
    }

    return Result.success(null);
  }
}
```

### 2. Data Layer (Score: 8-10)
- **Repository Implementation**: Concrete implementations of domain interfaces
- **Data Sources**: Remote and local data sources
- **Data Models**: Data transfer objects
- **Mappers**: Convert between data models and domain entities

**Good Example:**
```dart
// Data model - represents data structure
@JsonSerializable()
class BlockedAppModel {
  const BlockedAppModel({
    required this.id,
    required this.name,
    required this.packageName,
    required this.isBlocked,
    this.lastBlocked,
    required this.totalBlockedTimeMs,
  });

  final String id;
  final String name;
  final String packageName;
  final bool isBlocked;
  final DateTime? lastBlocked;
  final int totalBlockedTimeMs;

  factory BlockedAppModel.fromJson(Map<String, dynamic> json) =>
      _$BlockedAppModelFromJson(json);

  Map<String, dynamic> toJson() => _$BlockedAppModelToJson(this);

  // Mapper to domain entity
  BlockedApp toDomain() {
    return BlockedApp(
      id: id,
      name: name,
      packageName: packageName,
      isBlocked: isBlocked,
      lastBlocked: lastBlocked,
      totalBlockedTime: Duration(milliseconds: totalBlockedTimeMs),
    );
  }

  // Mapper from domain entity
  static BlockedAppModel fromDomain(BlockedApp app) {
    return BlockedAppModel(
      id: app.id,
      name: app.name,
      packageName: app.packageName,
      isBlocked: app.isBlocked,
      lastBlocked: app.lastBlocked,
      totalBlockedTimeMs: app.totalBlockedTime.inMilliseconds,
    );
  }
}
```

**Repository Implementation:**
```dart
// Repository implementation - coordinates data sources
class BlockingRepositoryImpl implements BlockingRepository {
  const BlockingRepositoryImpl({
    required LocalDataSource localDataSource,
    required RemoteDataSource remoteDataSource,
    required NetworkInfo networkInfo,
  }) : _localDataSource = localDataSource,
       _remoteDataSource = remoteDataSource,
       _networkInfo = networkInfo;

  final LocalDataSource _localDataSource;
  final RemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  @override
  Future<Result<List<BlockedApp>, RepositoryException>> getBlockedApps() async {
    try {
      // Try to get from cache first
      final cachedApps = await _localDataSource.getBlockedApps();
      
      if (await _networkInfo.isConnected) {
        // Fetch from remote and update cache
        final remoteResult = await _remoteDataSource.getBlockedApps();
        if (remoteResult.isSuccess) {
          await _localDataSource.cacheBlockedApps(remoteResult.value!);
          return Result.success(
            remoteResult.value!.map((model) => model.toDomain()).toList(),
          );
        }
      }

      // Return cached data if available
      if (cachedApps.isNotEmpty) {
        return Result.success(
          cachedApps.map((model) => model.toDomain()).toList(),
        );
      }

      return Result.failure(
        const RepositoryException('No data available'),
      );
    } catch (e) {
      return Result.failure(
        RepositoryException('Failed to get blocked apps: $e'),
      );
    }
  }

  @override
  Future<Result<void, RepositoryException>> updateBlockingState(
    String appId,
    bool isBlocked,
  ) async {
    try {
      // Update local cache first
      await _localDataSource.updateBlockingState(appId, isBlocked);

      // Sync with remote if connected
      if (await _networkInfo.isConnected) {
        final remoteResult = await _remoteDataSource.updateBlockingState(
          appId,
          isBlocked,
        );
        
        if (remoteResult.isFailure) {
          // Rollback local changes
          await _localDataSource.updateBlockingState(appId, !isBlocked);
          return Result.failure(
            RepositoryException('Failed to sync with server: ${remoteResult.error}'),
          );
        }
      }

      return Result.success(null);
    } catch (e) {
      return Result.failure(
        RepositoryException('Failed to update blocking state: $e'),
      );
    }
  }

  @override
  Stream<BlockingStateChange> get blockingStateStream {
    return _localDataSource.blockingStateStream.map(
      (change) => BlockingStateChange(
        appId: change.appId,
        isBlocked: change.isBlocked,
        timestamp: change.timestamp,
      ),
    );
  }
}
```

### 3. Presentation Layer (Score: 8-10)
- **BLoC Classes**: State management and business logic coordination
- **UI Components**: Widgets and screens
- **State Classes**: Immutable state representations
- **Event Classes**: User interaction events

**Good Example:**
```dart
// BLoC - coordinates presentation logic
class BlockingBloc extends Bloc<BlockingEvent, BlockingState> {
  BlockingBloc({
    required StartBlockingSessionUseCase startSessionUseCase,
    required StopBlockingSessionUseCase stopSessionUseCase,
    required GetBlockedAppsUseCase getBlockedAppsUseCase,
    required ToggleAppBlockingUseCase toggleAppBlockingUseCase,
  }) : _startSessionUseCase = startSessionUseCase,
       _stopSessionUseCase = stopSessionUseCase,
       _getBlockedAppsUseCase = getBlockedAppsUseCase,
       _toggleAppBlockingUseCase = toggleAppBlockingUseCase,
       super(const BlockingState.initial()) {
    on<BlockingEvent>(_onBlockingEvent);
    
    // Listen to repository changes
    _setupRepositoryListeners();
  }

  final StartBlockingSessionUseCase _startSessionUseCase;
  final StopBlockingSessionUseCase _stopSessionUseCase;
  final GetBlockedAppsUseCase _getBlockedAppsUseCase;
  final ToggleAppBlockingUseCase _toggleAppBlockingUseCase;

  late final StreamSubscription _blockingStateSubscription;

  void _setupRepositoryListeners() {
    _blockingStateSubscription = _getBlockedAppsUseCase.blockingStateStream.listen(
      (change) {
        add(BlockingStateChanged(change));
      },
    );
  }

  Future<void> _onBlockingEvent(
    BlockingEvent event,
    Emitter<BlockingState> emit,
  ) async {
    switch (event) {
      case LoadBlockedApps():
        await _onLoadBlockedApps(emit);
      case ToggleAppBlocking():
        await _onToggleAppBlocking(event, emit);
      case StartFocusSession():
        await _onStartFocusSession(event, emit);
      case StopFocusSession():
        await _onStopFocusSession(event, emit);
      case BlockingStateChanged():
        await _onBlockingStateChanged(event, emit);
    }
  }

  Future<void> _onLoadBlockedApps(Emitter<BlockingState> emit) async {
    emit(state.copyWith(status: BlockingStatus.loading));

    final result = await _getBlockedAppsUseCase.execute();
    
    result.when(
      success: (apps) => emit(state.copyWith(
        status: BlockingStatus.loaded,
        blockedApps: apps,
      )),
      failure: (error) => emit(state.copyWith(
        status: BlockingStatus.error,
        error: error.message,
      )),
    );
  }

  Future<void> _onStartFocusSession(
    StartFocusSession event,
    Emitter<BlockingState> emit,
  ) async {
    emit(state.copyWith(sessionStatus: SessionStatus.starting));

    final result = await _startSessionUseCase.execute(event.config);
    
    result.when(
      success: (session) => emit(state.copyWith(
        sessionStatus: SessionStatus.active,
        currentSession: session,
      )),
      failure: (error) => emit(state.copyWith(
        sessionStatus: SessionStatus.idle,
        error: error.message,
      )),
    );
  }

  @override
  Future<void> close() {
    _blockingStateSubscription.cancel();
    return super.close();
  }
}
```

## Dependency Injection

### 1. Service Locator Pattern (Score: 8-10)
- **get_it Package**: Use get_it for dependency injection
- **Registration**: Register dependencies at app startup
- **Scoping**: Proper scoping of dependencies
- **Testing**: Easy mocking for tests

**Good Example:**
```dart
// Service locator setup
final GetIt serviceLocator = GetIt.instance;

Future<void> setupServiceLocator() async {
  // External services
  serviceLocator.registerSingleton<Dio>(
    Dio()..interceptors.add(LogInterceptor()),
  );
  
  serviceLocator.registerSingleton<FlutterSecureStorage>(
    const FlutterSecureStorage(),
  );

  // Core services
  serviceLocator.registerSingleton<NetworkInfo>(
    NetworkInfoImpl(DataConnectionChecker()),
  );

  // Data sources
  serviceLocator.registerSingleton<LocalDataSource>(
    LocalDataSourceImpl(
      secureStorage: serviceLocator<FlutterSecureStorage>(),
    ),
  );
  
  serviceLocator.registerSingleton<RemoteDataSource>(
    RemoteDataSourceImpl(
      dio: serviceLocator<Dio>(),
    ),
  );

  // Repositories
  serviceLocator.registerSingleton<BlockingRepository>(
    BlockingRepositoryImpl(
      localDataSource: serviceLocator<LocalDataSource>(),
      remoteDataSource: serviceLocator<RemoteDataSource>(),
      networkInfo: serviceLocator<NetworkInfo>(),
    ),
  );

  // Use cases
  serviceLocator.registerSingleton<StartBlockingSessionUseCase>(
    StartBlockingSessionUseCase(
      repository: serviceLocator<BlockingRepository>(),
      notificationService: serviceLocator<NotificationService>(),
      platformService: serviceLocator<PlatformBlockingService>(),
    ),
  );

  // BLoCs - Factory registration for multiple instances
  serviceLocator.registerFactory<BlockingBloc>(
    () => BlockingBloc(
      startSessionUseCase: serviceLocator<StartBlockingSessionUseCase>(),
      stopSessionUseCase: serviceLocator<StopBlockingSessionUseCase>(),
      getBlockedAppsUseCase: serviceLocator<GetBlockedAppsUseCase>(),
      toggleAppBlockingUseCase: serviceLocator<ToggleAppBlockingUseCase>(),
    ),
  );
}
```

### 2. Testable Architecture (Score: 8-10)
- **Interface Segregation**: Use interfaces for all dependencies
- **Mockable Services**: All external dependencies can be mocked
- **Dependency Injection**: Dependencies injected through constructors
- **Pure Functions**: Business logic in pure functions where possible

**Good Example:**
```dart
// Abstract interfaces for testability
abstract class NetworkInfo {
  Future<bool> get isConnected;
}

abstract class NotificationService {
  Future<void> scheduleSessionNotifications(BlockingSession session);
  Future<void> cancelSessionNotifications(String sessionId);
}

abstract class PlatformBlockingService {
  Future<Result<bool, BlockingException>> blockApps(List<String> packageNames);
  Future<Result<bool, BlockingException>> unblockApps(List<String> packageNames);
}

// Testable use case with injected dependencies
class StartBlockingSessionUseCase {
  const StartBlockingSessionUseCase({
    required BlockingRepository repository,
    required NotificationService notificationService,
    required PlatformBlockingService platformService,
    required Logger logger,
  }) : _repository = repository,
       _notificationService = notificationService,
       _platformService = platformService,
       _logger = logger;

  final BlockingRepository _repository;
  final NotificationService _notificationService;
  final PlatformBlockingService _platformService;
  final Logger _logger;

  Future<Result<BlockingSession, UseCaseException>> execute(
    SessionConfig config,
  ) async {
    _logger.info('Starting blocking session with config: $config');

    // Pure function for validation
    final validationResult = validateSessionConfig(config);
    if (validationResult.isFailure) {
      _logger.warning('Invalid session config: ${validationResult.error}');
      return Result.failure(validationResult.error!);
    }

    // Create session through repository
    final sessionResult = await _repository.createSession(config);
    if (sessionResult.isFailure) {
      _logger.error('Failed to create session: ${sessionResult.error}');
      return Result.failure(
        UseCaseException('Failed to create session: ${sessionResult.error}'),
      );
    }

    final session = sessionResult.value!;

    // Start platform blocking
    final blockingResult = await _platformService.blockApps(
      session.blockedAppIds,
    );
    if (blockingResult.isFailure) {
      _logger.error('Failed to block apps: ${blockingResult.error}');
      // Cleanup created session
      await _repository.deleteSession(session.id);
      return Result.failure(
        UseCaseException('Failed to start blocking: ${blockingResult.error}'),
      );
    }

    // Schedule notifications
    try {
      await _notificationService.scheduleSessionNotifications(session);
    } catch (e) {
      _logger.warning('Failed to schedule notifications: $e');
      // Don't fail the use case for notification errors
    }

    _logger.info('Successfully started blocking session: ${session.id}');
    return Result.success(session);
  }
}

// Pure function for validation (easily testable)
Result<void, UseCaseException> validateSessionConfig(SessionConfig config) {
  if (config.duration.inMinutes < 1) {
    return Result.failure(
      const UseCaseException('Session duration must be at least 1 minute'),
    );
  }

  if (config.duration.inHours > 24) {
    return Result.failure(
      const UseCaseException('Session duration cannot exceed 24 hours'),
    );
  }

  if (config.blockedAppIds.isEmpty) {
    return Result.failure(
      const UseCaseException('At least one app must be blocked'),
    );
  }

  if (config.blockedAppIds.length > 50) {
    return Result.failure(
      const UseCaseException('Cannot block more than 50 apps per session'),
    );
  }

  return Result.success(null);
}
```

## Error Handling Architecture

### 1. Hierarchical Error Handling (Score: 8-10)
- **Domain Errors**: Business logic errors
- **Repository Errors**: Data access errors
- **Network Errors**: Communication errors
- **Platform Errors**: Native platform errors

**Good Example:**
```dart
// Error hierarchy
abstract class AppException implements Exception {
  const AppException(this.message, {this.code});
  
  final String message;
  final String? code;
}

// Domain layer errors
class UseCaseException extends AppException {
  const UseCaseException(String message, {String? code}) 
      : super(message, code: code);
}

class ValidationException extends AppException {
  const ValidationException(String message, {String? code}) 
      : super(message, code: code);
}

// Data layer errors
class RepositoryException extends AppException {
  const RepositoryException(String message, {String? code}) 
      : super(message, code: code);
}

class NetworkException extends AppException {
  const NetworkException(String message, {String? code}) 
      : super(message, code: code);
}

class CacheException extends AppException {
  const CacheException(String message, {String? code}) 
      : super(message, code: code);
}

// Platform layer errors
class PlatformException extends AppException {
  const PlatformException(String message, {String? code}) 
      : super(message, code: code);
}

class PermissionException extends AppException {
  const PermissionException(String message, {String? code}) 
      : super(message, code: code);
}

// Error handling in BLoC
class BlockingBloc extends Bloc<BlockingEvent, BlockingState> {
  // ... other code ...

  void _handleError(AppException error, Emitter<BlockingState> emit) {
    switch (error.runtimeType) {
      case ValidationException:
        emit(state.copyWith(
          status: BlockingStatus.error,
          error: 'Invalid input: ${error.message}',
          errorType: ErrorType.validation,
        ));
      case NetworkException:
        emit(state.copyWith(
          status: BlockingStatus.error,
          error: 'Network error: ${error.message}',
          errorType: ErrorType.network,
        ));
      case PermissionException:
        emit(state.copyWith(
          status: BlockingStatus.error,
          error: 'Permission required: ${error.message}',
          errorType: ErrorType.permission,
        ));
      default:
        emit(state.copyWith(
          status: BlockingStatus.error,
          error: error.message,
          errorType: ErrorType.unknown,
        ));
    }
  }
}
```

## Testing Architecture

### 1. Layer-Specific Testing (Score: 8-10)
- **Unit Tests**: Test domain logic and use cases
- **Repository Tests**: Test data layer logic
- **BLoC Tests**: Test presentation logic
- **Integration Tests**: Test complete flows

**Good Example:**
```dart
// Use case test
void main() {
  group('StartBlockingSessionUseCase', () {
    late StartBlockingSessionUseCase useCase;
    late MockBlockingRepository mockRepository;
    late MockNotificationService mockNotificationService;
    late MockPlatformBlockingService mockPlatformService;
    late MockLogger mockLogger;

    setUp(() {
      mockRepository = MockBlockingRepository();
      mockNotificationService = MockNotificationService();
      mockPlatformService = MockPlatformBlockingService();
      mockLogger = MockLogger();
      
      useCase = StartBlockingSessionUseCase(
        repository: mockRepository,
        notificationService: mockNotificationService,
        platformService: mockPlatformService,
        logger: mockLogger,
      );
    });

    test('should start session successfully when all dependencies succeed', () async {
      // Arrange
      final config = SessionConfig(
        name: 'Test Session',
        duration: const Duration(hours: 1),
        blockedAppIds: ['com.test.app'],
      );
      
      final expectedSession = BlockingSession(
        id: 'test-session-id',
        name: 'Test Session',
        blockedAppIds: ['com.test.app'],
        startTime: DateTime.now(),
        duration: const Duration(hours: 1),
        status: SessionStatus.active,
      );

      when(() => mockRepository.createSession(config))
          .thenAnswer((_) async => Result.success(expectedSession));
      
      when(() => mockPlatformService.blockApps(['com.test.app']))
          .thenAnswer((_) async => Result.success(true));
      
      when(() => mockNotificationService.scheduleSessionNotifications(expectedSession))
          .thenAnswer((_) async {});

      // Act
      final result = await useCase.execute(config);

      // Assert
      expect(result.isSuccess, true);
      expect(result.value, equals(expectedSession));
      
      verify(() => mockRepository.createSession(config)).called(1);
      verify(() => mockPlatformService.blockApps(['com.test.app'])).called(1);
      verify(() => mockNotificationService.scheduleSessionNotifications(expectedSession)).called(1);
    });

    test('should fail when session config is invalid', () async {
      // Arrange
      final invalidConfig = SessionConfig(
        name: 'Test Session',
        duration: const Duration(seconds: 30), // Too short
        blockedAppIds: ['com.test.app'],
      );

      // Act
      final result = await useCase.execute(invalidConfig);

      // Assert
      expect(result.isFailure, true);
      expect(result.error, isA<UseCaseException>());
      expect(result.error!.message, contains('duration must be at least 1 minute'));
      
      // Verify no external calls were made
      verifyNever(() => mockRepository.createSession(any()));
      verifyNever(() => mockPlatformService.blockApps(any()));
      verifyNever(() => mockNotificationService.scheduleSessionNotifications(any()));
    });
  });
}
```

## Scoring Criteria

### Score 9-10: Excellent
- Perfect layer separation with clear boundaries
- Complete dependency injection setup
- Comprehensive error handling hierarchy
- Extensive testing coverage
- Exemplary use case implementation

### Score 7-8: Good
- Good layer separation with minor violations
- Adequate dependency injection
- Good error handling with some gaps
- Good testing coverage
- Solid use case implementation

### Score 5-6: Acceptable
- Basic layer separation
- Some dependency injection
- Basic error handling
- Limited testing
- Functional use cases

### Score 3-4: Below Standard
- Poor layer separation
- Limited dependency injection
- Weak error handling
- Minimal testing
- Poorly structured use cases

### Score 1-2: Poor
- No architectural patterns
- No dependency injection
- No error handling
- No testing
- Monolithic structure

## Common Architectural Anti-Patterns to Avoid

1. **God Classes**: Classes that know too much or do too much
2. **Circular Dependencies**: Dependencies that create cycles
3. **Tight Coupling**: Classes that depend on concrete implementations
4. **Anemic Domain Model**: Domain objects with no behavior
5. **Feature Envy**: Classes that use other classes' data excessively
6. **Leaky Abstractions**: Abstractions that expose implementation details
7. **Shared Mutable State**: Global state that can be modified from anywhere
8. **Direct Database Access**: UI components accessing data directly
9. **Platform Dependencies in Domain**: Domain layer depending on Flutter/platform
10. **Business Logic in UI**: Presentation layer containing business rules

## Architecture Documentation

### 1. Component Diagrams (Score: 8-10)
- **Layer Dependencies**: Clear dependency flow
- **Interface Definitions**: Well-defined interfaces
- **Data Flow**: Clear data transformation paths
- **Error Propagation**: Error handling flows

### 2. Sequence Diagrams (Score: 7-10)
- **Use Case Flows**: Complete user interaction flows
- **Error Scenarios**: Error handling sequences
- **Integration Points**: External system interactions
- **State Changes**: State transition sequences

Remember: Architecture is about making decisions that enable the team to be productive over the long term. Good architecture minimizes the cost of change and maximizes the ability to test and maintain the system.