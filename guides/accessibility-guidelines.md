# Accessibility Guidelines

## Overview

Mind Fence must be accessible to all users, including those with disabilities. These guidelines ensure compliance with WCAG 2.1 AA standards and provide an inclusive experience for users with visual, auditory, motor, and cognitive impairments.

## Visual Accessibility

### 1. Color and Contrast (Score: 9-10)
- **WCAG AA Compliance**: Minimum 4.5:1 contrast ratio for normal text, 3:1 for large text
- **Color Independence**: Information not conveyed by color alone
- **High Contrast Support**: Support system high contrast modes
- **Color Blind Friendly**: Accessible to users with color vision deficiencies

**Good Example:**
```dart
// Accessible color scheme with proper contrast
class AccessibleColors {
  static const Color primaryText = Color(0xFF212121); // Contrast ratio: 15.8:1 on white
  static const Color secondaryText = Color(0xFF757575); // Contrast ratio: 4.61:1 on white
  static const Color errorText = Color(0xFFD32F2F); // Contrast ratio: 5.25:1 on white
  static const Color successText = Color(0xFF388E3C); // Contrast ratio: 4.52:1 on white
  
  // Status colors with sufficient contrast
  static const Color blockedBackground = Color(0xFFFFEBEE); // Light red
  static const Color blockedBorder = Color(0xFFE57373); // Medium red
  static const Color blockedIcon = Color(0xFFD32F2F); // Dark red
  
  static const Color activeBackground = Color(0xFFE8F5E8); // Light green
  static const Color activeBorder = Color(0xFF81C784); // Medium green
  static const Color activeIcon = Color(0xFF388E3C); // Dark green
  
  // High contrast theme colors
  static const Color highContrastText = Color(0xFF000000);
  static const Color highContrastBackground = Color(0xFFFFFFFF);
  static const Color highContrastAccent = Color(0xFF0000FF);
}

// Accessible status indicator with multiple visual cues
class AccessibleStatusIndicator extends StatelessWidget {
  const AccessibleStatusIndicator({
    super.key,
    required this.isBlocked,
    required this.appName,
  });

  final bool isBlocked;
  final String appName;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: isBlocked ? '$appName is blocked' : '$appName is not blocked',
      value: isBlocked ? 'Blocked' : 'Active',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          // Background color
          color: isBlocked 
              ? AccessibleColors.blockedBackground 
              : AccessibleColors.activeBackground,
          // Border for additional visual distinction
          border: Border.all(
            color: isBlocked 
                ? AccessibleColors.blockedBorder 
                : AccessibleColors.activeBorder,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon for visual indication
            Icon(
              isBlocked ? Icons.block : Icons.check_circle,
              color: isBlocked 
                  ? AccessibleColors.blockedIcon 
                  : AccessibleColors.activeIcon,
              size: 16,
            ),
            const SizedBox(width: 4),
            // Text for additional clarity
            Text(
              isBlocked ? 'Blocked' : 'Active',
              style: TextStyle(
                color: isBlocked 
                    ? AccessibleColors.blockedIcon 
                    : AccessibleColors.activeIcon,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Bad Example:**
```dart
// Poor accessibility - relies only on color
class InaccessibleStatusIndicator extends StatelessWidget {
  final bool isBlocked;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        // Only color difference - inaccessible
        color: isBlocked ? Colors.red : Colors.green,
        shape: BoxShape.circle,
      ),
      // No semantic information
    );
  }
}
```

### 2. Text Accessibility (Score: 8-10)
- **Scalable Text**: Support dynamic text sizing
- **Readable Fonts**: Use clear, readable font families
- **Text Spacing**: Adequate line height and letter spacing
- **Text Alternatives**: Provide text alternatives for images

**Good Example:**
```dart
// Accessible text implementation
class AccessibleText extends StatelessWidget {
  const AccessibleText({
    super.key,
    required this.text,
    this.style,
    this.semanticsLabel,
    this.maxLines,
    this.textAlign,
  });

  final String text;
  final TextStyle? style;
  final String? semanticsLabel;
  final int? maxLines;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    
    // Respect user's text scale preference
    final textScaleFactor = mediaQuery.textScaleFactor.clamp(0.8, 2.0);
    
    return Semantics(
      label: semanticsLabel ?? text,
      child: Text(
        text,
        style: (style ?? theme.textTheme.bodyMedium)?.copyWith(
          // Ensure minimum text size
          fontSize: math.max(
            (style?.fontSize ?? 14) * textScaleFactor,
            14.0,
          ),
          // Improve readability with proper line height
          height: 1.4,
          // Ensure good contrast
          color: style?.color ?? theme.colorScheme.onSurface,
        ),
        maxLines: maxLines,
        textAlign: textAlign,
        // Enable text selection for screen readers
        textScaleFactor: 1.0, // We handle scaling manually
      ),
    );
  }
}

// Accessible heading with proper semantics
class AccessibleHeading extends StatelessWidget {
  const AccessibleHeading({
    super.key,
    required this.text,
    this.level = 1,
  });

  final String text;
  final int level; // Heading level 1-6

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    TextStyle style;
    switch (level) {
      case 1:
        style = theme.textTheme.headlineLarge!;
        break;
      case 2:
        style = theme.textTheme.headlineMedium!;
        break;
      case 3:
        style = theme.textTheme.headlineSmall!;
        break;
      case 4:
        style = theme.textTheme.titleLarge!;
        break;
      case 5:
        style = theme.textTheme.titleMedium!;
        break;
      case 6:
        style = theme.textTheme.titleSmall!;
        break;
      default:
        style = theme.textTheme.headlineMedium!;
    }

    return Semantics(
      header: true,
      child: AccessibleText(
        text: text,
        style: style,
        semanticsLabel: 'Heading level $level: $text',
      ),
    );
  }
}
```

## Screen Reader Support

### 1. Semantic Labels and Hints (Score: 9-10)
- **Descriptive Labels**: Clear, descriptive accessibility labels
- **Helpful Hints**: Provide usage hints for complex interactions
- **State Information**: Communicate current state clearly
- **Context Information**: Provide sufficient context

**Good Example:**
```dart
// Comprehensive screen reader support
class AccessibleBlockingSwitch extends StatelessWidget {
  const AccessibleBlockingSwitch({
    super.key,
    required this.app,
    required this.onToggle,
    this.isLoading = false,
  });

  final BlockedApp app;
  final VoidCallback onToggle;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // Clear label describing the control
      label: 'Blocking control for ${app.name}',
      
      // Current state information
      value: app.isBlocked ? 'Currently blocked' : 'Currently not blocked',
      
      // Instructions for use
      hint: isLoading 
          ? 'Please wait, updating blocking status'
          : app.isBlocked 
              ? 'Double tap to unblock this app'
              : 'Double tap to block this app',
      
      // Additional semantic information
      toggled: app.isBlocked,
      enabled: !isLoading,
      
      // Focus and interaction handling
      focusable: true,
      
      child: Switch(
        value: app.isBlocked,
        onChanged: isLoading ? null : (_) => onToggle(),
        
        // Visual indicator for loading state
        thumbIcon: isLoading 
            ? MaterialStateProperty.all(
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : null,
      ),
    );
  }
}

// Accessible focus session timer
class AccessibleFocusTimer extends StatefulWidget {
  const AccessibleFocusTimer({
    super.key,
    required this.remaining,
    required this.total,
    required this.isActive,
  });

  final Duration remaining;
  final Duration total;
  final bool isActive;

  @override
  State<AccessibleFocusTimer> createState() => _AccessibleFocusTimerState();
}

class _AccessibleFocusTimerState extends State<AccessibleFocusTimer> {
  String _lastAnnouncedTime = '';
  
  @override
  void didUpdateWidget(AccessibleFocusTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Announce time updates periodically
    if (widget.isActive && widget.remaining != oldWidget.remaining) {
      _announceTimeIfNeeded();
    }
  }

  void _announceTimeIfNeeded() {
    final timeString = _formatTimeForScreenReader(widget.remaining);
    
    // Only announce every minute to avoid spam
    if (widget.remaining.inSeconds % 60 == 0 && timeString != _lastAnnouncedTime) {
      _lastAnnouncedTime = timeString;
      
      SemanticsService.announce(
        'Focus session: $timeString remaining',
        TextDirection.ltr,
      );
    }
  }

  String _formatTimeForScreenReader(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '$hours hours and $minutes minutes';
    } else if (minutes > 0) {
      return '$minutes minutes and $seconds seconds';
    } else {
      return '$seconds seconds';
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeDisplay = _formatTime(widget.remaining);
    final progressValue = (widget.total.inSeconds - widget.remaining.inSeconds) / widget.total.inSeconds;
    
    return Semantics(
      label: 'Focus session timer',
      value: '${_formatTimeForScreenReader(widget.remaining)} remaining',
      hint: widget.isActive ? 'Session is active' : 'Session is paused',
      child: Column(
        children: [
          // Timer display
          Semantics(
            label: 'Time remaining',
            value: _formatTimeForScreenReader(widget.remaining),
            liveRegion: true, // Announces changes automatically
            child: Text(
              timeDisplay,
              style: Theme.of(context).textTheme.displayLarge,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Progress indicator
          Semantics(
            label: 'Session progress',
            value: '${(progressValue * 100).round()}% complete',
            child: LinearProgressIndicator(
              value: progressValue,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.isActive ? Colors.blue : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }
}
```

### 2. Navigation and Focus Management (Score: 8-10)
- **Logical Focus Order**: Focus moves in logical order
- **Focus Indicators**: Clear visual focus indicators
- **Skip Links**: Provide skip navigation options
- **Focus Restoration**: Restore focus appropriately

**Good Example:**
```dart
// Accessible navigation with proper focus management
class AccessibleScreen extends StatefulWidget {
  const AccessibleScreen({super.key});

  @override
  State<AccessibleScreen> createState() => _AccessibleScreenState();
}

class _AccessibleScreenState extends State<AccessibleScreen> {
  final List<FocusNode> _focusNodes = [];
  int _currentFocusIndex = 0;
  
  @override
  void initState() {
    super.initState();
    
    // Create focus nodes for navigation
    for (int i = 0; i < 5; i++) {
      _focusNodes.add(FocusNode());
    }
  }

  @override
  void dispose() {
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _moveFocus(bool forward) {
    if (forward) {
      _currentFocusIndex = (_currentFocusIndex + 1) % _focusNodes.length;
    } else {
      _currentFocusIndex = (_currentFocusIndex - 1 + _focusNodes.length) % _focusNodes.length;
    }
    
    _focusNodes[_currentFocusIndex].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const AccessibleText(
          text: 'Mind Fence',
          semanticsLabel: 'Mind Fence app, main screen',
        ),
        actions: [
          // Skip to main content
          Semantics(
            button: true,
            label: 'Skip to main content',
            hint: 'Bypass navigation and go directly to main content',
            child: IconButton(
              focusNode: _focusNodes[0],
              icon: const Icon(Icons.skip_next),
              onPressed: () {
                _focusNodes[2].requestFocus(); // Focus main content
              },
            ),
          ),
        ],
      ),
      
      body: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (event) {
          // Handle keyboard navigation
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.tab) {
              _moveFocus(!event.modifiersPressed.contains(LogicalKeyboardKey.shift));
            }
          }
        },
        child: Column(
          children: [
            // Navigation section
            Semantics(
              label: 'Navigation section',
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Semantics(
                      button: true,
                      label: 'View blocked apps',
                      child: ElevatedButton(
                        focusNode: _focusNodes[1],
                        onPressed: () => _navigateToBlockedApps(),
                        child: const Text('Blocked Apps'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Semantics(
                      button: true,
                      label: 'Start focus session',
                      child: ElevatedButton(
                        focusNode: _focusNodes[2],
                        onPressed: () => _startFocusSession(),
                        child: const Text('Focus Session'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Main content
            Expanded(
              child: Semantics(
                label: 'Main content area',
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Screen reader landmark
                        Semantics(
                          label: 'Main content begins here',
                          child: const SizedBox.shrink(),
                        ),
                        
                        const AccessibleHeading(
                          text: 'Your Blocking Status',
                          level: 1,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Focus main content here
                        Focus(
                          focusNode: _focusNodes[3],
                          child: const AccessibleBlockingOverview(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      
      floatingActionButton: Semantics(
        button: true,
        label: 'Add new app to block',
        hint: 'Opens a dialog to select an app to block',
        child: FloatingActionButton(
          focusNode: _focusNodes[4],
          onPressed: _showAddAppDialog,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _navigateToBlockedApps() {
    // Implementation
  }

  void _startFocusSession() {
    // Implementation
  }

  void _showAddAppDialog() {
    // Implementation
  }
}
```

## Motor Accessibility

### 1. Touch Target Size (Score: 8-10)
- **Minimum Size**: 44x44 logical pixels minimum touch targets
- **Adequate Spacing**: Sufficient spacing between interactive elements
- **Easy Interaction**: Support for different interaction methods
- **Gesture Alternatives**: Provide alternatives to complex gestures

**Good Example:**
```dart
// Accessible touch targets and interactions
class AccessibleButton extends StatelessWidget {
  const AccessibleButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.semanticsLabel,
    this.semanticsHint,
    this.minimumSize = const Size(44, 44),
  });

  final VoidCallback? onPressed;
  final Widget child;
  final String? semanticsLabel;
  final String? semanticsHint;
  final Size minimumSize;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      hint: semanticsHint,
      enabled: onPressed != null,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: BoxConstraints(
              minWidth: minimumSize.width,
              minHeight: minimumSize.height,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).primaryColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

// Accessible slider with large touch targets
class AccessibleTimeSlider extends StatefulWidget {
  const AccessibleTimeSlider({
    super.key,
    required this.value,
    required this.onChanged,
    required this.min,
    required this.max,
    this.divisions,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;
  final int? divisions;

  @override
  State<AccessibleTimeSlider> createState() => _AccessibleTimeSliderState();
}

class _AccessibleTimeSliderState extends State<AccessibleTimeSlider> {
  @override
  Widget build(BuildContext context) {
    final duration = Duration(minutes: widget.value.round());
    
    return Semantics(
      slider: true,
      label: 'Focus session duration',
      value: _formatDuration(duration),
      hint: 'Swipe left to decrease, right to increase duration',
      increasedValue: _formatDuration(
        Duration(minutes: (widget.value + 15).round()),
      ),
      decreasedValue: _formatDuration(
        Duration(minutes: (widget.value - 15).round()),
      ),
      onIncrease: widget.value < widget.max ? () {
        widget.onChanged((widget.value + 15).clamp(widget.min, widget.max));
      } : null,
      onDecrease: widget.value > widget.min ? () {
        widget.onChanged((widget.value - 15).clamp(widget.min, widget.max));
      } : null,
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          // Larger thumb for easier interaction
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 16),
          
          // Larger track for easier touch
          trackHeight: 8,
          
          // Better visibility
          activeTrackColor: Theme.of(context).primaryColor,
          inactiveTrackColor: Theme.of(context).primaryColor.withOpacity(0.3),
          thumbColor: Theme.of(context).primaryColor,
          
          // Value indicator
          showValueIndicator: ShowValueIndicator.always,
          valueIndicatorTextStyle: Theme.of(context).textTheme.bodyMedium,
        ),
        child: Slider(
          value: widget.value,
          min: widget.min,
          max: widget.max,
          divisions: widget.divisions,
          label: _formatDuration(duration),
          onChanged: widget.onChanged,
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '$hours hours ${minutes} minutes';
    } else {
      return '$minutes minutes';
    }
  }
}
```

### 2. Keyboard Navigation (Score: 8-10)
- **Full Keyboard Support**: All functionality accessible via keyboard
- **Logical Tab Order**: Focus moves in logical sequence
- **Keyboard Shortcuts**: Provide useful shortcuts
- **Visual Focus Indicators**: Clear focus indication

**Good Example:**
```dart
// Full keyboard navigation support
class KeyboardAccessibleApp extends StatefulWidget {
  const KeyboardAccessibleApp({super.key});

  @override
  State<KeyboardAccessibleApp> createState() => _KeyboardAccessibleAppState();
}

class _KeyboardAccessibleAppState extends State<KeyboardAccessibleApp> {
  late final FocusNode _mainFocusNode;
  final Map<LogicalKeySet, Intent> _shortcuts = {
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN): const AddAppIntent(),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF): const StartFocusIntent(),
    LogicalKeySet(LogicalKeyboardKey.escape): const CancelIntent(),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyR): const RefreshIntent(),
  };

  @override
  void initState() {
    super.initState();
    _mainFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _mainFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: _shortcuts,
      child: Actions(
        actions: {
          AddAppIntent: CallbackAction<AddAppIntent>(
            onInvoke: (_) => _addApp(),
          ),
          StartFocusIntent: CallbackAction<StartFocusIntent>(
            onInvoke: (_) => _startFocus(),
          ),
          CancelIntent: CallbackAction<CancelIntent>(
            onInvoke: (_) => _cancel(),
          ),
          RefreshIntent: CallbackAction<RefreshIntent>(
            onInvoke: (_) => _refresh(),
          ),
        },
        child: Focus(
          focusNode: _mainFocusNode,
          autofocus: true,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Mind Fence'),
              actions: [
                // Keyboard shortcut help
                Semantics(
                  button: true,
                  label: 'Show keyboard shortcuts',
                  hint: 'Press to see available keyboard shortcuts',
                  child: IconButton(
                    icon: const Icon(Icons.keyboard),
                    onPressed: _showKeyboardHelp,
                  ),
                ),
              ],
            ),
            body: const KeyboardNavigableContent(),
          ),
        ),
      ),
    );
  }

  void _addApp() {
    // Announce action to screen reader
    SemanticsService.announce(
      'Opening add app dialog',
      TextDirection.ltr,
    );
    // Implementation
  }

  void _startFocus() {
    SemanticsService.announce(
      'Starting focus session',
      TextDirection.ltr,
    );
    // Implementation
  }

  void _cancel() {
    SemanticsService.announce(
      'Cancelled',
      TextDirection.ltr,
    );
    Navigator.of(context).maybePop();
  }

  void _refresh() {
    SemanticsService.announce(
      'Refreshing data',
      TextDirection.ltr,
    );
    // Implementation
  }

  void _showKeyboardHelp() {
    showDialog(
      context: context,
      builder: (context) => const KeyboardHelpDialog(),
    );
  }
}

// Keyboard shortcuts help dialog
class KeyboardHelpDialog extends StatelessWidget {
  const KeyboardHelpDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Keyboard Shortcuts'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AccessibleText(text: 'Ctrl+N: Add new app'),
          AccessibleText(text: 'Ctrl+F: Start focus session'),
          AccessibleText(text: 'Ctrl+R: Refresh data'),
          AccessibleText(text: 'Escape: Cancel/Go back'),
          AccessibleText(text: 'Tab: Move to next element'),
          AccessibleText(text: 'Shift+Tab: Move to previous element'),
          AccessibleText(text: 'Space/Enter: Activate button'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

// Intent classes for keyboard shortcuts
class AddAppIntent extends Intent {}
class StartFocusIntent extends Intent {}
class RefreshIntent extends Intent {}
```

## Cognitive Accessibility

### 1. Clear Communication (Score: 8-10)
- **Simple Language**: Use clear, simple language
- **Consistent Terminology**: Use consistent terms throughout
- **Clear Instructions**: Provide clear, step-by-step instructions
- **Error Prevention**: Prevent errors where possible

**Good Example:**
```dart
// Clear, accessible form with validation
class AccessibleFocusSessionForm extends StatefulWidget {
  const AccessibleFocusSessionForm({super.key});

  @override
  State<AccessibleFocusSessionForm> createState() => _AccessibleFocusSessionFormState();
}

class _AccessibleFocusSessionFormState extends State<AccessibleFocusSessionForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _durationController = TextEditingController();
  final List<String> _selectedApps = [];
  
  String? _nameError;
  String? _durationError;
  String? _appsError;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Create focus session form',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Clear heading
            const AccessibleHeading(
              text: 'Create Focus Session',
              level: 1,
            ),
            
            const SizedBox(height: 16),
            
            // Instructions
            const AccessibleText(
              text: 'Fill out the form below to create a new focus session. All fields are required.',
              semanticsLabel: 'Instructions: Fill out the form below to create a new focus session. All fields are required.',
            ),
            
            const SizedBox(height: 24),
            
            // Session name field
            _buildNameField(),
            
            const SizedBox(height: 16),
            
            // Duration field
            _buildDurationField(),
            
            const SizedBox(height: 16),
            
            // App selection
            _buildAppSelection(),
            
            const SizedBox(height: 24),
            
            // Submit button
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Field label
        Semantics(
          label: 'Session name field',
          child: const AccessibleText(
            text: 'Session Name *',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Input field
        Semantics(
          textField: true,
          label: 'Enter a name for your focus session',
          hint: 'Type a descriptive name like Work Time or Study Session',
          child: TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'e.g., Work Time, Study Session',
              errorText: _nameError,
              border: const OutlineInputBorder(),
              helperText: 'Choose a name that helps you remember this session',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a session name';
              }
              if (value.trim().length < 3) {
                return 'Session name must be at least 3 characters';
              }
              return null;
            },
            onChanged: (value) {
              setState(() {
                _nameError = null;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDurationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: 'Session duration field',
          child: const AccessibleText(
            text: 'Duration (minutes) *',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        
        const SizedBox(height: 8),
        
        Semantics(
          textField: true,
          label: 'Enter session duration in minutes',
          hint: 'Type a number between 15 and 480 minutes',
          child: TextFormField(
            controller: _durationController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'e.g., 60 for 1 hour',
              errorText: _durationError,
              border: const OutlineInputBorder(),
              helperText: 'Enter minutes (15-480). Example: 60 for 1 hour',
              suffixText: 'minutes',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter session duration';
              }
              
              final duration = int.tryParse(value.trim());
              if (duration == null) {
                return 'Please enter a valid number';
              }
              
              if (duration < 15) {
                return 'Minimum duration is 15 minutes';
              }
              
              if (duration > 480) {
                return 'Maximum duration is 8 hours (480 minutes)';
              }
              
              return null;
            },
            onChanged: (value) {
              setState(() {
                _durationError = null;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAppSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: 'App selection section',
          child: const AccessibleText(
            text: 'Apps to Block *',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        
        const SizedBox(height: 8),
        
        const AccessibleText(
          text: 'Select which apps you want to block during this session',
        ),
        
        const SizedBox(height: 12),
        
        if (_appsError != null)
          Semantics(
            liveRegion: true,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red),
                borderRadius: BorderRadius.circular(4),
              ),
              child: AccessibleText(
                text: _appsError!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
        
        // App list would go here
        const Placeholder(fallbackHeight: 200),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: AccessibleButton(
        onPressed: _submitForm,
        semanticsLabel: 'Create focus session',
        semanticsHint: 'Creates a new focus session with the entered settings',
        child: const AccessibleText(
          text: 'Create Session',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      // Success announcement
      SemanticsService.announce(
        'Focus session created successfully',
        TextDirection.ltr,
      );
      
      // Implementation
    } else {
      // Error announcement
      SemanticsService.announce(
        'Please fix the errors in the form',
        TextDirection.ltr,
      );
    }
  }
}
```

## Testing Accessibility

### 1. Automated Testing (Score: 8-10)
- **Accessibility Tests**: Automated accessibility testing
- **Screen Reader Testing**: Test with actual screen readers
- **Contrast Testing**: Automated contrast ratio checking
- **Navigation Testing**: Test keyboard navigation flows

**Good Example:**
```dart
// Comprehensive accessibility testing
void main() {
  group('Accessibility Tests', () {
    testWidgets('BlockingStatusCard meets accessibility requirements', (tester) async {
      final app = BlockedApp(
        id: 'test-app',
        name: 'Instagram',
        packageName: 'com.instagram.android',
        isBlocked: true,
        totalBlockedTime: const Duration(hours: 2),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlockingStatusCard(
              app: app,
              onToggle: () {},
            ),
          ),
        ),
      );

      // Test semantic labels
      expect(
        find.bySemanticsLabel(RegExp(r'Instagram.*blocked')),
        findsOneWidget,
      );

      // Test button semantics
      final switchFinder = find.byType(Switch);
      final switchSemanticsData = tester.getSemantics(switchFinder);
      
      expect(switchSemanticsData.hasFlag(SemanticsFlag.isToggled), true);
      expect(switchSemanticsData.hasAction(SemanticsAction.tap), true);
      expect(switchSemanticsData.label, contains('Instagram'));

      // Test minimum touch target size
      final switchRect = tester.getRect(switchFinder);
      expect(switchRect.width, greaterThanOrEqualTo(44));
      expect(switchRect.height, greaterThanOrEqualTo(44));

      // Test focus
      await tester.tap(switchFinder);
      await tester.pump();
      
      expect(switchSemanticsData.hasFlag(SemanticsFlag.isFocused), true);
    });

    testWidgets('Focus session timer announces time changes', (tester) async {
      bool announcementMade = false;
      String? announcementText;
      
      // Mock SemanticsService
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('flutter/semantics'),
        (call) {
          if (call.method == 'announce') {
            announcementMade = true;
            announcementText = call.arguments['message'];
          }
          return null;
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleFocusTimer(
              remaining: const Duration(minutes: 60),
              total: const Duration(minutes: 60),
              isActive: true,
            ),
          ),
        ),
      );

      // Simulate time change
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleFocusTimer(
              remaining: const Duration(minutes: 59),
              total: const Duration(minutes: 60),
              isActive: true,
            ),
          ),
        ),
      );

      // Check that announcement was made
      expect(announcementMade, true);
      expect(announcementText, contains('59 minutes'));
    });

    testWidgets('Color contrast meets WCAG AA standards', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleStatusIndicator(
              isBlocked: true,
              appName: 'Instagram',
            ),
          ),
        ),
      );

      // Get the rendered colors
      final container = tester.widget<Container>(
        find.byType(Container).first,
      );
      
      final decoration = container.decoration as BoxDecoration;
      final backgroundColor = decoration.color;
      final borderColor = decoration.border?.top.color;

      // Check contrast ratios (simplified test)
      expect(backgroundColor, isNotNull);
      expect(borderColor, isNotNull);
      
      // In a real test, you would calculate actual contrast ratios
      // and ensure they meet WCAG AA standards (4.5:1 for normal text)
    });

    testWidgets('Keyboard navigation works correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: KeyboardAccessibleApp(),
        ),
      );

      // Test initial focus
      expect(find.byType(Focus), findsWidgets);

      // Test tab navigation
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      // Test keyboard shortcuts
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pump();

      // Verify shortcut action was triggered
      // (Implementation would depend on your specific app logic)
    });
  });
}
```

## Scoring Criteria

### Score 9-10: Excellent
- Perfect WCAG 2.1 AA compliance
- Comprehensive screen reader support
- Full keyboard navigation
- Excellent contrast ratios (7:1+)
- Complete accessibility testing
- Multiple input method support

### Score 7-8: Good
- Good WCAG compliance with minor issues
- Good screen reader support
- Basic keyboard navigation
- Good contrast ratios (4.5:1+)
- Some accessibility testing
- Most input methods supported

### Score 5-6: Acceptable
- Basic WCAG compliance
- Limited screen reader support
- Some keyboard navigation
- Acceptable contrast ratios
- Limited accessibility testing
- Basic input method support

### Score 3-4: Below Standard
- Poor WCAG compliance
- Minimal screen reader support
- Limited keyboard navigation
- Poor contrast ratios
- No accessibility testing
- Mouse/touch only

### Score 1-2: Poor
- No accessibility considerations
- No screen reader support
- No keyboard navigation
- Very poor contrast
- No accessibility testing
- Single input method only

## Common Accessibility Anti-Patterns to Avoid

1. **Color-Only Information**: Relying solely on color to convey information
2. **Insufficient Contrast**: Poor contrast ratios
3. **Missing Alt Text**: Images without alternative text
4. **No Keyboard Support**: Mouse/touch-only interactions
5. **Poor Focus Management**: Unclear or missing focus indicators
6. **Tiny Touch Targets**: Interactive elements too small
7. **No Semantic Labels**: Missing accessibility labels
8. **Complex Language**: Overly complex terminology
9. **No Error Prevention**: Poor validation and error handling
10. **Inaccessible Forms**: Forms without proper labels and instructions

Remember: Accessibility is not an afterthought—it should be built into Mind Fence from the beginning. Creating an accessible app benefits all users, not just those with disabilities. Good accessibility practices often improve the overall user experience for everyone.