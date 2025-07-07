# Testing Guidelines

## Overview

Comprehensive testing is essential for the Mind Fence app to ensure reliability, security, and user trust. These guidelines cover all aspects of testing from unit tests to end-to-end integration tests, with specific focus on blocking functionality and security features.

## Testing Strategy

### 1. Testing Pyramid (Score: 8-10)
- **Unit Tests (70%)**: Test individual components and business logic
- **Integration Tests (20%)**: Test component interactions
- **End-to-End Tests (10%)**: Test complete user workflows
- **Manual Testing**: Exploratory testing for edge cases

**Test Coverage Requirements:**
- **Minimum**: 80% overall code coverage
- **Domain Layer**: 95% coverage (critical business logic)
- **Data Layer**: 85% coverage (data handling)
- **Presentation Layer**: 70% coverage (UI logic)

### 2. Test Categories (Score: 8-10)
- **Unit Tests**: Individual functions and classes
- **Widget Tests**: UI components and interactions
- **Integration Tests**: Feature-level workflows
- **Golden Tests**: UI appearance verification
- **Security Tests**: Vulnerability and bypass testing

## Unit Testing

### 1. Domain Layer Testing (Score: 9-10)
- **Pure Functions**: Test business logic without dependencies
- **Entity Validation**: Test entity creation and validation
- **Use Case Logic**: Test complete use case scenarios
- **Error Handling**: Test all error conditions

**Good Example:**
```dart
// Testing a use case with comprehensive scenarios
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

    group('successful execution', () {
      test('should create and start session with valid config', () async {
        // Arrange
        final config = SessionConfig(
          name: 'Focus Session',
          duration: const Duration(hours: 2),
          blockedAppIds: ['com.instagram.android', 'com.twitter.android'],
        );
        
        final expectedSession = BlockingSession(
          id: 'session-123',
          name: 'Focus Session',
          blockedAppIds: ['com.instagram.android', 'com.twitter.android'],
          startTime: DateTime.now(),
          duration: const Duration(hours: 2),
          status: SessionStatus.active,
        );

        when(() => mockRepository.createSession(config))
            .thenAnswer((_) async => Result.success(expectedSession));
        
        when(() => mockPlatformService.blockApps(['com.instagram.android', 'com.twitter.android']))
            .thenAnswer((_) async => Result.success(true));
        
        when(() => mockNotificationService.scheduleSessionNotifications(expectedSession))
            .thenAnswer((_) async {});

        // Act
        final result = await useCase.execute(config);

        // Assert
        expect(result.isSuccess, true);
        expect(result.value, equals(expectedSession));
        
        verify(() => mockRepository.createSession(config)).called(1);
        verify(() => mockPlatformService.blockApps(['com.instagram.android', 'com.twitter.android'])).called(1);
        verify(() => mockNotificationService.scheduleSessionNotifications(expectedSession)).called(1);
      });

      test('should handle notification scheduling failure gracefully', () async {
        // Arrange
        final config = SessionConfig(
          name: 'Focus Session',
          duration: const Duration(hours: 1),
          blockedAppIds: ['com.instagram.android'],
        );
        
        final expectedSession = BlockingSession(
          id: 'session-123',
          name: 'Focus Session',
          blockedAppIds: ['com.instagram.android'],
          startTime: DateTime.now(),
          duration: const Duration(hours: 1),
          status: SessionStatus.active,
        );

        when(() => mockRepository.createSession(config))
            .thenAnswer((_) async => Result.success(expectedSession));
        
        when(() => mockPlatformService.blockApps(['com.instagram.android']))
            .thenAnswer((_) async => Result.success(true));
        
        when(() => mockNotificationService.scheduleSessionNotifications(expectedSession))
            .thenThrow(Exception('Notification permission denied'));

        // Act
        final result = await useCase.execute(config);

        // Assert - should still succeed even if notifications fail
        expect(result.isSuccess, true);
        expect(result.value, equals(expectedSession));
        
        verify(() => mockLogger.warning('Failed to schedule notifications: Exception: Notification permission denied')).called(1);
      });
    });

    group('validation errors', () {
      test('should fail when duration is too short', () async {
        // Arrange
        final config = SessionConfig(
          name: 'Focus Session',
          duration: const Duration(seconds: 30),
          blockedAppIds: ['com.instagram.android'],
        );

        // Act
        final result = await useCase.execute(config);

        // Assert
        expect(result.isFailure, true);
        expect(result.error, isA<UseCaseException>());
        expect(result.error!.message, contains('duration must be at least 1 minute'));
        
        verifyNever(() => mockRepository.createSession(any()));
        verifyNever(() => mockPlatformService.blockApps(any()));
      });

      test('should fail when no apps are selected', () async {
        // Arrange
        final config = SessionConfig(
          name: 'Focus Session',
          duration: const Duration(hours: 1),
          blockedAppIds: [],
        );

        // Act
        final result = await useCase.execute(config);

        // Assert
        expect(result.isFailure, true);
        expect(result.error, isA<UseCaseException>());
        expect(result.error!.message, contains('At least one app must be blocked'));
      });

      test('should fail when duration exceeds maximum', () async {
        // Arrange
        final config = SessionConfig(
          name: 'Focus Session',
          duration: const Duration(hours: 25),
          blockedAppIds: ['com.instagram.android'],
        );

        // Act
        final result = await useCase.execute(config);

        // Assert
        expect(result.isFailure, true);
        expect(result.error, isA<UseCaseException>());
        expect(result.error!.message, contains('duration cannot exceed 24 hours'));
      });
    });

    group('repository errors', () {
      test('should fail when repository cannot create session', () async {
        // Arrange
        final config = SessionConfig(
          name: 'Focus Session',
          duration: const Duration(hours: 1),
          blockedAppIds: ['com.instagram.android'],
        );

        when(() => mockRepository.createSession(config))
            .thenAnswer((_) async => Result.failure(
              const RepositoryException('Database connection failed')));

        // Act
        final result = await useCase.execute(config);

        // Assert
        expect(result.isFailure, true);
        expect(result.error, isA<UseCaseException>());
        expect(result.error!.message, contains('Failed to create session'));
        
        verify(() => mockRepository.createSession(config)).called(1);
        verifyNever(() => mockPlatformService.blockApps(any()));
      });
    });

    group('platform blocking errors', () {
      test('should cleanup session when platform blocking fails', () async {
        // Arrange
        final config = SessionConfig(
          name: 'Focus Session',
          duration: const Duration(hours: 1),
          blockedAppIds: ['com.instagram.android'],
        );
        
        final createdSession = BlockingSession(
          id: 'session-123',
          name: 'Focus Session',
          blockedAppIds: ['com.instagram.android'],
          startTime: DateTime.now(),
          duration: const Duration(hours: 1),
          status: SessionStatus.active,
        );

        when(() => mockRepository.createSession(config))
            .thenAnswer((_) async => Result.success(createdSession));
        
        when(() => mockPlatformService.blockApps(['com.instagram.android']))
            .thenAnswer((_) async => Result.failure(
              const BlockingException('Device admin permission denied')));
        
        when(() => mockRepository.deleteSession('session-123'))
            .thenAnswer((_) async => Result.success(null));

        // Act
        final result = await useCase.execute(config);

        // Assert
        expect(result.isFailure, true);
        expect(result.error, isA<UseCaseException>());
        expect(result.error!.message, contains('Failed to start blocking'));
        
        verify(() => mockRepository.createSession(config)).called(1);
        verify(() => mockPlatformService.blockApps(['com.instagram.android'])).called(1);
        verify(() => mockRepository.deleteSession('session-123')).called(1);
      });
    });
  });
}
```

### 2. Entity Testing (Score: 8-10)
- **Value Objects**: Test immutability and equality
- **Business Rules**: Test domain rules and constraints
- **State Transitions**: Test valid state changes
- **Edge Cases**: Test boundary conditions

**Good Example:**
```dart
// Comprehensive entity testing
void main() {
  group('BlockingSession', () {
    test('should create session with valid parameters', () {
      // Arrange
      final startTime = DateTime.now();
      final duration = const Duration(hours: 2);
      final blockedAppIds = ['com.instagram.android', 'com.twitter.android'];

      // Act
      final session = BlockingSession(
        id: 'session-123',
        name: 'Focus Session',
        blockedAppIds: blockedAppIds,
        startTime: startTime,
        duration: duration,
        status: SessionStatus.active,
      );

      // Assert
      expect(session.id, 'session-123');
      expect(session.name, 'Focus Session');
      expect(session.blockedAppIds, blockedAppIds);
      expect(session.startTime, startTime);
      expect(session.duration, duration);
      expect(session.status, SessionStatus.active);
    });

    test('should calculate remaining time correctly for active session', () {
      // Arrange
      final startTime = DateTime.now().subtract(const Duration(minutes: 30));
      final duration = const Duration(hours: 2);
      
      final session = BlockingSession(
        id: 'session-123',
        name: 'Focus Session',
        blockedAppIds: ['com.instagram.android'],
        startTime: startTime,
        duration: duration,
        status: SessionStatus.active,
      );

      // Act
      final remainingTime = session.remainingTime;

      // Assert
      expect(remainingTime.inMinutes, closeTo(90, 1)); // 2 hours - 30 minutes
    });

    test('should return zero remaining time for expired session', () {
      // Arrange
      final startTime = DateTime.now().subtract(const Duration(hours: 3));
      final duration = const Duration(hours: 2);
      
      final session = BlockingSession(
        id: 'session-123',
        name: 'Focus Session',
        blockedAppIds: ['com.instagram.android'],
        startTime: startTime,
        duration: duration,
        status: SessionStatus.active,
      );

      // Act
      final remainingTime = session.remainingTime;

      // Assert
      expect(remainingTime, Duration.zero);
      expect(session.isExpired, true);
    });

    test('should return zero remaining time for non-active session', () {
      // Arrange
      final startTime = DateTime.now();
      final duration = const Duration(hours: 2);
      
      final session = BlockingSession(
        id: 'session-123',
        name: 'Focus Session',
        blockedAppIds: ['com.instagram.android'],
        startTime: startTime,
        duration: duration,
        status: SessionStatus.paused,
      );

      // Act
      final remainingTime = session.remainingTime;

      // Assert
      expect(remainingTime, Duration.zero);
      expect(session.isActive, false);
    });

    test('should support equality comparison', () {
      // Arrange
      final startTime = DateTime.now();
      final duration = const Duration(hours: 2);
      final blockedAppIds = ['com.instagram.android'];

      final session1 = BlockingSession(
        id: 'session-123',
        name: 'Focus Session',
        blockedAppIds: blockedAppIds,
        startTime: startTime,
        duration: duration,
        status: SessionStatus.active,
      );

      final session2 = BlockingSession(
        id: 'session-123',
        name: 'Focus Session',
        blockedAppIds: blockedAppIds,
        startTime: startTime,
        duration: duration,
        status: SessionStatus.active,
      );

      final session3 = BlockingSession(
        id: 'session-456',
        name: 'Focus Session',
        blockedAppIds: blockedAppIds,
        startTime: startTime,
        duration: duration,
        status: SessionStatus.active,
      );

      // Assert
      expect(session1, equals(session2));
      expect(session1, isNot(equals(session3)));
    });

    test('should create copy with modified properties', () {
      // Arrange
      final originalSession = BlockingSession(
        id: 'session-123',
        name: 'Focus Session',
        blockedAppIds: ['com.instagram.android'],
        startTime: DateTime.now(),
        duration: const Duration(hours: 2),
        status: SessionStatus.active,
      );

      // Act
      final modifiedSession = originalSession.copyWith(
        status: SessionStatus.paused,
        name: 'Paused Session',
      );

      // Assert
      expect(modifiedSession.id, originalSession.id);
      expect(modifiedSession.name, 'Paused Session');
      expect(modifiedSession.status, SessionStatus.paused);
      expect(modifiedSession.blockedAppIds, originalSession.blockedAppIds);
      expect(modifiedSession.startTime, originalSession.startTime);
      expect(modifiedSession.duration, originalSession.duration);
    });
  });
}
```

## Widget Testing

### 1. Component Testing (Score: 8-10)
- **User Interactions**: Test taps, scrolls, and input
- **State Updates**: Test widget state changes
- **Accessibility**: Test screen reader support
- **Visual Feedback**: Test loading states and animations

**Good Example:**
```dart
// Comprehensive widget testing
void main() {
  group('BlockingStatusCard', () {
    late MockBlockingBloc mockBloc;
    late BlockedApp testApp;

    setUp(() {
      mockBloc = MockBlockingBloc();
      testApp = BlockedApp(
        id: 'app-123',
        name: 'Instagram',
        packageName: 'com.instagram.android',
        isBlocked: false,
        lastBlocked: DateTime.now().subtract(const Duration(hours: 1)),
        totalBlockedTime: const Duration(hours: 5, minutes: 30),
      );
    });

    testWidgets('should display app information correctly', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlockingStatusCard(
              app: testApp,
              onToggle: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Instagram'), findsOneWidget);
      expect(find.text('com.instagram.android'), findsOneWidget);
      expect(find.text('Not blocked'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('should display blocked status correctly', (tester) async {
      // Arrange
      final blockedApp = testApp.copyWith(isBlocked: true);
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlockingStatusCard(
              app: blockedApp,
              onToggle: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Currently blocked'), findsOneWidget);
      expect(find.byIcon(Icons.block), findsOneWidget);
      
      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, true);
    });

    testWidgets('should call onToggle when switch is tapped', (tester) async {
      // Arrange
      bool toggleCalled = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlockingStatusCard(
              app: testApp,
              onToggle: () => toggleCalled = true,
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.byType(Switch));
      await tester.pump();

      // Assert
      expect(toggleCalled, true);
    });

    testWidgets('should show details when expanded', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlockingStatusCard(
              app: testApp,
              onToggle: () {},
              showDetails: true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Package: com.instagram.android'), findsOneWidget);
      expect(find.textContaining('Last blocked:'), findsOneWidget);
      expect(find.text('Total blocked time: 5h 30m'), findsOneWidget);
    });

    testWidgets('should be accessible to screen readers', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlockingStatusCard(
              app: testApp,
              onToggle: () {},
            ),
          ),
        ),
      );

      // Assert
      final semantics = tester.getSemantics(find.byType(Switch));
      expect(semantics.label, contains('Block Instagram'));
      expect(semantics.hint, contains('Currently not blocked'));
    });

    testWidgets('should handle loading state', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlockingStatusCard(
              app: testApp,
              onToggle: () {},
              isLoading: true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.onChanged, isNull); // Should be disabled
    });

    testWidgets('should animate status change', (tester) async {
      // Arrange
      bool isBlocked = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: BlockingStatusCard(
                  app: testApp.copyWith(isBlocked: isBlocked),
                  onToggle: () => setState(() => isBlocked = !isBlocked),
                ),
              );
            },
          ),
        ),
      );

      // Act
      await tester.tap(find.byType(Switch));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Assert
      expect(find.byIcon(Icons.block), findsOneWidget);
      expect(find.text('Currently blocked'), findsOneWidget);
    });
  });
}
```

### 2. Screen Testing (Score: 8-10)
- **Complete Flows**: Test entire screen workflows
- **Navigation**: Test navigation between screens
- **Error States**: Test error handling and display
- **Edge Cases**: Test with different data states

**Good Example:**
```dart
// Complete screen testing
void main() {
  group('BlockingScreen', () {
    late MockBlockingBloc mockBloc;

    setUp(() {
      mockBloc = MockBlockingBloc();
    });

    testWidgets('should display loading state initially', (tester) async {
      // Arrange
      when(() => mockBloc.state).thenReturn(
        const BlockingState(status: BlockingStatus.loading),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<BlockingBloc>.value(
            value: mockBloc,
            child: const BlockingScreen(),
          ),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading...'), findsOneWidget);
    });

    testWidgets('should display blocked apps when loaded', (tester) async {
      // Arrange
      final blockedApps = [
        BlockedApp(
          id: 'app-1',
          name: 'Instagram',
          packageName: 'com.instagram.android',
          isBlocked: true,
          totalBlockedTime: const Duration(hours: 2),
        ),
        BlockedApp(
          id: 'app-2',
          name: 'Twitter',
          packageName: 'com.twitter.android',
          isBlocked: false,
          totalBlockedTime: const Duration(hours: 1),
        ),
      ];

      when(() => mockBloc.state).thenReturn(
        BlockingState(
          status: BlockingStatus.loaded,
          blockedApps: blockedApps,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<BlockingBloc>.value(
            value: mockBloc,
            child: const BlockingScreen(),
          ),
        ),
      );

      // Assert
      expect(find.text('Instagram'), findsOneWidget);
      expect(find.text('Twitter'), findsOneWidget);
      expect(find.byType(BlockingStatusCard), findsNWidgets(2));
    });

    testWidgets('should display empty state when no apps', (tester) async {
      // Arrange
      when(() => mockBloc.state).thenReturn(
        const BlockingState(
          status: BlockingStatus.loaded,
          blockedApps: [],
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<BlockingBloc>.value(
            value: mockBloc,
            child: const BlockingScreen(),
          ),
        ),
      );

      // Assert
      expect(find.text('No blocked apps'), findsOneWidget);
      expect(find.text('Add some apps to get started'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('should display error state with retry option', (tester) async {
      // Arrange
      when(() => mockBloc.state).thenReturn(
        const BlockingState(
          status: BlockingStatus.error,
          error: 'Failed to load blocked apps',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<BlockingBloc>.value(
            value: mockBloc,
            child: const BlockingScreen(),
          ),
        ),
      );

      // Assert
      expect(find.text('Error: Failed to load blocked apps'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);

      // Act
      await tester.tap(find.text('Retry'));
      await tester.pump();

      // Assert
      verify(() => mockBloc.add(const LoadBlockedApps())).called(1);
    });

    testWidgets('should toggle app blocking when switch is tapped', (tester) async {
      // Arrange
      final blockedApp = BlockedApp(
        id: 'app-1',
        name: 'Instagram',
        packageName: 'com.instagram.android',
        isBlocked: false,
        totalBlockedTime: const Duration(hours: 2),
      );

      when(() => mockBloc.state).thenReturn(
        BlockingState(
          status: BlockingStatus.loaded,
          blockedApps: [blockedApp],
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<BlockingBloc>.value(
            value: mockBloc,
            child: const BlockingScreen(),
          ),
        ),
      );

      // Act
      await tester.tap(find.byType(Switch));
      await tester.pump();

      // Assert
      verify(() => mockBloc.add(const ToggleAppBlocking('app-1'))).called(1);
    });

    testWidgets('should navigate to add app screen when FAB is tapped', (tester) async {
      // Arrange
      when(() => mockBloc.state).thenReturn(
        const BlockingState(
          status: BlockingStatus.loaded,
          blockedApps: [],
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<BlockingBloc>.value(
            value: mockBloc,
            child: const BlockingScreen(),
          ),
        ),
      );

      // Act
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(AddAppScreen), findsOneWidget);
    });

    testWidgets('should show snackbar on error', (tester) async {
      // Arrange
      when(() => mockBloc.state).thenReturn(
        const BlockingState(
          status: BlockingStatus.loaded,
          blockedApps: [],
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<BlockingBloc>.value(
            value: mockBloc,
            child: const BlockingScreen(),
          ),
        ),
      );

      // Act - simulate error state
      when(() => mockBloc.state).thenReturn(
        const BlockingState(
          status: BlockingStatus.error,
          error: 'Network error',
        ),
      );

      await tester.pump();

      // Assert
      expect(find.text('Network error'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}
```

## Integration Testing

### 1. Feature Integration Tests (Score: 8-10)
- **Complete Workflows**: Test end-to-end user flows
- **Data Persistence**: Test data saving and loading
- **Platform Integration**: Test native platform features
- **Network Operations**: Test API calls and caching

**Good Example:**
```dart
// Integration test for complete blocking workflow
void main() {
  group('Blocking Integration Tests', () {
    late IntegrationTestWidgetsFlutterBinding binding;
    
    setUpAll(() {
      binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
    });

    testWidgets('complete blocking session workflow', (tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();

      // Navigate to blocking screen
      await tester.tap(find.byIcon(Icons.block));
      await tester.pumpAndSettle();

      // Add an app to block
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Instagram'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // Verify app appears in blocked list
      expect(find.text('Instagram'), findsOneWidget);
      expect(find.text('com.instagram.android'), findsOneWidget);

      // Toggle blocking on
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // Verify blocking is active
      expect(find.text('Currently blocked'), findsOneWidget);
      expect(find.byIcon(Icons.block), findsOneWidget);

      // Start a focus session
      await tester.tap(find.text('Start Focus Session'));
      await tester.pumpAndSettle();

      // Configure session
      await tester.enterText(find.byType(TextField), 'Work Session');
      await tester.tap(find.text('1 hour'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start Session'));
      await tester.pumpAndSettle();

      // Verify session is active
      expect(find.text('Work Session'), findsOneWidget);
      expect(find.textContaining('59:'), findsOneWidget); // Timer showing
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Try to open blocked app (should be blocked)
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'com.mindfence.blocking',
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('openApp', 'com.instagram.android'),
        ),
        (data) {
          final result = const StandardMethodCodec().decodeEnvelope(data!);
          expect(result, false); // Should be blocked
        },
      );

      // End session
      await tester.tap(find.text('End Session'));
      await tester.pumpAndSettle();

      // Verify session ended
      expect(find.text('Session Complete'), findsOneWidget);
      expect(find.text('Work Session'), findsOneWidget);
      expect(find.textContaining('You focused for'), findsOneWidget);
    });

    testWidgets('offline functionality test', (tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();

      // Simulate offline state
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'connectivity_plus',
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('check', null),
        ),
        (data) {
          const StandardMethodCodec().encodeSuccessEnvelope('none');
        },
      );

      // Navigate to blocking screen
      await tester.tap(find.byIcon(Icons.block));
      await tester.pumpAndSettle();

      // Verify offline functionality still works
      expect(find.text('Offline Mode'), findsOneWidget);
      expect(find.byType(BlockingStatusCard), findsWidgets);

      // Toggle blocking should still work
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      // Verify state change persisted locally
      expect(find.text('Currently blocked'), findsOneWidget);

      // Restore connectivity
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'connectivity_plus',
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('check', null),
        ),
        (data) {
          const StandardMethodCodec().encodeSuccessEnvelope('wifi');
        },
      );

      await tester.pump(const Duration(seconds: 2));

      // Verify sync occurred
      expect(find.text('Synced'), findsOneWidget);
    });
  });
}
```

### 2. Security Testing (Score: 9-10)
- **Bypass Attempts**: Test various bypass scenarios
- **Permission Handling**: Test permission edge cases
- **Data Encryption**: Test encrypted data storage
- **Authentication**: Test security features

**Good Example:**
```dart
// Security-focused integration tests
void main() {
  group('Security Integration Tests', () {
    testWidgets('should prevent bypass through task manager', (tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();

      // Start blocking session
      await _startBlockingSession(tester);

      // Simulate attempt to kill app through task manager
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'com.mindfence.security',
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('simulateTaskKill', 'com.instagram.android'),
        ),
        (data) {},
      );

      await tester.pump(const Duration(seconds: 1));

      // Verify blocking is still active
      expect(find.text('Currently blocked'), findsOneWidget);
      expect(find.text('Bypass attempt detected'), findsOneWidget);
    });

    testWidgets('should handle permission revocation gracefully', (tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();

      // Start blocking session
      await _startBlockingSession(tester);

      // Simulate permission revocation
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'com.mindfence.permissions',
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('revokePermission', 'device_admin'),
        ),
        (data) {},
      );

      await tester.pump(const Duration(seconds: 1));

      // Verify appropriate error handling
      expect(find.text('Permission Required'), findsOneWidget);
      expect(find.text('Device admin permission was revoked'), findsOneWidget);
      expect(find.text('Grant Permission'), findsOneWidget);
    });

    testWidgets('should detect and handle root/jailbreak', (tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();

      // Simulate rooted device
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'com.mindfence.security',
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('simulateRootedDevice', true),
        ),
        (data) {},
      );

      await tester.pump(const Duration(seconds: 1));

      // Verify security warning
      expect(find.text('Security Warning'), findsOneWidget);
      expect(find.text('Device appears to be rooted'), findsOneWidget);
      expect(find.text('Blocking may not be reliable'), findsOneWidget);
    });

    testWidgets('should encrypt sensitive data', (tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();

      // Add sensitive data
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('emergency_contact')), 'john@example.com');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify data is encrypted in storage
      final storage = await SharedPreferences.getInstance();
      final rawData = storage.getString('emergency_contact');
      
      // Data should be encrypted, not plain text
      expect(rawData, isNot(equals('john@example.com')));
      expect(rawData, isNotNull);
      expect(rawData!.length, greaterThan(20)); // Encrypted data is longer
    });
  });
}

Future<void> _startBlockingSession(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.block));
  await tester.pumpAndSettle();

  await tester.tap(find.text('Start Focus Session'));
  await tester.pumpAndSettle();

  await tester.tap(find.text('Start Session'));
  await tester.pumpAndSettle();
}
```

## Golden Testing

### 1. Visual Regression Testing (Score: 7-10)
- **UI Consistency**: Test visual appearance across updates
- **Theme Variations**: Test light and dark themes
- **Screen Sizes**: Test different screen sizes
- **Platform Differences**: Test iOS vs Android appearance

**Good Example:**
```dart
// Golden tests for visual consistency
void main() {
  group('Golden Tests', () {
    testWidgets('BlockingStatusCard golden test - light theme', (tester) async {
      // Arrange
      final app = BlockedApp(
        id: 'app-1',
        name: 'Instagram',
        packageName: 'com.instagram.android',
        isBlocked: true,
        lastBlocked: DateTime(2023, 7, 15, 14, 30),
        totalBlockedTime: const Duration(hours: 2, minutes: 30),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: Center(
              child: BlockingStatusCard(
                app: app,
                onToggle: () {},
                showDetails: true,
              ),
            ),
          ),
        ),
      );

      // Assert
      await expectLater(
        find.byType(BlockingStatusCard),
        matchesGoldenFile('blocking_status_card_light.png'),
      );
    });

    testWidgets('BlockingStatusCard golden test - dark theme', (tester) async {
      // Arrange
      final app = BlockedApp(
        id: 'app-1',
        name: 'Instagram',
        packageName: 'com.instagram.android',
        isBlocked: true,
        lastBlocked: DateTime(2023, 7, 15, 14, 30),
        totalBlockedTime: const Duration(hours: 2, minutes: 30),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: Center(
              child: BlockingStatusCard(
                app: app,
                onToggle: () {},
                showDetails: true,
              ),
            ),
          ),
        ),
      );

      // Assert
      await expectLater(
        find.byType(BlockingStatusCard),
        matchesGoldenFile('blocking_status_card_dark.png'),
      );
    });

    testWidgets('FocusSessionTimer golden test', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: FocusSessionTimer(
                remaining: const Duration(minutes: 45, seconds: 30),
                totalDuration: const Duration(hours: 1),
                isActive: true,
                onStart: () {},
                onStop: () {},
                onPause: () {},
              ),
            ),
          ),
        ),
      );

      // Assert
      await expectLater(
        find.byType(FocusSessionTimer),
        matchesGoldenFile('focus_session_timer_active.png'),
      );
    });
  });
}
```

## Performance Testing

### 1. Performance Benchmarks (Score: 8-10)
- **Rendering Performance**: Test frame rates and rendering time
- **Memory Usage**: Test memory allocation and leaks
- **Battery Impact**: Test battery consumption
- **Network Performance**: Test API response times

**Good Example:**
```dart
// Performance testing
void main() {
  group('Performance Tests', () {
    testWidgets('blocking list should render efficiently with many items', (tester) async {
      // Arrange
      final largeAppList = List.generate(1000, (index) => BlockedApp(
        id: 'app-$index',
        name: 'App $index',
        packageName: 'com.app$index.android',
        isBlocked: index % 2 == 0,
        totalBlockedTime: Duration(hours: index % 10),
      ));

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: largeAppList.length,
              itemBuilder: (context, index) {
                return BlockingStatusCard(
                  app: largeAppList[index],
                  onToggle: () {},
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      stopwatch.stop();

      // Assert
      expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // Should render in < 1 second
      
      // Test scrolling performance
      final scrollStopwatch = Stopwatch()..start();
      await tester.fling(find.byType(ListView), const Offset(0, -500), 1000);
      await tester.pumpAndSettle();
      scrollStopwatch.stop();

      expect(scrollStopwatch.elapsedMilliseconds, lessThan(100)); // Smooth scrolling
    });

    testWidgets('memory usage should remain stable during blocking operations', (tester) async {
      // Arrange
      final memoryTracker = MemoryTracker();
      
      await tester.pumpWidget(
        MaterialApp(
          home: const BlockingScreen(),
        ),
      );

      // Act - perform multiple blocking operations
      for (int i = 0; i < 50; i++) {
        await tester.tap(find.byType(Switch).first);
        await tester.pump();
        
        if (i % 10 == 0) {
          memoryTracker.recordUsage();
        }
      }

      // Assert
      expect(memoryTracker.hasMemoryLeak, false);
      expect(memoryTracker.maxMemoryUsage, lessThan(100 * 1024 * 1024)); // < 100MB
    });
  });
}
```

## Test Organization

### 1. Test File Structure (Score: 8-10)
- **Mirror Structure**: Test files mirror source structure
- **Naming Convention**: Clear, descriptive test file names
- **Helper Functions**: Reusable test utilities
- **Mock Objects**: Centralized mock definitions

**Good Structure:**
```
test/
├── unit/
│   ├── domain/
│   │   ├── entities/
│   │   │   ├── blocked_app_test.dart
│   │   │   └── blocking_session_test.dart
│   │   └── use_cases/
│   │       ├── start_blocking_session_use_case_test.dart
│   │       └── toggle_app_blocking_use_case_test.dart
│   ├── data/
│   │   ├── repositories/
│   │   │   └── blocking_repository_impl_test.dart
│   │   └── data_sources/
│   │       ├── local_data_source_test.dart
│   │       └── remote_data_source_test.dart
│   └── presentation/
│       ├── bloc/
│       │   └── blocking_bloc_test.dart
│       └── widgets/
│           └── blocking_status_card_test.dart
├── widget/
│   ├── screens/
│   │   └── blocking_screen_test.dart
│   └── components/
│       └── focus_session_timer_test.dart
├── integration/
│   ├── blocking_workflow_test.dart
│   └── security_test.dart
├── golden/
│   └── ui_consistency_test.dart
└── helpers/
    ├── test_helpers.dart
    ├── mock_objects.dart
    └── test_data.dart
```

### 2. Test Utilities (Score: 7-10)
- **Helper Functions**: Common test setup and teardown
- **Mock Factories**: Easy mock object creation
- **Test Data**: Realistic test data generators
- **Custom Matchers**: Domain-specific assertions

**Good Example:**
```dart
// test/helpers/test_helpers.dart
class TestHelpers {
  static BlockedApp createTestApp({
    String? id,
    String? name,
    String? packageName,
    bool isBlocked = false,
    DateTime? lastBlocked,
    Duration? totalBlockedTime,
  }) {
    return BlockedApp(
      id: id ?? 'test-app-${DateTime.now().millisecondsSinceEpoch}',
      name: name ?? 'Test App',
      packageName: packageName ?? 'com.test.app',
      isBlocked: isBlocked,
      lastBlocked: lastBlocked,
      totalBlockedTime: totalBlockedTime ?? const Duration(hours: 1),
    );
  }

  static BlockingSession createTestSession({
    String? id,
    String? name,
    List<String>? blockedAppIds,
    DateTime? startTime,
    Duration? duration,
    SessionStatus? status,
  }) {
    return BlockingSession(
      id: id ?? 'test-session-${DateTime.now().millisecondsSinceEpoch}',
      name: name ?? 'Test Session',
      blockedAppIds: blockedAppIds ?? ['com.test.app'],
      startTime: startTime ?? DateTime.now(),
      duration: duration ?? const Duration(hours: 1),
      status: status ?? SessionStatus.active,
    );
  }

  static Widget createTestWidget({
    required Widget child,
    ThemeData? theme,
  }) {
    return MaterialApp(
      theme: theme ?? ThemeData.light(),
      home: Scaffold(body: child),
    );
  }
}

// test/helpers/mock_objects.dart
class MockBlockingRepository extends Mock implements BlockingRepository {}
class MockNotificationService extends Mock implements NotificationService {}
class MockPlatformBlockingService extends Mock implements PlatformBlockingService {}
class MockLogger extends Mock implements Logger {}

// Custom matchers
class IsBlockingSession extends Matcher {
  const IsBlockingSession({
    this.id,
    this.name,
    this.status,
  });

  final String? id;
  final String? name;
  final SessionStatus? status;

  @override
  bool matches(item, Map matchState) {
    if (item is! BlockingSession) return false;
    
    if (id != null && item.id != id) return false;
    if (name != null && item.name != name) return false;
    if (status != null && item.status != status) return false;
    
    return true;
  }

  @override
  Description describe(Description description) {
    return description.add('is a BlockingSession');
  }
}

Matcher isBlockingSession({
  String? id,
  String? name,
  SessionStatus? status,
}) => IsBlockingSession(id: id, name: name, status: status);
```

## Scoring Criteria

### Score 9-10: Excellent
- Comprehensive test coverage (>90%)
- Perfect test pyramid distribution
- Excellent security testing
- Golden tests for UI consistency
- Performance benchmarks
- Complete integration testing

### Score 7-8: Good
- Good test coverage (80-90%)
- Solid test pyramid
- Basic security testing
- Some golden tests
- Basic performance testing
- Good integration coverage

### Score 5-6: Acceptable
- Adequate test coverage (70-80%)
- Basic test structure
- Limited security testing
- Few golden tests
- Limited performance testing
- Some integration tests

### Score 3-4: Below Standard
- Poor test coverage (50-70%)
- Weak test structure
- No security testing
- No golden tests
- No performance testing
- Minimal integration tests

### Score 1-2: Poor
- Very low test coverage (<50%)
- No test organization
- No security considerations
- No UI testing
- No performance testing
- No integration testing

## Common Testing Anti-Patterns to Avoid

1. **Testing Implementation Details**: Test behavior, not implementation
2. **Flaky Tests**: Tests that pass/fail randomly
3. **Slow Tests**: Tests that take too long to run
4. **Unclear Test Names**: Tests with vague or confusing names
5. **No Assertions**: Tests that don't verify anything
6. **Too Many Mocks**: Over-mocking that tests nothing real
7. **Brittle Tests**: Tests that break with minor changes
8. **No Error Testing**: Only testing happy paths
9. **Duplicate Test Logic**: Repeated test setup without helpers
10. **No Security Testing**: Ignoring security test scenarios

Remember: Testing is not just about finding bugs—it's about ensuring that Mind Fence works reliably and securely for users who depend on it to maintain their digital well-being.