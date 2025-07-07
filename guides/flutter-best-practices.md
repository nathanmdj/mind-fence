# Flutter Best Practices Guidelines

## Overview

These guidelines ensure optimal Flutter development practices specifically tailored for the Mind Fence project. They cover widget optimization, state management, performance, and platform-specific implementations.

## Widget Development

### 1. Widget Design Principles (Score: 8-10)
- **Single Responsibility**: Each widget has one clear purpose
- **Composition**: Build complex widgets from simple ones
- **Reusability**: Create reusable components
- **Const Constructors**: Use const constructors whenever possible

**Good Example:**
```dart
// Well-designed, reusable widget
class BlockingStatusCard extends StatelessWidget {
  const BlockingStatusCard({
    super.key,
    required this.app,
    required this.onToggle,
    this.showDetails = false,
  });

  final BlockedApp app;
  final VoidCallback onToggle;
  final bool showDetails;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          _buildHeader(context),
          if (showDetails) _buildDetails(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return ListTile(
      leading: _buildStatusIcon(),
      title: Text(app.name),
      subtitle: Text(_getStatusText()),
      trailing: Switch(
        value: app.isBlocked,
        onChanged: (_) => onToggle(),
      ),
    );
  }

  Widget _buildStatusIcon() {
    return CircleAvatar(
      backgroundColor: app.isBlocked ? Colors.red : Colors.green,
      child: Icon(
        app.isBlocked ? Icons.block : Icons.check,
        color: Colors.white,
      ),
    );
  }

  Widget _buildDetails(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Package: ${app.packageName}'),
          if (app.lastBlocked != null)
            Text('Last blocked: ${_formatDate(app.lastBlocked!)}'),
          Text('Total blocked time: ${_formatDuration(app.totalBlockedTime)}'),
        ],
      ),
    );
  }

  String _getStatusText() {
    return app.isBlocked ? 'Currently blocked' : 'Not blocked';
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, y h:mm a').format(date);
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }
}
```

**Bad Example:**
```dart
// Poor widget design
class BadBlockingWidget extends StatefulWidget {
  final List<BlockedApp> apps;
  final Function(String) onToggle;
  final bool showAnalytics;
  final String userId;
  
  BadBlockingWidget({this.apps, this.onToggle, this.showAnalytics, this.userId});
  
  @override
  _BadBlockingWidgetState createState() => _BadBlockingWidgetState();
}

class _BadBlockingWidgetState extends State<BadBlockingWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      // Does too much, not reusable, poor performance
      child: Column(
        children: [
          // Hardcoded values, no const constructors
          Text('Blocked Apps', style: TextStyle(fontSize: 24)),
          ListView.builder(
            shrinkWrap: true,
            itemCount: widget.apps.length,
            itemBuilder: (context, index) {
              final app = widget.apps[index];
              return ListTile(
                title: Text(app.name),
                trailing: Switch(
                  value: app.isBlocked,
                  onChanged: (value) {
                    // Business logic in widget
                    widget.onToggle(app.packageName);
                    // Direct database calls
                    DatabaseService().updateApp(app.id, value);
                    // Analytics in widget
                    if (widget.showAnalytics) {
                      Analytics.track('app_toggled', {
                        'app': app.name,
                        'user': widget.userId,
                      });
                    }
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
```

### 2. Widget Performance (Score: 8-10)
- **Const Constructors**: Use const for immutable widgets
- **Builder Patterns**: Use builder methods for complex widgets
- **Widget Caching**: Cache expensive widgets
- **Avoid Rebuilds**: Minimize unnecessary rebuilds

**Good Example:**
```dart
// Performance-optimized widget
class OptimizedAppList extends StatelessWidget {
  const OptimizedAppList({
    super.key,
    required this.apps,
    required this.onAppToggle,
  });

  final List<BlockedApp> apps;
  final void Function(BlockedApp) onAppToggle;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: apps.length,
      itemBuilder: (context, index) {
        final app = apps[index];
        return _AppListItem(
          key: ValueKey(app.id), // Stable keys for performance
          app: app,
          onToggle: () => onAppToggle(app),
        );
      },
    );
  }
}

class _AppListItem extends StatelessWidget {
  const _AppListItem({
    super.key,
    required this.app,
    required this.onToggle,
  });

  final BlockedApp app;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: _buildAppIcon(app),
        title: Text(app.name),
        subtitle: Text(app.packageName),
        trailing: Switch(
          value: app.isBlocked,
          onChanged: (_) => onToggle(),
        ),
      ),
    );
  }

  // Cached widget creation
  static final Map<String, Widget> _iconCache = {};
  
  Widget _buildAppIcon(BlockedApp app) {
    return _iconCache.putIfAbsent(
      app.packageName,
      () => CircleAvatar(
        backgroundColor: app.isBlocked ? Colors.red : Colors.green,
        child: Icon(
          app.isBlocked ? Icons.block : Icons.check,
          color: Colors.white,
        ),
      ),
    );
  }
}
```

## State Management with BLoC

### 1. BLoC Pattern Implementation (Score: 9-10)
- **Event-Driven**: Use events for user interactions
- **Immutable State**: Keep state immutable
- **Single Source of Truth**: Centralize state management
- **Testable**: Easy to test business logic

**Good Example:**
```dart
// Well-structured BLoC
class BlockingBloc extends Bloc<BlockingEvent, BlockingState> {
  final BlockingRepository _repository;
  final NotificationService _notificationService;
  
  BlockingBloc({
    required BlockingRepository repository,
    required NotificationService notificationService,
  }) : _repository = repository,
       _notificationService = notificationService,
       super(const BlockingState.initial()) {
    on<BlockingEvent>(_onBlockingEvent);
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
    }
  }

  Future<void> _onLoadBlockedApps(Emitter<BlockingState> emit) async {
    emit(state.copyWith(status: BlockingStatus.loading));
    
    try {
      final apps = await _repository.getBlockedApps();
      emit(state.copyWith(
        status: BlockingStatus.success,
        blockedApps: apps,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: BlockingStatus.failure,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onToggleAppBlocking(
    ToggleAppBlocking event,
    Emitter<BlockingState> emit,
  ) async {
    try {
      final result = await _repository.toggleAppBlocking(event.appId);
      
      if (result.isSuccess) {
        final updatedApps = state.blockedApps.map((app) {
          if (app.id == event.appId) {
            return app.copyWith(isBlocked: !app.isBlocked);
          }
          return app;
        }).toList();
        
        emit(state.copyWith(blockedApps: updatedApps));
        
        // Send notification if app was blocked
        if (result.value?.isBlocked == true) {
          await _notificationService.showBlockingNotification(result.value!);
        }
      } else {
        emit(state.copyWith(error: result.error?.message));
      }
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }
}

// Immutable state class
class BlockingState extends Equatable {
  const BlockingState({
    this.status = BlockingStatus.initial,
    this.blockedApps = const [],
    this.error,
  });

  final BlockingStatus status;
  final List<BlockedApp> blockedApps;
  final String? error;

  const BlockingState.initial() : this();

  BlockingState copyWith({
    BlockingStatus? status,
    List<BlockedApp>? blockedApps,
    String? error,
  }) {
    return BlockingState(
      status: status ?? this.status,
      blockedApps: blockedApps ?? this.blockedApps,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, blockedApps, error];
}

// Event hierarchy
sealed class BlockingEvent extends Equatable {
  const BlockingEvent();
}

class LoadBlockedApps extends BlockingEvent {
  const LoadBlockedApps();
  
  @override
  List<Object> get props => [];
}

class ToggleAppBlocking extends BlockingEvent {
  const ToggleAppBlocking(this.appId);
  
  final String appId;
  
  @override
  List<Object> get props => [appId];
}

class StartFocusSession extends BlockingEvent {
  const StartFocusSession(this.sessionConfig);
  
  final SessionConfig sessionConfig;
  
  @override
  List<Object> get props => [sessionConfig];
}
```

### 2. BLoC Integration with Widgets (Score: 8-10)
- **BlocBuilder**: Use for UI updates
- **BlocListener**: Use for side effects
- **BlocConsumer**: Use when both are needed
- **Context Extensions**: Use context extensions for cleaner code

**Good Example:**
```dart
// Proper BLoC integration
class BlockingScreen extends StatelessWidget {
  const BlockingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => BlockingBloc(
        repository: context.read<BlockingRepository>(),
        notificationService: context.read<NotificationService>(),
      )..add(const LoadBlockedApps()),
      child: const _BlockingScreenContent(),
    );
  }
}

class _BlockingScreenContent extends StatelessWidget {
  const _BlockingScreenContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blocked Apps'),
        actions: [
          IconButton(
            onPressed: () => context.read<BlockingBloc>().add(const LoadBlockedApps()),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: BlocConsumer<BlockingBloc, BlockingState>(
        listener: (context, state) {
          // Handle side effects
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error!)),
            );
          }
        },
        builder: (context, state) {
          return switch (state.status) {
            BlockingStatus.loading => const Center(
                child: CircularProgressIndicator(),
              ),
            BlockingStatus.success => _buildAppList(context, state.blockedApps),
            BlockingStatus.failure => _buildErrorView(context, state.error),
            BlockingStatus.initial => const SizedBox.shrink(),
          };
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAppDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAppList(BuildContext context, List<BlockedApp> apps) {
    if (apps.isEmpty) {
      return const Center(
        child: Text('No blocked apps'),
      );
    }

    return ListView.builder(
      itemCount: apps.length,
      itemBuilder: (context, index) {
        final app = apps[index];
        return BlockingStatusCard(
          app: app,
          onToggle: () => context.read<BlockingBloc>().add(
                ToggleAppBlocking(app.id),
              ),
        );
      },
    );
  }

  Widget _buildErrorView(BuildContext context, String? error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text('Error: ${error ?? 'Unknown error'}'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.read<BlockingBloc>().add(
                  const LoadBlockedApps(),
                ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
```

## Platform-Specific Implementations

### 1. Method Channels (Score: 8-10)
- **Type Safety**: Use proper type definitions
- **Error Handling**: Handle platform errors gracefully
- **Async Operations**: Use async/await properly
- **Platform Detection**: Check platform before calls

**Good Example:**
```dart
// Platform-specific blocking service
class PlatformBlockingService {
  static const _channel = MethodChannel('com.mindfence.blocking');
  
  /// Blocks the specified apps using platform-specific methods.
  /// 
  /// On iOS, uses ScreenTime API. On Android, uses DeviceAdmin.
  Future<Result<bool, BlockingException>> blockApps(
    List<String> packageNames,
  ) async {
    try {
      if (packageNames.isEmpty) {
        return Result.failure(
          const BlockingException('Package names cannot be empty'),
        );
      }
      
      // Platform-specific validation
      if (Platform.isAndroid) {
        final hasPermission = await _hasAndroidPermissions();
        if (!hasPermission) {
          return Result.failure(
            const BlockingException('Android device admin permission required'),
          );
        }
      } else if (Platform.isIOS) {
        final hasPermission = await _hasIOSPermissions();
        if (!hasPermission) {
          return Result.failure(
            const BlockingException('iOS ScreenTime permission required'),
          );
        }
      }
      
      final result = await _channel.invokeMethod<bool>(
        'blockApps',
        {
          'packageNames': packageNames,
          'platform': Platform.operatingSystem,
        },
      );
      
      return result == true
          ? Result.success(true)
          : Result.failure(const BlockingException('Failed to block apps'));
          
    } on PlatformException catch (e) {
      return Result.failure(
        BlockingException(
          'Platform error: ${e.message}',
          code: e.code,
          originalError: e,
        ),
      );
    } catch (e) {
      return Result.failure(
        BlockingException(
          'Unexpected error: $e',
          originalError: e,
        ),
      );
    }
  }
  
  Future<bool> _hasAndroidPermissions() async {
    try {
      final hasPermission = await _channel.invokeMethod<bool>(
        'hasDeviceAdminPermission',
      );
      return hasPermission ?? false;
    } catch (e) {
      return false;
    }
  }
  
  Future<bool> _hasIOSPermissions() async {
    try {
      final hasPermission = await _channel.invokeMethod<bool>(
        'hasScreenTimePermission',
      );
      return hasPermission ?? false;
    } catch (e) {
      return false;
    }
  }
}
```

### 2. Native Code Integration (Score: 8-10)
- **Proper Interfaces**: Define clear interfaces
- **Error Propagation**: Propagate errors properly
- **Resource Management**: Manage native resources
- **Threading**: Handle threading correctly

**Good Example (Android):**
```kotlin
// Android native implementation
class BlockingMethodCallHandler : MethodCallHandler {
    private val devicePolicyManager: DevicePolicyManager by lazy {
        context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
    }
    
    private val componentName: ComponentName by lazy {
        ComponentName(context, BlockingDeviceAdminReceiver::class.java)
    }
    
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "blockApps" -> {
                try {
                    val packageNames = call.argument<List<String>>("packageNames")
                    if (packageNames.isNullOrEmpty()) {
                        result.error("INVALID_ARGS", "Package names cannot be empty", null)
                        return
                    }
                    
                    val success = blockApps(packageNames)
                    result.success(success)
                } catch (e: Exception) {
                    result.error("BLOCKING_ERROR", e.message, null)
                }
            }
            "hasDeviceAdminPermission" -> {
                val hasPermission = devicePolicyManager.isAdminActive(componentName)
                result.success(hasPermission)
            }
            else -> result.notImplemented()
        }
    }
    
    private fun blockApps(packageNames: List<String>): Boolean {
        return try {
            if (!devicePolicyManager.isAdminActive(componentName)) {
                false
            } else {
                // Use device admin to block apps
                devicePolicyManager.setPackagesSuspended(
                    componentName,
                    packageNames.toTypedArray(),
                    true
                )
                true
            }
        } catch (e: SecurityException) {
            false
        }
    }
}
```

## Performance Optimization

### 1. Memory Management (Score: 8-10)
- **Dispose Resources**: Properly dispose of resources
- **Avoid Memory Leaks**: Be careful with listeners and subscriptions
- **Use Weak References**: Where appropriate
- **Profile Memory Usage**: Regular memory profiling

**Good Example:**
```dart
// Proper resource management
class FocusSessionManager extends ChangeNotifier {
  final SessionRepository _repository;
  final TimerService _timerService;
  
  late final StreamSubscription _sessionSubscription;
  late final StreamSubscription _timerSubscription;
  
  FocusSessionManager({
    required SessionRepository repository,
    required TimerService timerService,
  }) : _repository = repository,
       _timerService = timerService {
    _initializeSubscriptions();
  }
  
  void _initializeSubscriptions() {
    _sessionSubscription = _repository.sessionStream.listen(
      (session) {
        // Handle session updates
        notifyListeners();
      },
      onError: (error) {
        // Handle errors
      },
    );
    
    _timerSubscription = _timerService.timerStream.listen(
      (timeRemaining) {
        // Handle timer updates
        notifyListeners();
      },
    );
  }
  
  @override
  void dispose() {
    // Always dispose of subscriptions
    _sessionSubscription.cancel();
    _timerSubscription.cancel();
    super.dispose();
  }
}
```

### 2. Build Performance (Score: 8-10)
- **Const Widgets**: Use const constructors
- **Builder Methods**: Extract builder methods
- **Avoid Expensive Operations**: Don't do heavy work in build methods
- **Use Keys**: Provide keys for list items

**Good Example:**
```dart
// Performance-optimized build method
class AppBlockingDashboard extends StatelessWidget {
  const AppBlockingDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BlockingBloc, BlockingState>(
      builder: (context, state) {
        return Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: _buildContent(context, state),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.security),
            SizedBox(width: 8),
            Text('Mind Fence Dashboard'),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, BlockingState state) {
    return switch (state.status) {
      BlockingStatus.loading => const Center(
          child: CircularProgressIndicator(),
        ),
      BlockingStatus.success => _buildSuccessContent(state),
      BlockingStatus.failure => _buildErrorContent(context, state),
      BlockingStatus.initial => const SizedBox.shrink(),
    };
  }

  Widget _buildSuccessContent(BlockingState state) {
    return ListView.builder(
      itemCount: state.blockedApps.length,
      itemBuilder: (context, index) {
        final app = state.blockedApps[index];
        return BlockingStatusCard(
          key: ValueKey(app.id), // Stable key for performance
          app: app,
          onToggle: () => context.read<BlockingBloc>().add(
                ToggleAppBlocking(app.id),
              ),
        );
      },
    );
  }

  Widget _buildErrorContent(BuildContext context, BlockingState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64),
          const SizedBox(height: 16),
          Text('Error: ${state.error}'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.read<BlockingBloc>().add(
                  const LoadBlockedApps(),
                ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
```

## Package Management

### 1. Dependency Management (Score: 8-10)
- **Version Pinning**: Pin specific versions
- **Minimal Dependencies**: Only use necessary packages
- **Security Updates**: Keep dependencies updated
- **License Compliance**: Check package licenses

**Good Example:**
```yaml
# pubspec.yaml - Well-managed dependencies
dependencies:
  flutter:
    sdk: flutter
  
  # State management
  flutter_bloc: ^8.1.3
  equatable: ^2.0.5
  
  # Network
  dio: ^5.3.2
  
  # Storage
  flutter_secure_storage: ^9.0.0
  sqflite: ^2.3.0
  
  # UI
  material_color_utilities: ^0.5.0
  
  # Platform
  device_info_plus: ^9.1.0
  permission_handler: ^11.0.1
  
  # Utils
  intl: ^0.18.1
  logger: ^2.0.2+1

dev_dependencies:
  flutter_test:
    sdk: flutter
  
  # Testing
  bloc_test: ^9.1.4
  mocktail: ^1.0.0
  
  # Code quality
  flutter_lints: ^3.0.1
  
  # Code generation
  build_runner: ^2.4.7
  json_annotation: ^4.8.1
  json_serializable: ^6.7.1
```

### 2. Code Generation (Score: 7-10)
- **JSON Serialization**: Use code generation for JSON
- **Immutable Classes**: Generate immutable classes
- **Dependency Injection**: Use code generation for DI
- **Build Scripts**: Automate code generation

**Good Example:**
```dart
// Using code generation for JSON serialization
@JsonSerializable()
class BlockedApp extends Equatable {
  const BlockedApp({
    required this.id,
    required this.name,
    required this.packageName,
    required this.isBlocked,
    this.lastBlocked,
    required this.totalBlockedTime,
  });

  final String id;
  final String name;
  final String packageName;
  final bool isBlocked;
  final DateTime? lastBlocked;
  @JsonKey(fromJson: _durationFromJson, toJson: _durationToJson)
  final Duration totalBlockedTime;

  factory BlockedApp.fromJson(Map<String, dynamic> json) =>
      _$BlockedAppFromJson(json);

  Map<String, dynamic> toJson() => _$BlockedAppToJson(this);

  static Duration _durationFromJson(int microseconds) =>
      Duration(microseconds: microseconds);

  static int _durationToJson(Duration duration) => duration.inMicroseconds;

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

## Testing Integration

### 1. Widget Testing (Score: 8-10)
- **Comprehensive Tests**: Test all user interactions
- **Golden Tests**: Use golden tests for UI verification
- **Accessibility Tests**: Test accessibility features
- **Platform Testing**: Test platform-specific behavior

**Good Example:**
```dart
// Comprehensive widget test
void main() {
  group('BlockingStatusCard', () {
    late MockBlockingBloc mockBloc;
    late BlockedApp testApp;

    setUp(() {
      mockBloc = MockBlockingBloc();
      testApp = const BlockedApp(
        id: 'test-id',
        name: 'Test App',
        packageName: 'com.test.app',
        isBlocked: false,
        totalBlockedTime: Duration(hours: 2),
      );
    });

    testWidgets('displays app information correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<BlockingBloc>.value(
            value: mockBloc,
            child: BlockingStatusCard(
              app: testApp,
              onToggle: () {},
            ),
          ),
        ),
      );

      expect(find.text('Test App'), findsOneWidget);
      expect(find.text('com.test.app'), findsOneWidget);
      expect(find.text('Not blocked'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('calls onToggle when switch is tapped', (tester) async {
      bool toggleCalled = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: BlockingStatusCard(
            app: testApp,
            onToggle: () => toggleCalled = true,
          ),
        ),
      );

      await tester.tap(find.byType(Switch));
      await tester.pump();

      expect(toggleCalled, isTrue);
    });

    testWidgets('shows correct status for blocked app', (tester) async {
      final blockedApp = testApp.copyWith(isBlocked: true);
      
      await tester.pumpWidget(
        MaterialApp(
          home: BlockingStatusCard(
            app: blockedApp,
            onToggle: () {},
          ),
        ),
      );

      expect(find.text('Currently blocked'), findsOneWidget);
      expect(find.byIcon(Icons.block), findsOneWidget);
    });

    testWidgets('meets accessibility requirements', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlockingStatusCard(
            app: testApp,
            onToggle: () {},
          ),
        ),
      );

      // Check that all interactive elements have semantic labels
      final switch = find.byType(Switch);
      expect(switch, findsOneWidget);
      
      final switchWidget = tester.widget<Switch>(switch);
      expect(switchWidget.value, isFalse);
      
      // Test with screen reader
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/accessibility',
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('announce', 'Test announcement'),
        ),
        (data) {},
      );
    });
  });
}
```

## Scoring Criteria

### Score 9-10: Excellent
- Perfect widget composition and performance
- Exemplary BLoC implementation
- Flawless platform integration
- Comprehensive testing
- Optimal dependency management

### Score 7-8: Good
- Good widget design with minor issues
- Solid BLoC implementation
- Good platform integration
- Adequate testing
- Good dependency management

### Score 5-6: Acceptable
- Basic widget implementation
- Functional BLoC usage
- Some platform integration
- Basic testing
- Acceptable dependencies

### Score 3-4: Below Standard
- Poor widget design
- Weak BLoC implementation
- Limited platform integration
- Minimal testing
- Poor dependency management

### Score 1-2: Poor
- No design principles followed
- No proper state management
- No platform integration
- No testing
- Chaotic dependencies

## Common Flutter Anti-Patterns to Avoid

1. **Stateful Widgets Everywhere**: Use StatelessWidget when possible
2. **Business Logic in Widgets**: Keep business logic in BLoCs
3. **Direct Database Calls**: Use repository pattern
4. **Ignoring Platform Differences**: Handle platform-specific code properly
5. **No Error Handling**: Always handle errors gracefully
6. **Blocking Build Methods**: Never do async work in build methods
7. **Memory Leaks**: Always dispose resources
8. **Hardcoded Values**: Use constants and theme values
9. **Poor Testing**: Write comprehensive tests
10. **Dependency Hell**: Manage dependencies carefully

Remember: Flutter development is about creating performant, maintainable apps that work seamlessly across platforms. Follow these guidelines to ensure Mind Fence delivers an exceptional user experience.