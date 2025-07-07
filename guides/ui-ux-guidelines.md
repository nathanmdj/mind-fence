# UI/UX Design Guidelines

## Overview

Mind Fence requires a clean, distraction-free interface that promotes focus and productivity. These guidelines ensure consistent, accessible, and user-friendly design across all platforms.

## Core Design Principles

### 1. Minimalist Design (Score: 8-10)
- **Clean Interface**: Minimal visual clutter, essential elements only
- **Whitespace**: Generous spacing between elements
- **Typography**: Clear hierarchy with readable fonts
- **Color Palette**: Calming, non-distracting colors

**Good Example:**
```dart
// Clean card design with proper spacing
Card(
  elevation: 2,
  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  child: Padding(
    padding: EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Focus Session',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        SizedBox(height: 8),
        Text(
          'Block social media for focused work',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    ),
  ),
)
```

**Bad Example:**
```dart
// Cluttered design with poor spacing
Container(
  decoration: BoxDecoration(
    color: Colors.blue,
    border: Border.all(color: Colors.red, width: 3),
    borderRadius: BorderRadius.circular(20),
  ),
  child: Column(
    children: [
      Text('Focus Session', style: TextStyle(fontSize: 24, color: Colors.yellow)),
      Icon(Icons.star, size: 50, color: Colors.green),
      Text('Block social media', style: TextStyle(fontSize: 18, color: Colors.purple)),
      // No spacing, conflicting colors
    ],
  ),
)
```

### 2. Dark Mode Implementation (Score: 8-10)
- **Complete Theme Support**: All components support dark mode
- **Appropriate Colors**: Dark backgrounds with light text
- **Consistent Contrast**: Maintain readability in both themes
- **System Integration**: Follow system theme preferences

**Good Example:**
```dart
// Proper theme-aware implementation
class AppTheme {
  static final lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.light,
    ),
    cardTheme: CardTheme(
      elevation: 2,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
  );

  static final darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    ),
    cardTheme: CardTheme(
      elevation: 2,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
  );
}

// Usage in widget
Container(
  color: Theme.of(context).colorScheme.surface,
  child: Text(
    'Mind Fence',
    style: TextStyle(
      color: Theme.of(context).colorScheme.onSurface,
    ),
  ),
)
```

### 3. Responsive Design (Score: 8-10)
- **Flexible Layouts**: Adapt to different screen sizes
- **Orientation Support**: Handle portrait and landscape modes
- **Tablet Optimization**: Utilize larger screens effectively
- **Text Scaling**: Support accessibility text sizes

**Good Example:**
```dart
// Responsive layout using LayoutBuilder
class ResponsiveLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          // Tablet layout
          return Row(
            children: [
              Expanded(flex: 1, child: NavigationDrawer()),
              Expanded(flex: 3, child: MainContent()),
            ],
          );
        } else {
          // Phone layout
          return Column(
            children: [
              AppBar(),
              Expanded(child: MainContent()),
            ],
          );
        }
      },
    );
  }
}
```

## Material Design 3 Compliance

### 1. Component Usage (Score: 7-10)
- **Standard Components**: Use Material 3 components consistently
- **Proper Styling**: Follow Material Design specifications
- **State Management**: Handle different component states
- **Accessibility**: Ensure components are accessible

**Good Example:**
```dart
// Proper Material 3 button implementation
FilledButton(
  onPressed: () => _startFocusSession(),
  child: Text('Start Focus Session'),
)

// Proper Material 3 card with state
Card(
  elevation: widget.isActive ? 4 : 1,
  child: ListTile(
    leading: Icon(
      widget.isActive ? Icons.block : Icons.check_circle,
      color: widget.isActive ? Colors.red : Colors.green,
    ),
    title: Text(widget.appName),
    subtitle: Text(widget.description),
    trailing: Switch(
      value: widget.isActive,
      onChanged: widget.onToggle,
    ),
  ),
)
```

### 2. Color System (Score: 8-10)
- **Theme Colors**: Use theme-defined colors consistently
- **Semantic Colors**: Apply colors with semantic meaning
- **Contrast Ratios**: Maintain accessibility standards
- **Color Roles**: Follow Material 3 color roles

**Good Example:**
```dart
// Semantic color usage
class StatusColors {
  static Color blocked(BuildContext context) =>
      Theme.of(context).colorScheme.error;
  
  static Color active(BuildContext context) =>
      Theme.of(context).colorScheme.primary;
  
  static Color inactive(BuildContext context) =>
      Theme.of(context).colorScheme.outline;
}

// Usage
Container(
  decoration: BoxDecoration(
    color: isBlocked 
        ? StatusColors.blocked(context).withOpacity(0.1)
        : StatusColors.active(context).withOpacity(0.1),
    border: Border.all(
      color: isBlocked 
          ? StatusColors.blocked(context)
          : StatusColors.active(context),
    ),
  ),
)
```

## User Experience Patterns

### 1. Blocking Interface (Score: 8-10)
- **Clear Status**: Immediately show what's blocked
- **Easy Toggle**: Simple on/off controls
- **Visual Feedback**: Clear indication of blocking state
- **Emergency Access**: Accessible override options

**Good Example:**
```dart
class BlockingCard extends StatelessWidget {
  final String appName;
  final bool isBlocked;
  final VoidCallback onToggle;
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isBlocked ? Colors.red : Colors.green,
          child: Icon(
            isBlocked ? Icons.block : Icons.check,
            color: Colors.white,
          ),
        ),
        title: Text(appName),
        subtitle: Text(
          isBlocked ? 'Currently blocked' : 'Not blocked',
          style: TextStyle(
            color: isBlocked ? Colors.red : Colors.green,
          ),
        ),
        trailing: Switch(
          value: isBlocked,
          onChanged: (_) => onToggle(),
        ),
      ),
    );
  }
}
```

### 2. Focus Sessions (Score: 8-10)
- **Timer Display**: Large, visible countdown
- **Progress Indication**: Visual progress tracking
- **Minimal Distractions**: Clean interface during sessions
- **Session Controls**: Easy start/stop/pause actions

**Good Example:**
```dart
class FocusSessionTimer extends StatelessWidget {
  final Duration remaining;
  final bool isActive;
  final VoidCallback onStart;
  final VoidCallback onStop;
  
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _formatDuration(remaining),
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.red : Colors.grey,
          ),
        ),
        SizedBox(height: 32),
        CircularProgressIndicator(
          value: _getProgress(),
          strokeWidth: 8,
          backgroundColor: Colors.grey[300],
        ),
        SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (!isActive)
              FilledButton(
                onPressed: onStart,
                child: Text('Start Focus'),
              ),
            if (isActive)
              FilledButton(
                onPressed: onStop,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: Text('End Session'),
              ),
          ],
        ),
      ],
    );
  }
}
```

## Accessibility Requirements

### 1. Screen Reader Support (Score: 8-10)
- **Semantic Labels**: Meaningful accessibility labels
- **Screen Reader Testing**: Test with TalkBack/VoiceOver
- **Focus Management**: Logical focus order
- **Action Descriptions**: Clear action descriptions

**Good Example:**
```dart
// Accessible switch with semantic labels
Semantics(
  label: 'Block ${widget.appName}',
  hint: widget.isBlocked 
      ? 'Currently blocked, tap to unblock'
      : 'Currently not blocked, tap to block',
  child: Switch(
    value: widget.isBlocked,
    onChanged: widget.onToggle,
  ),
)
```

### 2. Color Contrast (Score: 8-10)
- **WCAG AA Compliance**: Minimum 4.5:1 contrast ratio
- **Color Independence**: Information not solely dependent on color
- **Test Tools**: Use contrast checking tools
- **High Contrast**: Support high contrast modes

## Animation and Transitions

### 1. Smooth Animations (Score: 7-10)
- **60fps Performance**: Smooth, performant animations
- **Appropriate Duration**: 200-300ms for most transitions
- **Easing Curves**: Use appropriate easing functions
- **Reduce Motion**: Respect accessibility preferences

**Good Example:**
```dart
// Smooth state transition
AnimatedContainer(
  duration: Duration(milliseconds: 250),
  curve: Curves.easeInOut,
  color: isBlocked ? Colors.red : Colors.green,
  child: Icon(isBlocked ? Icons.block : Icons.check),
)
```

## Scoring Criteria

### Score 9-10: Excellent
- Perfect Material Design 3 compliance
- Flawless dark mode implementation
- Complete accessibility support
- Responsive design for all devices
- Smooth, performant animations

### Score 7-8: Good
- Good Material Design compliance with minor issues
- Functional dark mode with minor inconsistencies
- Basic accessibility support
- Mostly responsive design
- Generally smooth animations

### Score 5-6: Acceptable
- Basic Material Design usage
- Dark mode partially implemented
- Limited accessibility features
- Some responsive design elements
- Acceptable animations

### Score 3-4: Below Standard
- Inconsistent design patterns
- Poor or missing dark mode
- Minimal accessibility support
- Poor responsive design
- Choppy or missing animations

### Score 1-2: Poor
- No design consistency
- No dark mode support
- No accessibility considerations
- Fixed layouts only
- No animations or poor performance

## Common Anti-Patterns to Avoid

1. **Hardcoded Colors**: Always use theme colors
2. **Fixed Sizes**: Use responsive measurements
3. **Poor Contrast**: Ensure readability in all themes
4. **Inconsistent Spacing**: Use consistent padding/margins
5. **Missing Accessibility**: Always add semantic labels
6. **Cluttered Interface**: Keep design minimal and focused
7. **Poor Animation**: Avoid jarring or slow transitions
8. **Ignoring States**: Handle loading, error, and empty states

Remember: The UI is the user's primary interaction point with the blocking functionality. It must be intuitive, accessible, and distraction-free to support the app's core mission of reducing digital distractions.