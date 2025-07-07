# Performance Guidelines

## Overview

Performance is critical for Mind Fence since it runs continuously in the background to monitor and block apps. Poor performance can drain battery, consume excessive memory, and impact user experience. These guidelines ensure optimal performance across all devices and usage scenarios.

## Memory Management

### 1. Memory Optimization (Score: 8-10)
- **Dispose Resources**: Properly dispose of streams, controllers, and listeners
- **Avoid Memory Leaks**: Use weak references and proper cleanup
- **Efficient Data Structures**: Choose appropriate data structures
- **Memory Profiling**: Regular memory usage analysis

**Good Example:**
```dart
// Proper resource management
class BlockingSessionManager extends ChangeNotifier {
  final SessionRepository _repository;
  final TimerService _timerService;
  final PlatformBlockingService _platformService;
  
  StreamSubscription<SessionStatus>? _sessionSubscription;
  StreamSubscription<Duration>? _timerSubscription;
  Timer? _periodicChecksTimer;
  
  BlockingSessionManager({
    required SessionRepository repository,
    required TimerService timerService,
    required PlatformBlockingService platformService,
  }) : _repository = repository,
       _timerService = timerService,
       _platformService = platformService {
    _initializeSubscriptions();
  }

  void _initializeSubscriptions() {
    _sessionSubscription = _repository.sessionStatusStream.listen(
      _handleSessionStatusChange,
      onError: _handleSessionError,
    );
    
    _timerSubscription = _timerService.timerStream.listen(
      _handleTimerUpdate,
      onError: _handleTimerError,
    );
    
    // Periodic checks for bypass attempts
    _periodicChecksTimer = Timer.periodic(
      const Duration(seconds: 30),
      _performSecurityChecks,
    );
  }

  void _handleSessionStatusChange(SessionStatus status) {
    // Handle session status changes
    notifyListeners();
  }

  void _handleTimerUpdate(Duration remaining) {
    // Handle timer updates
    notifyListeners();
  }

  void _performSecurityChecks(Timer timer) {
    // Check for bypass attempts
    _platformService.verifyBlockingIntegrity();
  }

  @override
  void dispose() {
    // Critical: Always dispose of resources
    _sessionSubscription?.cancel();
    _timerSubscription?.cancel();
    _periodicChecksTimer?.cancel();
    super.dispose();
  }
}
```

**Bad Example:**
```dart
// Memory leak example - DON'T DO THIS
class BadSessionManager extends ChangeNotifier {
  final SessionRepository _repository;
  List<BlockingSession> _sessions = [];
  
  BadSessionManager({required SessionRepository repository}) 
      : _repository = repository {
    // Never disposed subscription - MEMORY LEAK
    _repository.sessionStatusStream.listen((status) {
      // Memory leak: continuously growing list
      _sessions.add(BlockingSession(
        id: DateTime.now().toString(),
        name: 'Session',
        blockedAppIds: [],
        startTime: DateTime.now(),
        duration: const Duration(hours: 1),
        status: SessionStatus.active,
      ));
      notifyListeners();
    });
  }
  
  // Missing dispose method - MEMORY LEAK
  // Resources are never cleaned up
}
```

### 2. Object Pooling (Score: 7-10)
- **Reuse Objects**: Pool frequently created objects
- **Reduce Allocations**: Minimize object creation in hot paths
- **Efficient Collections**: Use appropriate collection types
- **Weak References**: Use weak references for caches

**Good Example:**
```dart
// Object pooling for frequently used objects
class BlockingEventPool {
  static final BlockingEventPool _instance = BlockingEventPool._internal();
  factory BlockingEventPool() => _instance;
  BlockingEventPool._internal();
  
  final Queue<ToggleAppBlockingEvent> _toggleEventPool = Queue();
  final Queue<SessionStatusUpdateEvent> _statusUpdatePool = Queue();
  
  ToggleAppBlockingEvent getToggleEvent(String appId) {
    if (_toggleEventPool.isNotEmpty) {
      final event = _toggleEventPool.removeFirst();
      return event._reset(appId);
    }
    return ToggleAppBlockingEvent(appId);
  }
  
  void releaseToggleEvent(ToggleAppBlockingEvent event) {
    if (_toggleEventPool.length < 10) { // Limit pool size
      _toggleEventPool.add(event);
    }
  }
  
  SessionStatusUpdateEvent getStatusUpdateEvent(String sessionId, SessionStatus status) {
    if (_statusUpdatePool.isNotEmpty) {
      final event = _statusUpdatePool.removeFirst();
      return event._reset(sessionId, status);
    }
    return SessionStatusUpdateEvent(sessionId, status);
  }
  
  void releaseStatusUpdateEvent(SessionStatusUpdateEvent event) {
    if (_statusUpdatePool.length < 10) {
      _statusUpdatePool.add(event);
    }
  }
}

// Reusable event with reset capability
class ToggleAppBlockingEvent extends BlockingEvent {
  String _appId;
  
  ToggleAppBlockingEvent(this._appId);
  
  String get appId => _appId;
  
  ToggleAppBlockingEvent _reset(String appId) {
    _appId = appId;
    return this;
  }
  
  @override
  List<Object> get props => [_appId];
}
```

## Network Performance

### 1. Efficient API Calls (Score: 8-10)
- **Request Batching**: Batch multiple requests
- **Caching Strategy**: Implement intelligent caching
- **Compression**: Use response compression
- **Connection Pooling**: Reuse HTTP connections

**Good Example:**
```dart
// Efficient API client with caching and batching
class OptimizedApiClient {
  final Dio _dio;
  final Map<String, CacheEntry> _cache = {};
  final List<ApiRequest> _pendingRequests = [];
  Timer? _batchTimer;
  
  OptimizedApiClient({required Dio dio}) : _dio = dio {
    _configureClient();
  }

  void _configureClient() {
    // Enable compression
    _dio.options.headers['Accept-Encoding'] = 'gzip, deflate';
    
    // Connection pooling
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
    
    // Add caching interceptor
    _dio.interceptors.add(CacheInterceptor());
  }

  Future<Result<T, NetworkException>> get<T>(
    String endpoint, {
    Duration? cacheTimeout,
    bool forceRefresh = false,
  }) async {
    final cacheKey = _getCacheKey(endpoint);
    
    // Check cache first
    if (!forceRefresh && _cache.containsKey(cacheKey)) {
      final entry = _cache[cacheKey]!;
      if (!entry.isExpired) {
        return Result.success(entry.data as T);
      }
    }
    
    try {
      final response = await _dio.get<T>(endpoint);
      
      // Cache the response
      if (cacheTimeout != null) {
        _cache[cacheKey] = CacheEntry(
          data: response.data,
          expiresAt: DateTime.now().add(cacheTimeout),
        );
      }
      
      return Result.success(response.data as T);
    } on DioException catch (e) {
      return Result.failure(NetworkException(e.message ?? 'Network error'));
    }
  }

  Future<Result<List<T>, NetworkException>> batchGet<T>(
    List<String> endpoints, {
    Duration? cacheTimeout,
  }) async {
    final futures = endpoints.map((endpoint) => get<T>(
      endpoint,
      cacheTimeout: cacheTimeout,
    ));
    
    final results = await Future.wait(futures);
    
    final data = <T>[];
    for (final result in results) {
      if (result.isSuccess) {
        data.add(result.value!);
      } else {
        return Result.failure(result.error!);
      }
    }
    
    return Result.success(data);
  }

  // Batch POST requests for better performance
  void queueRequest(ApiRequest request) {
    _pendingRequests.add(request);
    
    // Start batch timer if not already running
    _batchTimer ??= Timer(const Duration(milliseconds: 100), _processBatch);
  }

  void _processBatch() {
    if (_pendingRequests.isEmpty) return;
    
    final batch = List<ApiRequest>.from(_pendingRequests);
    _pendingRequests.clear();
    _batchTimer = null;
    
    _sendBatchRequest(batch);
  }

  Future<void> _sendBatchRequest(List<ApiRequest> requests) async {
    try {
      final response = await _dio.post('/batch', data: {
        'requests': requests.map((r) => r.toJson()).toList(),
      });
      
      final results = response.data['results'] as List;
      
      for (int i = 0; i < results.length; i++) {
        final request = requests[i];
        final result = results[i];
        
        if (result['success']) {
          request.completer.complete(Result.success(result['data']));
        } else {
          request.completer.complete(Result.failure(
            NetworkException(result['error']),
          ));
        }
      }
    } catch (e) {
      // Complete all requests with error
      for (final request in requests) {
        request.completer.complete(Result.failure(
          NetworkException('Batch request failed: $e'),
        ));
      }
    }
  }

  String _getCacheKey(String endpoint) => 'cache_$endpoint';
}

class CacheEntry {
  final dynamic data;
  final DateTime expiresAt;
  
  CacheEntry({required this.data, required this.expiresAt});
  
  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
```

### 2. Background Sync (Score: 8-10)
- **Intelligent Scheduling**: Schedule sync based on usage patterns
- **Differential Sync**: Only sync changed data
- **Conflict Resolution**: Handle sync conflicts gracefully
- **Retry Logic**: Implement exponential backoff

**Good Example:**
```dart
// Intelligent background sync service
class BackgroundSyncService {
  final ApiClient _apiClient;
  final LocalStorage _localStorage;
  final NetworkInfo _networkInfo;
  
  Timer? _syncTimer;
  final List<SyncTask> _pendingTasks = [];
  bool _isSyncing = false;
  
  BackgroundSyncService({
    required ApiClient apiClient,
    required LocalStorage localStorage,
    required NetworkInfo networkInfo,
  }) : _apiClient = apiClient,
       _localStorage = localStorage,
       _networkInfo = networkInfo {
    _initializeSync();
  }

  void _initializeSync() {
    // Schedule periodic sync
    _syncTimer = Timer.periodic(
      const Duration(minutes: 5),
      _performSync,
    );
    
    // Listen for network changes
    _networkInfo.onConnectivityChanged.listen(_handleConnectivityChange);
  }

  void _handleConnectivityChange(ConnectivityResult result) {
    if (result != ConnectivityResult.none && _pendingTasks.isNotEmpty) {
      // Network available, attempt sync
      _performSync(null);
    }
  }

  void queueSyncTask(SyncTask task) {
    _pendingTasks.add(task);
    
    // Immediate sync for high priority tasks
    if (task.priority == SyncPriority.high) {
      _performSync(null);
    }
  }

  Future<void> _performSync(Timer? timer) async {
    if (_isSyncing || _pendingTasks.isEmpty) return;
    
    if (!await _networkInfo.isConnected) {
      // No network, skip sync
      return;
    }
    
    _isSyncing = true;
    
    try {
      // Sort tasks by priority and timestamp
      _pendingTasks.sort((a, b) {
        if (a.priority.index != b.priority.index) {
          return a.priority.index.compareTo(b.priority.index);
        }
        return a.timestamp.compareTo(b.timestamp);
      });
      
      // Process tasks in batches
      const batchSize = 10;
      for (int i = 0; i < _pendingTasks.length; i += batchSize) {
        final batch = _pendingTasks.skip(i).take(batchSize).toList();
        
        await _processSyncBatch(batch);
        
        // Remove completed tasks
        _pendingTasks.removeWhere((task) => task.isCompleted);
      }
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _processSyncBatch(List<SyncTask> batch) async {
    final futures = batch.map(_processSyncTask);
    await Future.wait(futures);
  }

  Future<void> _processSyncTask(SyncTask task) async {
    try {
      switch (task.type) {
        case SyncType.blockingStateUpdate:
          await _syncBlockingState(task);
          break;
        case SyncType.sessionData:
          await _syncSessionData(task);
          break;
        case SyncType.analyticsData:
          await _syncAnalyticsData(task);
          break;
      }
      
      task.markCompleted();
    } catch (e) {
      task.incrementRetryCount();
      
      if (task.retryCount >= 3) {
        // Too many failures, mark as failed
        task.markFailed();
      } else {
        // Exponential backoff
        final delay = Duration(seconds: math.pow(2, task.retryCount).toInt());
        Timer(delay, () => _processSyncTask(task));
      }
    }
  }

  Future<void> _syncBlockingState(SyncTask task) async {
    final localData = await _localStorage.getPendingBlockingUpdates();
    
    if (localData.isEmpty) {
      task.markCompleted();
      return;
    }
    
    // Send differential update
    final result = await _apiClient.post('/sync/blocking', data: {
      'updates': localData.map((update) => update.toJson()).toList(),
      'lastSyncTimestamp': await _localStorage.getLastSyncTimestamp(),
    });
    
    if (result.isSuccess) {
      await _localStorage.clearPendingBlockingUpdates();
      await _localStorage.setLastSyncTimestamp(DateTime.now());
      
      // Apply any server-side changes
      final serverUpdates = result.value['updates'] as List?;
      if (serverUpdates != null) {
        await _applyServerUpdates(serverUpdates);
      }
    } else {
      throw Exception('Sync failed: ${result.error}');
    }
  }

  void dispose() {
    _syncTimer?.cancel();
  }
}

enum SyncPriority { high, medium, low }
enum SyncType { blockingStateUpdate, sessionData, analyticsData }

class SyncTask {
  final String id;
  final SyncType type;
  final SyncPriority priority;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  
  int retryCount = 0;
  bool isCompleted = false;
  bool isFailed = false;
  
  SyncTask({
    required this.id,
    required this.type,
    required this.priority,
    required this.data,
    required this.timestamp,
  });
  
  void markCompleted() => isCompleted = true;
  void markFailed() => isFailed = true;
  void incrementRetryCount() => retryCount++;
}
```

## UI Performance

### 1. Efficient Rendering (Score: 8-10)
- **Const Constructors**: Use const for immutable widgets
- **Builder Patterns**: Use builder widgets for expensive operations
- **Lazy Loading**: Load content on demand
- **Efficient Lists**: Use ListView.builder for large lists

**Good Example:**
```dart
// Efficient list rendering with pagination
class OptimizedBlockingList extends StatefulWidget {
  const OptimizedBlockingList({
    super.key,
    required this.onAppToggle,
  });

  final void Function(BlockedApp) onAppToggle;

  @override
  State<OptimizedBlockingList> createState() => _OptimizedBlockingListState();
}

class _OptimizedBlockingListState extends State<OptimizedBlockingList> {
  final ScrollController _scrollController = ScrollController();
  final List<BlockedApp> _apps = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;
  
  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _scrollController.addListener(_handleScroll);
  }

  void _handleScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMoreData();
    }
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await context.read<BlockingRepository>().getBlockedApps(
        page: 0,
        limit: 20,
      );
      
      if (result.isSuccess) {
        setState(() {
          _apps.addAll(result.value!);
          _currentPage = 0;
          _hasMore = result.value!.length == 20;
        });
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoading || !_hasMore) return;
    
    setState(() => _isLoading = true);
    
    try {
      final result = await context.read<BlockingRepository>().getBlockedApps(
        page: _currentPage + 1,
        limit: 20,
      );
      
      if (result.isSuccess) {
        setState(() {
          _apps.addAll(result.value!);
          _currentPage++;
          _hasMore = result.value!.length == 20;
        });
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: _apps.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _apps.length) {
          // Loading indicator
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        final app = _apps[index];
        return _OptimizedAppItem(
          key: ValueKey(app.id), // Stable key for performance
          app: app,
          onToggle: () => widget.onAppToggle(app),
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

// Optimized individual item widget
class _OptimizedAppItem extends StatelessWidget {
  const _OptimizedAppItem({
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
        leading: _buildAppIcon(),
        title: Text(app.name),
        subtitle: Text(app.packageName),
        trailing: Switch(
          value: app.isBlocked,
          onChanged: (_) => onToggle(),
        ),
      ),
    );
  }

  Widget _buildAppIcon() {
    return CircleAvatar(
      backgroundColor: app.isBlocked ? Colors.red : Colors.green,
      child: Icon(
        app.isBlocked ? Icons.block : Icons.check,
        color: Colors.white,
      ),
    );
  }
}
```

### 2. Animation Performance (Score: 7-10)
- **60 FPS Target**: Maintain smooth 60 FPS animations
- **Efficient Transitions**: Use efficient animation curves
- **Reduced Motion**: Respect accessibility preferences
- **Animation Caching**: Cache complex animations

**Good Example:**
```dart
// Optimized animation implementation
class OptimizedBlockingAnimation extends StatefulWidget {
  const OptimizedBlockingAnimation({
    super.key,
    required this.isBlocked,
    required this.child,
  });

  final bool isBlocked;
  final Widget child;

  @override
  State<OptimizedBlockingAnimation> createState() => _OptimizedBlockingAnimationState();
}

class _OptimizedBlockingAnimationState extends State<OptimizedBlockingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    // Use efficient easing curve
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(curve);
    
    _colorAnimation = ColorTween(
      begin: Colors.green,
      end: Colors.red,
    ).animate(curve);
    
    if (widget.isBlocked) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(OptimizedBlockingAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.isBlocked != widget.isBlocked) {
      if (widget.isBlocked) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check for reduced motion preference
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    
    if (reduceMotion) {
      // Skip animations for accessibility
      return Container(
        decoration: BoxDecoration(
          color: widget.isBlocked ? Colors.red : Colors.green,
        ),
        child: widget.child,
      );
    }
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              color: _colorAnimation.value,
            ),
            child: widget.child,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

## Battery Optimization

### 1. Background Processing (Score: 9-10)
- **Minimize Background Work**: Reduce background processing
- **Efficient Scheduling**: Use smart scheduling for background tasks
- **Doze Mode Handling**: Handle Android Doze mode correctly
- **iOS Background Modes**: Proper iOS background execution

**Good Example:**
```dart
// Battery-efficient background service
class EfficientBackgroundService {
  static const _backgroundTaskId = 'mind_fence_background';
  
  Timer? _monitoringTimer;
  bool _isInBackground = false;
  DateTime? _lastBackgroundTime;
  
  void startBackgroundMonitoring() {
    // Register background task
    _registerBackgroundTask();
    
    // Use adaptive timing based on usage patterns
    final interval = _calculateOptimalInterval();
    
    _monitoringTimer = Timer.periodic(interval, _performBackgroundCheck);
  }
  
  Duration _calculateOptimalInterval() {
    // Adaptive interval based on user behavior
    final lastActivity = UserActivityTracker.getLastActivity();
    final timeSinceActivity = DateTime.now().difference(lastActivity);
    
    if (timeSinceActivity.inMinutes < 10) {
      // User recently active, check more frequently
      return const Duration(seconds: 30);
    } else if (timeSinceActivity.inHours < 1) {
      // User somewhat active, moderate checking
      return const Duration(minutes: 2);
    } else {
      // User inactive, minimal checking
      return const Duration(minutes: 5);
    }
  }

  void _registerBackgroundTask() {
    BackgroundTaskManager.register(_backgroundTaskId, () async {
      // Critical: Keep background work minimal
      await _performEssentialChecks();
    });
  }

  Future<void> _performBackgroundCheck(Timer timer) async {
    try {
      // Only do essential work in background
      if (_isInBackground) {
        await _performEssentialChecks();
      } else {
        await _performFullCheck();
      }
    } catch (e) {
      // Log error but don't crash
      Logger.error('Background check failed: $e');
    }
  }

  Future<void> _performEssentialChecks() async {
    // Minimal battery-efficient checks
    final blockedApps = await LocalStorage.getActiveBlockedApps();
    
    for (final app in blockedApps) {
      final isRunning = await PlatformChannel.isAppRunning(app.packageName);
      
      if (isRunning) {
        // App is running when it should be blocked
        await PlatformChannel.forceCloseApp(app.packageName);
        
        // Log bypass attempt
        AnalyticsService.logBypassAttempt(app.packageName);
      }
    }
  }

  Future<void> _performFullCheck() async {
    // More comprehensive checks when app is in foreground
    await _performEssentialChecks();
    
    // Update usage statistics
    await UsageStatsService.updateStats();
    
    // Sync data if needed
    await BackgroundSyncService.syncIfNeeded();
  }

  void onAppStateChange(AppState state) {
    _isInBackground = state == AppState.background;
    
    if (_isInBackground) {
      _lastBackgroundTime = DateTime.now();
      
      // Reduce monitoring frequency in background
      _monitoringTimer?.cancel();
      _monitoringTimer = Timer.periodic(
        const Duration(minutes: 5),
        _performBackgroundCheck,
      );
    } else {
      // Resume normal monitoring frequency
      _monitoringTimer?.cancel();
      _monitoringTimer = Timer.periodic(
        const Duration(seconds: 30),
        _performBackgroundCheck,
      );
    }
  }

  void dispose() {
    _monitoringTimer?.cancel();
    BackgroundTaskManager.unregister(_backgroundTaskId);
  }
}
```

### 2. CPU Optimization (Score: 8-10)
- **Efficient Algorithms**: Use optimal algorithms and data structures
- **Lazy Evaluation**: Compute values only when needed
- **Caching**: Cache expensive computations
- **Asynchronous Processing**: Use async/await for I/O operations

**Good Example:**
```dart
// CPU-efficient app usage tracking
class OptimizedUsageTracker {
  final Map<String, UsageData> _usageCache = {};
  final Map<String, DateTime> _lastChecked = {};
  
  Timer? _trackingTimer;
  
  void startTracking() {
    // Use efficient interval
    _trackingTimer = Timer.periodic(
      const Duration(seconds: 10),
      _updateUsageData,
    );
  }

  Future<void> _updateUsageData(Timer timer) async {
    final now = DateTime.now();
    
    // Get list of apps to track
    final trackedApps = await _getTrackedApps();
    
    // Process apps in batches to avoid blocking UI
    const batchSize = 5;
    for (int i = 0; i < trackedApps.length; i += batchSize) {
      final batch = trackedApps.skip(i).take(batchSize);
      
      await Future.wait(
        batch.map((app) => _updateAppUsage(app, now)),
      );
      
      // Yield control to prevent blocking
      await Future.delayed(const Duration(milliseconds: 1));
    }
  }

  Future<void> _updateAppUsage(String packageName, DateTime now) async {
    final lastCheck = _lastChecked[packageName] ?? now;
    
    // Skip if checked recently (within 5 seconds)
    if (now.difference(lastCheck).inSeconds < 5) {
      return;
    }
    
    try {
      // Efficient usage data retrieval
      final usageData = await _getUsageDataEfficiently(packageName);
      
      if (usageData != null) {
        _usageCache[packageName] = usageData;
        _lastChecked[packageName] = now;
      }
    } catch (e) {
      // Log error but continue processing other apps
      Logger.warning('Failed to update usage for $packageName: $e');
    }
  }

  Future<UsageData?> _getUsageDataEfficiently(String packageName) async {
    // Use cached data if available and recent
    final cached = _usageCache[packageName];
    if (cached != null && _isCacheValid(cached)) {
      return cached;
    }
    
    // Fetch from system efficiently
    final usage = await PlatformChannel.getAppUsage(packageName);
    
    if (usage != null) {
      return UsageData(
        packageName: packageName,
        lastUsed: usage.lastUsed,
        totalTime: usage.totalTime,
        isCurrentlyActive: usage.isActive,
        timestamp: DateTime.now(),
      );
    }
    
    return null;
  }

  bool _isCacheValid(UsageData data) {
    const cacheTimeout = Duration(minutes: 1);
    return DateTime.now().difference(data.timestamp) < cacheTimeout;
  }

  Future<List<String>> _getTrackedApps() async {
    // Cache tracked apps list
    static List<String>? _cachedTrackedApps;
    static DateTime? _lastCacheUpdate;
    
    const cacheTimeout = Duration(minutes: 5);
    
    if (_cachedTrackedApps != null && 
        _lastCacheUpdate != null &&
        DateTime.now().difference(_lastCacheUpdate!) < cacheTimeout) {
      return _cachedTrackedApps!;
    }
    
    // Fetch from database efficiently
    final apps = await DatabaseService.getTrackedApps();
    
    _cachedTrackedApps = apps;
    _lastCacheUpdate = DateTime.now();
    
    return apps;
  }

  void dispose() {
    _trackingTimer?.cancel();
    _usageCache.clear();
    _lastChecked.clear();
  }
}

class UsageData {
  final String packageName;
  final DateTime lastUsed;
  final Duration totalTime;
  final bool isCurrentlyActive;
  final DateTime timestamp;
  
  const UsageData({
    required this.packageName,
    required this.lastUsed,
    required this.totalTime,
    required this.isCurrentlyActive,
    required this.timestamp,
  });
}
```

## Storage Performance

### 1. Database Optimization (Score: 8-10)
- **Efficient Queries**: Use proper indexing and query optimization
- **Batch Operations**: Batch database operations
- **Connection Pooling**: Manage database connections efficiently
- **Data Compression**: Compress large data before storage

**Good Example:**
```dart
// Optimized database operations
class OptimizedDatabase {
  static Database? _database;
  static final Map<String, PreparedStatement> _preparedStatements = {};
  
  static Future<Database> get database async {
    if (_database != null) return _database!;
    
    _database = await _initializeDatabase();
    return _database!;
  }
  
  static Future<Database> _initializeDatabase() async {
    final path = await getDatabasesPath();
    final dbPath = join(path, 'mind_fence.db');
    
    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: _createDatabase,
      onOpen: _configureDatabase,
    );
  }
  
  static Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE blocked_apps (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        package_name TEXT NOT NULL,
        is_blocked INTEGER NOT NULL DEFAULT 0,
        last_blocked INTEGER,
        total_blocked_time INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    
    // Create indexes for performance
    await db.execute('CREATE INDEX idx_blocked_apps_package_name ON blocked_apps(package_name)');
    await db.execute('CREATE INDEX idx_blocked_apps_is_blocked ON blocked_apps(is_blocked)');
    await db.execute('CREATE INDEX idx_blocked_apps_updated_at ON blocked_apps(updated_at)');
  }
  
  static Future<void> _configureDatabase(Database db) async {
    // Enable WAL mode for better performance
    await db.execute('PRAGMA journal_mode=WAL');
    
    // Optimize SQLite settings
    await db.execute('PRAGMA synchronous=NORMAL');
    await db.execute('PRAGMA cache_size=10000');
    await db.execute('PRAGMA temp_store=MEMORY');
  }

  // Efficient batch insert
  static Future<void> insertBlockedApps(List<BlockedApp> apps) async {
    final db = await database;
    
    final batch = db.batch();
    
    for (final app in apps) {
      batch.insert(
        'blocked_apps',
        {
          'id': app.id,
          'name': app.name,
          'package_name': app.packageName,
          'is_blocked': app.isBlocked ? 1 : 0,
          'last_blocked': app.lastBlocked?.millisecondsSinceEpoch,
          'total_blocked_time': app.totalBlockedTime.inMilliseconds,
          'created_at': DateTime.now().millisecondsSinceEpoch,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit(noResult: true);
  }

  // Efficient query with pagination
  static Future<List<BlockedApp>> getBlockedApps({
    int? limit,
    int? offset,
    bool? isBlocked,
  }) async {
    final db = await database;
    
    final whereClause = isBlocked != null ? 'WHERE is_blocked = ?' : '';
    final whereArgs = isBlocked != null ? [isBlocked ? 1 : 0] : <dynamic>[];
    
    final limitClause = limit != null ? 'LIMIT $limit' : '';
    final offsetClause = offset != null ? 'OFFSET $offset' : '';
    
    final query = '''
      SELECT * FROM blocked_apps 
      $whereClause 
      ORDER BY updated_at DESC 
      $limitClause $offsetClause
    ''';
    
    final results = await db.rawQuery(query, whereArgs);
    
    return results.map((row) => BlockedApp(
      id: row['id'] as String,
      name: row['name'] as String,
      packageName: row['package_name'] as String,
      isBlocked: (row['is_blocked'] as int) == 1,
      lastBlocked: row['last_blocked'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(row['last_blocked'] as int)
          : null,
      totalBlockedTime: Duration(milliseconds: row['total_blocked_time'] as int),
    )).toList();
  }

  // Prepared statement for frequent operations
  static Future<void> updateBlockingState(String appId, bool isBlocked) async {
    final db = await database;
    
    // Use prepared statement for better performance
    const statementKey = 'update_blocking_state';
    
    if (!_preparedStatements.containsKey(statementKey)) {
      _preparedStatements[statementKey] = await db.prepare('''
        UPDATE blocked_apps 
        SET is_blocked = ?, updated_at = ? 
        WHERE id = ?
      ''');
    }
    
    final statement = _preparedStatements[statementKey]!;
    await statement.execute([
      isBlocked ? 1 : 0,
      DateTime.now().millisecondsSinceEpoch,
      appId,
    ]);
  }

  // Efficient cleanup of old data
  static Future<void> cleanupOldData() async {
    final db = await database;
    
    // Delete sessions older than 30 days
    final cutoffTime = DateTime.now().subtract(const Duration(days: 30));
    
    await db.delete(
      'blocking_sessions',
      where: 'created_at < ?',
      whereArgs: [cutoffTime.millisecondsSinceEpoch],
    );
    
    // Vacuum database to reclaim space
    await db.execute('VACUUM');
  }

  static Future<void> dispose() async {
    for (final statement in _preparedStatements.values) {
      await statement.dispose();
    }
    _preparedStatements.clear();
    
    await _database?.close();
    _database = null;
  }
}
```

## Performance Monitoring

### 1. Real-time Monitoring (Score: 8-10)
- **Performance Metrics**: Track key performance indicators
- **Memory Usage**: Monitor memory consumption
- **Battery Impact**: Track battery usage
- **Network Usage**: Monitor network consumption

**Good Example:**
```dart
// Performance monitoring service
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  final Map<String, PerformanceMetric> _metrics = {};
  Timer? _monitoringTimer;
  
  void startMonitoring() {
    _monitoringTimer = Timer.periodic(
      const Duration(seconds: 30),
      _collectMetrics,
    );
  }

  Future<void> _collectMetrics(Timer timer) async {
    await Future.wait([
      _collectMemoryMetrics(),
      _collectCPUMetrics(),
      _collectNetworkMetrics(),
      _collectBatteryMetrics(),
    ]);
  }

  Future<void> _collectMemoryMetrics() async {
    final memoryInfo = await DeviceInfoService.getMemoryInfo();
    
    _metrics['memory_usage'] = PerformanceMetric(
      name: 'memory_usage',
      value: memoryInfo.usedMemory.toDouble(),
      unit: 'bytes',
      timestamp: DateTime.now(),
    );
    
    _metrics['memory_peak'] = PerformanceMetric(
      name: 'memory_peak',
      value: memoryInfo.peakMemory.toDouble(),
      unit: 'bytes',
      timestamp: DateTime.now(),
    );
  }

  Future<void> _collectCPUMetrics() async {
    final cpuInfo = await DeviceInfoService.getCPUInfo();
    
    _metrics['cpu_usage'] = PerformanceMetric(
      name: 'cpu_usage',
      value: cpuInfo.usagePercentage,
      unit: 'percentage',
      timestamp: DateTime.now(),
    );
  }

  Future<void> _collectNetworkMetrics() async {
    final networkInfo = await DeviceInfoService.getNetworkInfo();
    
    _metrics['network_bytes_sent'] = PerformanceMetric(
      name: 'network_bytes_sent',
      value: networkInfo.bytesSent.toDouble(),
      unit: 'bytes',
      timestamp: DateTime.now(),
    );
    
    _metrics['network_bytes_received'] = PerformanceMetric(
      name: 'network_bytes_received',
      value: networkInfo.bytesReceived.toDouble(),
      unit: 'bytes',
      timestamp: DateTime.now(),
    );
  }

  Future<void> _collectBatteryMetrics() async {
    final batteryInfo = await DeviceInfoService.getBatteryInfo();
    
    _metrics['battery_level'] = PerformanceMetric(
      name: 'battery_level',
      value: batteryInfo.level.toDouble(),
      unit: 'percentage',
      timestamp: DateTime.now(),
    );
  }

  void trackOperation(String operationName, Duration duration) {
    final metric = PerformanceMetric(
      name: 'operation_$operationName',
      value: duration.inMilliseconds.toDouble(),
      unit: 'milliseconds',
      timestamp: DateTime.now(),
    );
    
    _metrics[metric.name] = metric;
    
    // Alert for slow operations
    if (duration.inMilliseconds > 1000) {
      _alertSlowOperation(operationName, duration);
    }
  }

  void _alertSlowOperation(String operationName, Duration duration) {
    Logger.warning(
      'Slow operation detected: $operationName took ${duration.inMilliseconds}ms',
    );
    
    // Send performance alert to analytics
    AnalyticsService.trackPerformanceIssue(
      operationName,
      duration.inMilliseconds,
    );
  }

  Map<String, PerformanceMetric> getMetrics() {
    return Map.unmodifiable(_metrics);
  }

  void dispose() {
    _monitoringTimer?.cancel();
    _metrics.clear();
  }
}

class PerformanceMetric {
  final String name;
  final double value;
  final String unit;
  final DateTime timestamp;
  
  const PerformanceMetric({
    required this.name,
    required this.value,
    required this.unit,
    required this.timestamp,
  });
  
  Map<String, dynamic> toJson() => {
    'name': name,
    'value': value,
    'unit': unit,
    'timestamp': timestamp.toIso8601String(),
  };
}
```

## Scoring Criteria

### Score 9-10: Excellent
- Perfect memory management with no leaks
- Highly efficient network operations
- 60 FPS UI performance consistently
- Optimal battery usage
- Comprehensive performance monitoring

### Score 7-8: Good
- Good memory management with minor issues
- Efficient network operations
- Generally smooth UI performance
- Good battery optimization
- Basic performance monitoring

### Score 5-6: Acceptable
- Adequate memory management
- Some network optimization
- Acceptable UI performance
- Basic battery considerations
- Limited performance monitoring

### Score 3-4: Below Standard
- Poor memory management
- Inefficient network operations
- Poor UI performance
- High battery consumption
- No performance monitoring

### Score 1-2: Poor
- Memory leaks present
- No network optimization
- Very poor UI performance
- Excessive battery usage
- No performance considerations

## Common Performance Anti-Patterns to Avoid

1. **Memory Leaks**: Not disposing of resources properly
2. **Synchronous I/O**: Blocking operations on main thread
3. **Excessive Rebuilds**: Rebuilding widgets unnecessarily
4. **Inefficient Queries**: Poor database query optimization
5. **Frequent Allocations**: Creating objects in hot paths
6. **Blocking Animations**: Heavy operations during animations
7. **Unbounded Caches**: Caches that grow without limits
8. **Excessive Background Work**: Too much processing in background
9. **Inefficient Algorithms**: Using suboptimal algorithms
10. **No Performance Monitoring**: Not tracking performance metrics

Remember: Performance optimization is an ongoing process. Mind Fence must maintain excellent performance while providing comprehensive app blocking functionality. Users depend on the app running efficiently in the background without impacting their device's performance or battery life.