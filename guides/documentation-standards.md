# Documentation Standards

## Overview

Comprehensive documentation is essential for the Mind Fence project's maintainability, onboarding, and long-term success. These standards ensure consistent, clear, and useful documentation across all aspects of the project.

## Code Documentation

### 1. API Documentation (Score: 9-10)
- **Complete Coverage**: All public APIs documented
- **Parameter Documentation**: Every parameter explained
- **Return Value Documentation**: Return types and meanings documented
- **Exception Documentation**: All possible exceptions listed
- **Usage Examples**: Practical examples provided

**Good Example:**
```dart
/// Service responsible for managing app blocking functionality.
/// 
/// This service coordinates between the platform-specific blocking mechanisms
/// and the Flutter application layer. It provides high-level blocking operations
/// while handling platform differences transparently.
/// 
/// Example usage:
/// ```dart
/// final blockingService = AppBlockingService(
///   repository: repository,
///   platformService: platformService,
/// );
/// 
/// // Block specific apps
/// final result = await blockingService.blockApps(['com.instagram.android']);
/// if (result.isSuccess) {
///   print('Apps blocked successfully');
/// }
/// ```
class AppBlockingService {
  /// Creates a new [AppBlockingService] instance.
  /// 
  /// [repository] is used for persisting blocking state
  /// [platformService] handles platform-specific blocking operations
  /// [logger] is used for logging operations (optional)
  AppBlockingService({
    required BlockingRepository repository,
    required PlatformBlockingService platformService,
    Logger? logger,
  }) : _repository = repository,
       _platformService = platformService,
       _logger = logger ?? Logger('AppBlockingService');

  final BlockingRepository _repository;
  final PlatformBlockingService _platformService;
  final Logger _logger;

  /// Blocks the specified apps immediately.
  /// 
  /// This method performs the following operations:
  /// 1. Validates that blocking permissions are available
  /// 2. Updates the blocking state in the repository
  /// 3. Sends blocking commands to the platform service
  /// 4. Verifies that blocking was successful
  /// 
  /// [packageNames] - List of app package names to block. Must not be empty.
  /// [reason] - Optional reason for blocking (used for analytics)
  /// 
  /// Returns a [Result] containing:
  /// - Success: [BlockingResult] with details about blocked apps
  /// - Failure: [BlockingException] with error details
  /// 
  /// Throws:
  /// - [ArgumentError] if [packageNames] is empty
  /// - [StateError] if the service is not properly initialized
  /// 
  /// Example:
  /// ```dart
  /// final result = await blockingService.blockApps([
  ///   'com.instagram.android',
  ///   'com.twitter.android',
  /// ], reason: 'Focus session started');
  /// 
  /// result.when(
  ///   success: (blockingResult) {
  ///     print('Blocked ${blockingResult.blockedCount} apps');
  ///   },
  ///   failure: (error) {
  ///     print('Failed to block apps: ${error.message}');
  ///   },
  /// );
  /// ```
  Future<Result<BlockingResult, BlockingException>> blockApps(
    List<String> packageNames, {
    String? reason,
  }) async {
    if (packageNames.isEmpty) {
      throw ArgumentError('Package names list cannot be empty');
    }

    _logger.info('Attempting to block ${packageNames.length} apps: $packageNames');

    try {
      // Validate permissions
      final hasPermissions = await _validateBlockingPermissions();
      if (!hasPermissions) {
        return Result.failure(
          const PermissionException('Insufficient permissions for app blocking'),
        );
      }

      // Update repository state
      final repositoryResult = await _repository.updateBlockingStates(
        packageNames,
        isBlocked: true,
        reason: reason,
      );

      if (repositoryResult.isFailure) {
        _logger.error('Failed to update repository: ${repositoryResult.error}');
        return Result.failure(
          BlockingException('Failed to update blocking state: ${repositoryResult.error}'),
        );
      }

      // Execute platform blocking
      final platformResult = await _platformService.blockApps(packageNames);
      if (platformResult.isFailure) {
        _logger.error('Platform blocking failed: ${platformResult.error}');
        
        // Rollback repository changes
        await _repository.updateBlockingStates(
          packageNames,
          isBlocked: false,
          reason: 'Rollback due to platform failure',
        );

        return Result.failure(
          BlockingException('Platform blocking failed: ${platformResult.error}'),
        );
      }

      // Create success result
      final blockingResult = BlockingResult(
        blockedApps: packageNames,
        timestamp: DateTime.now(),
        reason: reason,
        blockedCount: packageNames.length,
      );

      _logger.info('Successfully blocked ${packageNames.length} apps');
      return Result.success(blockingResult);

    } catch (e, stackTrace) {
      _logger.error('Unexpected error during blocking', error: e, stackTrace: stackTrace);
      return Result.failure(
        BlockingException('Unexpected error: $e'),
      );
    }
  }

  /// Checks if the device has the necessary permissions for app blocking.
  /// 
  /// This method verifies platform-specific permissions:
  /// - Android: Device Admin or Accessibility Service permissions
  /// - iOS: Screen Time API permissions
  /// 
  /// Returns `true` if all required permissions are granted, `false` otherwise.
  /// 
  /// This is a lightweight check that doesn't require any parameters.
  /// For permission request operations, use [requestBlockingPermissions].
  Future<bool> hasBlockingPermissions() async {
    try {
      return await _platformService.hasRequiredPermissions();
    } catch (e) {
      _logger.warning('Error checking permissions: $e');
      return false;
    }
  }

  /// Requests the necessary permissions for app blocking.
  /// 
  /// This method will show platform-specific permission dialogs to the user.
  /// The exact permissions requested depend on the platform:
  /// 
  /// **Android:**
  /// - Device Admin permissions (for system-level app blocking)
  /// - Accessibility Service permissions (for monitoring app launches)
  /// - Usage Stats permissions (for app usage tracking)
  /// 
  /// **iOS:**
  /// - Screen Time API permissions (for app blocking)
  /// - Family Controls authorization (for content restrictions)
  /// 
  /// [showRationale] - Whether to show permission rationale to the user first
  /// 
  /// Returns a [Result] containing:
  /// - Success: [PermissionResult] with granted permissions
  /// - Failure: [PermissionException] if permissions were denied
  /// 
  /// Example:
  /// ```dart
  /// final result = await blockingService.requestBlockingPermissions(
  ///   showRationale: true,
  /// );
  /// 
  /// if (result.isSuccess) {
  ///   print('All permissions granted');
  /// } else {
  ///   print('Permission denied: ${result.error?.message}');
  /// }
  /// ```
  Future<Result<PermissionResult, PermissionException>> requestBlockingPermissions({
    bool showRationale = true,
  }) async {
    // Implementation details...
  }

  /// Validates that all required permissions are available.
  /// 
  /// This is an internal method used by other operations to ensure
  /// that blocking can be performed successfully.
  Future<bool> _validateBlockingPermissions() async {
    return await hasBlockingPermissions();
  }
}

/// Result of a blocking operation.
/// 
/// Contains information about which apps were blocked and when.
class BlockingResult {
  /// Creates a new [BlockingResult].
  const BlockingResult({
    required this.blockedApps,
    required this.timestamp,
    required this.blockedCount,
    this.reason,
  });

  /// List of package names that were successfully blocked.
  final List<String> blockedApps;

  /// When the blocking operation was performed.
  final DateTime timestamp;

  /// Optional reason for the blocking operation.
  final String? reason;

  /// Number of apps that were blocked.
  final int blockedCount;

  @override
  String toString() => 'BlockingResult(blockedCount: $blockedCount, timestamp: $timestamp)';
}
```

### 2. Inline Comments (Score: 8-10)
- **Explain Why, Not What**: Focus on reasoning and context
- **Complex Logic**: Document complex algorithms and business rules
- **Edge Cases**: Explain handling of edge cases
- **TODO Comments**: Structured TODO comments with context

**Good Example:**
```dart
class SecurityBypassDetector {
  /// Checks for potential bypass attempts using multiple detection methods.
  /// 
  /// This method implements a multi-layered approach to detect bypass attempts:
  /// 1. Process monitoring - checks if blocked apps are running
  /// 2. Network traffic analysis - monitors for suspicious network activity  
  /// 3. System integrity checks - verifies our blocking mechanisms are intact
  /// 4. Behavioral analysis - detects unusual user behavior patterns
  Future<BypassDetectionResult> detectBypassAttempts() async {
    final detectionResults = <DetectionMethod, bool>{};
    
    // Process monitoring: Check if any blocked apps are currently running
    // This is our primary detection method as it's the most reliable indicator
    // of a successful bypass attempt
    final runningBlockedApps = await _checkRunningBlockedApps();
    detectionResults[DetectionMethod.processMonitoring] = runningBlockedApps.isNotEmpty;
    
    // Network traffic analysis: Look for connections to known social media domains
    // This catches cases where users might access social media through browsers
    // or alternative apps that weren't explicitly blocked
    final suspiciousConnections = await _analyzeNetworkTraffic();
    detectionResults[DetectionMethod.networkAnalysis] = suspiciousConnections.isNotEmpty;
    
    // System integrity: Verify our blocking mechanisms haven't been tampered with
    // This includes checking if our device admin permissions are still active,
    // our accessibility service is running, and our app hasn't been modified
    final integrityViolations = await _checkSystemIntegrity();
    detectionResults[DetectionMethod.integrityCheck] = integrityViolations.isNotEmpty;
    
    // Behavioral analysis: Look for patterns that suggest bypass attempts
    // For example: rapid app switching, unusually long idle periods followed
    // by sudden activity, or attempts to access settings repeatedly
    final behavioralAnomalies = await _analyzeBehavioralPatterns();
    detectionResults[DetectionMethod.behavioralAnalysis] = behavioralAnomalies.isNotEmpty;
    
    // Calculate confidence score based on multiple detection methods
    // We use weighted scoring because some methods are more reliable than others
    final confidenceScore = _calculateConfidenceScore(detectionResults);
    
    // TODO(security): Implement machine learning-based detection
    // We should train a model on bypass attempt patterns to improve detection accuracy
    // Priority: High - Current rule-based system may miss sophisticated attempts
    // Assigned: Security team
    // Deadline: Next sprint
    
    // TODO(performance): Optimize network traffic analysis
    // Current implementation scans all network connections which may impact performance
    // Consider implementing a more targeted approach that only monitors specific domains
    // Priority: Medium - Only impacts devices with high network activity
    
    return BypassDetectionResult(
      detectionMethods: detectionResults,
      confidenceScore: confidenceScore,
      suspiciousApps: runningBlockedApps,
      suspiciousConnections: suspiciousConnections,
      integrityViolations: integrityViolations,
      behavioralAnomalies: behavioralAnomalies,
      timestamp: DateTime.now(),
    );
  }
  
  /// Calculates confidence score for bypass detection.
  /// 
  /// We use a weighted scoring system because different detection methods
  /// have different reliability levels:
  /// - Process monitoring: 40% weight (most reliable)
  /// - Network analysis: 25% weight (fairly reliable but can have false positives)
  /// - Integrity checks: 25% weight (reliable but rare)
  /// - Behavioral analysis: 10% weight (experimental, high false positive rate)
  double _calculateConfidenceScore(Map<DetectionMethod, bool> results) {
    const weights = {
      DetectionMethod.processMonitoring: 0.4,
      DetectionMethod.networkAnalysis: 0.25,
      DetectionMethod.integrityCheck: 0.25,
      DetectionMethod.behavioralAnalysis: 0.1,
    };
    
    double score = 0.0;
    for (final entry in results.entries) {
      if (entry.value) { // Detection method triggered
        score += weights[entry.key] ?? 0.0;
      }
    }
    
    // Ensure score is between 0.0 and 1.0
    return score.clamp(0.0, 1.0);
  }
}
```

## User Documentation

### 1. User Guides (Score: 8-10)
- **Step-by-Step Instructions**: Clear, numbered steps
- **Screenshots**: Visual aids for complex procedures
- **Common Scenarios**: Cover typical use cases
- **Troubleshooting**: Address common issues

**Good Example:**
```markdown
# Mind Fence User Guide

## Getting Started with Mind Fence

### Setting Up Your First Blocking Session

Mind Fence helps you stay focused by blocking distracting apps during important work or study periods. Follow these steps to set up your first blocking session:

#### Step 1: Grant Required Permissions

1. **Open Mind Fence** on your device
2. Tap **"Get Started"** on the welcome screen
3. You'll see a permission request screen with the following options:

   **On Android:**
   - **Device Administrator**: Required to block apps at the system level
   - **Accessibility Service**: Needed to monitor app launches
   - **Usage Statistics**: Allows tracking of your app usage patterns

   **On iOS:**
   - **Screen Time**: Required to access iOS app blocking features
   - **Family Controls**: Needed for content restrictions

4. **Tap "Grant Permissions"** and follow the system prompts
5. **Important**: Don't worry if you see security warnings - this is normal for apps that manage other apps

#### Step 2: Add Apps to Block

1. From the main screen, tap the **"+"** button in the bottom right
2. You'll see a list of installed apps on your device
3. **Select the apps you want to block** by tapping the checkbox next to each app:
   - Social media apps (Instagram, Twitter, TikTok)
   - Gaming apps
   - Entertainment apps (YouTube, Netflix)
   - Any other distracting apps

4. **Tap "Add Selected Apps"** when you're done

💡 **Tip**: Start with just 2-3 apps for your first session. You can always add more later.

#### Step 3: Create a Focus Session

1. From the main screen, tap **"Start Focus Session"**
2. **Enter a session name** (e.g., "Work Time", "Study Session")
3. **Set the duration**:
   - Use the slider to select time (15 minutes to 8 hours)
   - For beginners, try starting with 25-30 minutes

4. **Select which apps to block** for this session
5. **Tap "Start Session"**

#### Step 4: During Your Focus Session

When your session is active:

- ✅ **Blocked apps will be closed** if you try to open them
- ✅ **You'll see a timer** showing time remaining
- ✅ **You can pause the session** if needed (tap the pause button)
- ✅ **Emergency override** is available (hold the stop button for 5 seconds)

⚠️ **Important**: Emergency override should only be used for genuine emergencies, as it defeats the purpose of the blocking session.

#### Step 5: Completing Your Session

When your session ends:

- 🎉 **You'll see a completion screen** with your focus statistics
- 📊 **Your progress is automatically saved** to your history
- 🏆 **You may unlock achievements** for consistent focus sessions

### Common Use Cases

#### For Students
```
Session Name: "Study Time"
Duration: 50 minutes (with 10-minute breaks)
Blocked Apps: Instagram, TikTok, YouTube, Twitter
Best Time: During homework or exam preparation
```

#### For Remote Workers
```
Session Name: "Deep Work"
Duration: 2 hours
Blocked Apps: Social media, news apps, gaming apps
Best Time: Morning focus blocks or important project work
```

#### For Better Sleep
```
Session Name: "Wind Down"
Duration: 1 hour before bedtime
Blocked Apps: All social media, news, stimulating games
Best Time: Evening routine (9 PM - 10 PM)
```

### Troubleshooting Common Issues

#### "App blocking isn't working"

**Solution 1: Check Permissions**
1. Go to **Settings > Permissions** in Mind Fence
2. Verify all required permissions are enabled
3. If any are disabled, tap **"Re-grant Permissions"**

**Solution 2: Restart the App**
1. Close Mind Fence completely
2. Wait 10 seconds
3. Reopen the app
4. Try starting a new session

**Solution 3: Device Restart**
- Sometimes a device restart is needed after granting permissions
- This is especially common on Android devices

#### "I can't end my session early"

This is by design! Mind Fence is meant to help you resist the urge to check distracting apps. However:

- **For genuine emergencies**: Hold the stop button for 5 seconds
- **For bathroom breaks**: Use the pause button (max 15 minutes)
- **If you must stop**: The emergency override will be available after 5 minutes

#### "The app is draining my battery"

Mind Fence is optimized for battery efficiency, but you can:

1. **Reduce monitoring frequency**:
   - Go to **Settings > Advanced > Monitoring**
   - Change from "High" to "Medium" precision

2. **Limit background activity**:
   - Only use blocking when actively needed
   - Don't leave long sessions running overnight

#### "I accidentally blocked an important app"

**Quick Fix:**
1. Go to **Settings > Blocked Apps**
2. Find the app in your list
3. Tap the **toggle switch** to unblock it
4. The change takes effect immediately

**For Active Sessions:**
1. Pause your current session
2. Go to **Session Settings**
3. Remove the app from the current session
4. Resume your session

### Advanced Features

#### Scheduling Sessions
Set up automatic blocking sessions:

1. Go to **Settings > Schedules**
2. Tap **"Add Schedule"**
3. Choose days, times, and apps
4. Sessions will start automatically

#### Location-Based Blocking
Block apps only in certain locations:

1. Go to **Settings > Location Blocking**
2. Add locations (work, library, etc.)
3. Select apps to block at each location

#### Analytics and Insights
Track your focus progress:

1. Go to **Analytics** tab
2. View your focus time trends
3. See which apps you try to access most
4. Get weekly and monthly reports

### Getting Help

If you need additional support:

- **In-App Help**: Tap the **"?"** icon in any screen
- **FAQ**: Visit Settings > Help > Frequently Asked Questions
- **Contact Support**: Settings > Help > Contact Us
- **Video Tutorials**: Settings > Help > Video Guides

Remember: Building better digital habits takes time. Be patient with yourself and celebrate small wins!
```

### 2. Technical Documentation (Score: 8-10)
- **Architecture Overview**: High-level system design
- **API Reference**: Complete API documentation
- **Setup Instructions**: Development environment setup
- **Deployment Guide**: Deployment procedures

**Good Example:**
```markdown
# Mind Fence Technical Documentation

## Architecture Overview

Mind Fence follows Clean Architecture principles with a layered approach designed for maintainability, testability, and scalability.

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                       │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │
│  │   Widgets   │  │    BLoCs    │  │   Platform Channels │ │
│  └─────────────┘  └─────────────┘  └─────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                     Domain Layer                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │
│  │  Entities   │  │ Use Cases   │  │   Repository Interfaces │
│  └─────────────┘  └─────────────┘  └─────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                      Data Layer                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │
│  │ Repositories│  │Data Sources │  │   External APIs     │ │
│  └─────────────┘  └─────────────┘  └─────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### Core Components

#### 1. Blocking Engine
The blocking engine is the heart of Mind Fence, responsible for:

- **Platform Integration**: Interfaces with iOS Screen Time and Android Device Admin APIs
- **Process Monitoring**: Continuously monitors for blocked app launches
- **Bypass Detection**: Detects and prevents bypass attempts
- **Session Management**: Manages focus session lifecycle

**Key Classes:**
- `AppBlockingService`: Main service coordinating blocking operations
- `PlatformBlockingService`: Platform-specific blocking implementation
- `SessionManager`: Manages focus session lifecycle
- `BypassDetector`: Detects and prevents bypass attempts

#### 2. Data Persistence
Mind Fence uses a hybrid approach for data storage:

- **Local Storage**: SQLite database for offline functionality
- **Secure Storage**: Flutter Secure Storage for sensitive data
- **Cloud Sync**: Firebase for cross-device synchronization

**Database Schema:**
```sql
-- Core tables
CREATE TABLE blocked_apps (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    package_name TEXT UNIQUE NOT NULL,
    is_blocked BOOLEAN DEFAULT FALSE,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);

CREATE TABLE focus_sessions (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    start_time INTEGER NOT NULL,
    end_time INTEGER,
    duration_minutes INTEGER NOT NULL,
    status TEXT NOT NULL, -- 'active', 'completed', 'cancelled'
    created_at INTEGER NOT NULL
);

CREATE TABLE session_blocked_apps (
    session_id TEXT NOT NULL,
    app_id TEXT NOT NULL,
    PRIMARY KEY (session_id, app_id),
    FOREIGN KEY (session_id) REFERENCES focus_sessions(id),
    FOREIGN KEY (app_id) REFERENCES blocked_apps(id)
);

-- Analytics tables
CREATE TABLE app_usage_events (
    id TEXT PRIMARY KEY,
    app_id TEXT NOT NULL,
    event_type TEXT NOT NULL, -- 'opened', 'blocked', 'closed'
    timestamp INTEGER NOT NULL,
    session_id TEXT,
    FOREIGN KEY (app_id) REFERENCES blocked_apps(id),
    FOREIGN KEY (session_id) REFERENCES focus_sessions(id)
);

-- Indexes for performance
CREATE INDEX idx_blocked_apps_package_name ON blocked_apps(package_name);
CREATE INDEX idx_focus_sessions_status ON focus_sessions(status);
CREATE INDEX idx_app_usage_events_timestamp ON app_usage_events(timestamp);
```

#### 3. State Management
Mind Fence uses BLoC pattern for state management:

**BLoC Hierarchy:**
```
AppBloc (Global app state)
├── BlockingBloc (App blocking state)
├── SessionBloc (Focus session state)
├── AnalyticsBloc (Usage analytics state)
└── SettingsBloc (User settings state)
```

**Event Flow:**
```
UI Event → BLoC → Use Case → Repository → Data Source
                    ↓
UI Update ← BLoC ← Result ← Repository ← Data Source
```

### Platform-Specific Implementation

#### Android Implementation

**Required Permissions:**
```xml
<uses-permission android:name="android.permission.DEVICE_ADMIN" />
<uses-permission android:name="android.permission.PACKAGE_USAGE_STATS" />
<uses-permission android:name="android.permission.BIND_ACCESSIBILITY_SERVICE" />
```

**Device Admin Receiver:**
```kotlin
class BlockingDeviceAdminReceiver : DeviceAdminReceiver() {
    override fun onEnabled(context: Context, intent: Intent) {
        super.onEnabled(context, intent)
        // Device admin enabled
    }
    
    override fun onDisabled(context: Context, intent: Intent) {
        super.onDisabled(context, intent)
        // Handle device admin disabled
    }
}
```

**App Blocking Method:**
```kotlin
class AndroidBlockingService {
    fun blockApps(packageNames: List<String>): Boolean {
        return try {
            // Method 1: Package suspension (requires device admin)
            devicePolicyManager.setPackagesSuspended(
                adminComponent,
                packageNames.toTypedArray(),
                true
            )
            true
        } catch (e: SecurityException) {
            // Fallback to accessibility service method
            blockViaAccessibilityService(packageNames)
        }
    }
}
```

#### iOS Implementation

**Required Capabilities:**
```xml
<key>com.apple.developer.family-controls</key>
<true/>
<key>com.apple.developer.screen-time</key>
<true/>
```

**Screen Time Integration:**
```swift
import FamilyControls
import ManagedSettings

class IOSBlockingService {
    private let managedSettingsStore = ManagedSettingsStore()
    
    func blockApps(bundleIdentifiers: [String]) async -> Bool {
        do {
            let tokens = Set(bundleIdentifiers.compactMap { 
                Application(bundleIdentifier: $0)?.token 
            })
            
            managedSettingsStore.shield.applications = tokens
            return true
        } catch {
            print("Failed to block apps: \(error)")
            return false
        }
    }
}
```

### API Reference

#### Core Services

##### AppBlockingService

```dart
class AppBlockingService {
  /// Blocks the specified apps
  Future<Result<BlockingResult, BlockingException>> blockApps(
    List<String> packageNames, {
    String? reason,
  });
  
  /// Unblocks the specified apps
  Future<Result<UnblockingResult, BlockingException>> unblockApps(
    List<String> packageNames,
  );
  
  /// Checks if apps are currently blocked
  Future<Map<String, bool>> getBlockingStatus(List<String> packageNames);
  
  /// Stream of blocking state changes
  Stream<BlockingStateChange> get blockingStateStream;
}
```

##### SessionManager

```dart
class SessionManager {
  /// Starts a new focus session
  Future<Result<FocusSession, SessionException>> startSession(
    SessionConfig config,
  );
  
  /// Stops the current active session
  Future<Result<SessionResult, SessionException>> stopSession();
  
  /// Pauses the current session
  Future<Result<void, SessionException>> pauseSession();
  
  /// Resumes a paused session
  Future<Result<void, SessionException>> resumeSession();
  
  /// Gets the current active session
  FocusSession? get currentSession;
  
  /// Stream of session state changes
  Stream<SessionStateChange> get sessionStateStream;
}
```

### Development Setup

#### Prerequisites

- Flutter SDK 3.16.0 or higher
- Dart SDK 3.2.0 or higher
- Android Studio or VS Code
- Xcode (for iOS development)
- Git

#### Environment Setup

1. **Clone the Repository**
   ```bash
   git clone https://github.com/mind-fence/mind-fence-app.git
   cd mind-fence-app
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Environment Variables**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

4. **Generate Code**
   ```bash
   flutter packages pub run build_runner build
   ```

5. **Run Tests**
   ```bash
   flutter test
   ```

6. **Run the App**
   ```bash
   flutter run
   ```

#### Project Structure

```
lib/
├── core/                    # Core utilities and constants
│   ├── constants/          # App constants
│   ├── errors/            # Error classes
│   ├── network/           # Network utilities
│   └── utils/             # General utilities
├── features/              # Feature modules
│   ├── blocking/          # App blocking feature
│   │   ├── data/         # Data layer
│   │   ├── domain/       # Domain layer
│   │   └── presentation/ # Presentation layer
│   ├── analytics/        # Usage analytics
│   ├── settings/         # App settings
│   └── onboarding/       # User onboarding
└── main.dart             # App entry point
```

### Deployment

#### Android Deployment

1. **Build Release APK**
   ```bash
   flutter build apk --release
   ```

2. **Build App Bundle**
   ```bash
   flutter build appbundle --release
   ```

3. **Deploy to Play Store**
   - Upload the app bundle to Google Play Console
   - Fill out store listing information
   - Submit for review

#### iOS Deployment

1. **Build iOS App**
   ```bash
   flutter build ios --release
   ```

2. **Archive in Xcode**
   - Open `ios/Runner.xcworkspace` in Xcode
   - Select Product > Archive
   - Upload to App Store Connect

3. **Submit to App Store**
   - Complete app information in App Store Connect
   - Submit for review

### Performance Considerations

#### Memory Management
- Dispose of streams and controllers properly
- Use object pooling for frequently created objects
- Monitor memory usage in production

#### Battery Optimization
- Minimize background processing
- Use efficient polling intervals
- Implement smart scheduling based on usage patterns

#### Network Efficiency
- Batch API requests when possible
- Implement intelligent caching
- Use compression for large payloads

### Security Considerations

#### Data Protection
- All sensitive data encrypted at rest
- Use HTTPS for all network communications
- Implement certificate pinning

#### Bypass Prevention
- Multiple detection layers
- Regular integrity checks
- Tamper detection mechanisms

### Testing Strategy

#### Unit Tests
- 95% coverage for domain layer
- 85% coverage for data layer
- Mock all external dependencies

#### Integration Tests
- Test complete user workflows
- Verify platform integrations
- Test error scenarios

#### Security Testing
- Penetration testing
- Bypass attempt testing
- Vulnerability scanning

### Monitoring and Analytics

#### Error Tracking
- Crash reporting with Crashlytics
- Custom error tracking for business logic
- Performance monitoring

#### User Analytics
- Privacy-focused analytics
- Usage pattern analysis
- Feature adoption tracking

### Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines on:
- Code style standards
- Pull request process
- Issue reporting
- Development workflow
```

## Change Documentation

### 1. Changelog Management (Score: 8-10)
- **Version Control**: Semantic versioning
- **Detailed Entries**: Clear description of changes
- **Impact Assessment**: Note breaking changes
- **Migration Guides**: Help for version upgrades

**Good Example:**
```markdown
# Changelog

All notable changes to the Mind Fence project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Advanced scheduling system with recurring sessions
- Location-based blocking (GPS and WiFi network detection)
- Enhanced analytics dashboard with weekly/monthly insights
- Backup and restore functionality for user settings

### Changed
- Improved battery optimization for background monitoring
- Updated UI to Material Design 3 specifications
- Enhanced security with additional bypass detection methods

### Fixed
- Issue where notifications weren't showing on some Android devices
- Memory leak in session monitoring service
- Crash when rapidly toggling app blocking states

## [2.1.0] - 2024-01-15

### Added
- **Focus Session Templates**: Pre-configured session types for common scenarios
  - Study Session (2 hours, blocks social media and games)
  - Work Focus (4 hours, blocks entertainment apps)
  - Sleep Preparation (1 hour, blocks stimulating content)
- **Emergency Contacts Feature**: Allow specific contacts to bypass blocking during emergencies
- **Weekly Focus Reports**: Detailed analytics showing focus trends and improvements
- **Dark Mode Support**: Full dark theme implementation with system preference detection

### Changed
- **BREAKING**: Updated minimum Android version to API 26 (Android 8.0)
  - *Migration*: Users on Android 7.x will need to update their OS or use v2.0.x
- **Improved Session Recovery**: Sessions now automatically resume after app restarts
- **Enhanced Notification System**: More informative notifications with action buttons
- **Performance Optimizations**: 
  - Reduced memory usage by 25%
  - Faster app startup time (improved by 40%)
  - More efficient background monitoring

### Fixed
- **Critical**: Fixed bypass vulnerability where users could access blocked apps through recent apps
- **Session Timer**: Fixed issue where timer would occasionally show incorrect remaining time
- **iOS Screen Time**: Resolved compatibility issues with iOS 17
- **Database Migration**: Fixed corruption issues when upgrading from v1.x
- **Accessibility**: Improved screen reader support for visually impaired users

### Security
- **Enhanced Bypass Detection**: Added ML-based pattern recognition for bypass attempts
- **Root/Jailbreak Detection**: Improved detection of compromised devices
- **Certificate Pinning**: Added certificate pinning for all API communications
- **Data Encryption**: Upgraded to AES-256 encryption for local data storage

### Deprecated
- **Legacy API Endpoints**: Deprecated v1 API endpoints (will be removed in v3.0.0)
  - `/api/v1/sessions` → Use `/api/v2/sessions`
  - `/api/v1/apps` → Use `/api/v2/blocked-apps`

## [2.0.1] - 2023-12-10

### Fixed
- **Hotfix**: Resolved critical issue where blocking wouldn't work on Samsung devices
- **Hotfix**: Fixed crash when starting sessions with more than 20 blocked apps
- **Performance**: Reduced CPU usage during active blocking sessions

## [2.0.0] - 2023-12-01

### Added
- **Complete UI Redesign**: New Material Design interface with improved usability
- **Cross-Platform Sync**: Synchronize settings and sessions across devices
- **Advanced Analytics**: Detailed insights into app usage patterns and focus trends
- **Customizable Blocking Modes**: 
  - Strict Mode: Complete app blocking
  - Gentle Mode: Friction-based blocking with delays
  - Notification Mode: Block notifications only
- **Parental Controls**: Allow parents to manage children's device usage

### Changed
- **BREAKING**: Complete rewrite of blocking engine for improved reliability
  - *Migration*: All existing sessions and settings will be preserved during upgrade
- **BREAKING**: New API structure for third-party integrations
  - *Migration*: See [API Migration Guide](docs/api-migration-v2.md)
- **Improved Permission Handling**: Streamlined permission request flow
- **Enhanced Security**: Multi-layer bypass prevention system

### Removed
- **BREAKING**: Removed deprecated timer-based blocking (replaced with session-based)
- **BREAKING**: Removed support for Android 6.0 and below
- Legacy backup format (exported data will be automatically converted)

### Fixed
- Over 50 bug fixes and stability improvements
- Resolved all reported accessibility issues
- Fixed memory leaks in background services

### Security
- Implemented end-to-end encryption for cloud sync
- Added integrity checks for app binaries
- Enhanced protection against reverse engineering

## [1.5.2] - 2023-10-15

### Fixed
- **Critical Security Fix**: Patched vulnerability allowing bypass through developer options
- Fixed issue where sessions wouldn't end automatically on some devices
- Resolved crash when accessing analytics with no session history

### Security
- **CVE-2023-12345**: Fixed privilege escalation vulnerability in device admin handler
- Updated all dependencies to patch known security vulnerabilities

## [1.5.1] - 2023-09-20

### Added
- Support for Android 14 and iOS 17
- Portuguese and Spanish language support

### Fixed
- Improved stability on foldable devices
- Fixed widget placement issues on tablets
- Resolved synchronization conflicts in multi-device setups

## [1.5.0] - 2023-08-30

### Added
- **Widget Support**: Home screen widgets for quick session control
- **Focus Statistics**: Detailed metrics about focus sessions and productivity
- **Smart Suggestions**: AI-powered recommendations for optimal blocking schedules
- **Accessibility Improvements**: Enhanced support for screen readers and keyboard navigation

### Changed
- Redesigned onboarding flow with interactive tutorials
- Improved battery optimization algorithms
- Updated app icons and visual design

### Fixed
- Fixed issues with session persistence during device reboots
- Resolved problems with notification permissions on Android 13
- Fixed memory usage spikes during long sessions

---

## Migration Guides

### Upgrading from v1.x to v2.0

#### Database Migration
Your existing data will be automatically migrated, but we recommend backing up first:

1. **Backup Your Data**: Settings > Backup > Export Settings
2. **Update the App**: Install v2.0 from your app store
3. **Verify Migration**: Check that your blocked apps and session history are intact
4. **Test Functionality**: Create a test session to ensure blocking works correctly

#### API Changes (For Developers)
If you're using Mind Fence APIs:

```dart
// Old API (v1.x)
await mindFence.blockApps(['com.instagram.android']);

// New API (v2.0)
final result = await mindFence.blockingService.blockApps(['com.instagram.android']);
if (result.isSuccess) {
  print('Apps blocked successfully');
}
```

#### Configuration Changes
Some settings have moved:

- **Session Settings**: Now under Settings > Focus Sessions
- **Blocked Apps**: Now under Settings > App Management
- **Analytics**: New dedicated Analytics tab

### Upgrading from v2.0 to v2.1

This is a minor update with mostly additive changes:

1. **New Features**: All new features are opt-in
2. **Performance**: Automatic performance improvements
3. **Settings**: New settings categories added, existing settings unchanged

---

## Version Support Policy

| Version | Release Date | Support Until | Security Updates |
|---------|-------------|---------------|------------------|
| 2.1.x   | 2024-01-15  | 2025-01-15   | ✅ Active        |
| 2.0.x   | 2023-12-01  | 2024-06-01   | ✅ Active        |
| 1.5.x   | 2023-08-30  | 2024-02-29   | ⚠️ Security Only  |
| 1.4.x   | 2023-05-15  | 2023-11-15   | ❌ End of Life   |

### Support Guidelines
- **Active Support**: Full feature updates, bug fixes, and security patches
- **Security Only**: Critical security patches only
- **End of Life**: No updates provided, upgrade recommended
```

## Scoring Criteria

### Score 9-10: Excellent
- Complete API documentation with examples
- Comprehensive user guides with screenshots
- Detailed technical architecture documentation
- Well-maintained changelog with migration guides
- Excellent inline code comments

### Score 7-8: Good
- Good API documentation
- Basic user guides
- Architecture overview documented
- Regular changelog updates
- Good inline comments

### Score 5-6: Acceptable
- Basic API documentation
- Limited user guides
- Some technical documentation
- Irregular changelog
- Some inline comments

### Score 3-4: Below Standard
- Poor API documentation
- Minimal user guides
- Little technical documentation
- Infrequent changelog updates
- Few inline comments

### Score 1-2: Poor
- No API documentation
- No user guides
- No technical documentation
- No changelog
- No inline comments

## Common Documentation Anti-Patterns to Avoid

1. **Outdated Documentation**: Documentation that doesn't match current code
2. **Missing Examples**: API documentation without usage examples
3. **Vague Descriptions**: Unclear or ambiguous explanations
4. **No Migration Guides**: Breaking changes without upgrade instructions
5. **Poor Code Comments**: Comments that state the obvious instead of explaining why
6. **Inconsistent Style**: Different documentation styles across the project
7. **Missing Error Documentation**: Not documenting possible exceptions
8. **No Troubleshooting**: User guides without problem-solving sections
9. **Technical Jargon**: User documentation filled with technical terms
10. **No Visual Aids**: Complex procedures without screenshots or diagrams

Remember: Good documentation is an investment in the future of the Mind Fence project. It reduces support burden, improves developer productivity, and enhances user experience. Documentation should be treated as a first-class deliverable, not an afterthought.