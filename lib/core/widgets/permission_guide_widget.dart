import 'package:flutter/material.dart';
import '../services/permission_service.dart';

/// Widget that provides enhanced user guidance for permissions
class PermissionGuideWidget extends StatelessWidget {
  final PermissionType permissionType;
  final PermissionResult? permissionResult;
  final VoidCallback? onRequestPermission;
  final VoidCallback? onOpenSettings;
  final bool showDetailedInstructions;
  final bool showPriorityBadge;

  const PermissionGuideWidget({
    super.key,
    required this.permissionType,
    this.permissionResult,
    this.onRequestPermission,
    this.onOpenSettings,
    this.showDetailedInstructions = true,
    this.showPriorityBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon, title, and status
            Row(
              children: [
                _buildPermissionIcon(context),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _getPermissionTitle(),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (showPriorityBadge) _buildPriorityBadge(context),
                        ],
                      ),
                      const SizedBox(height: 4),
                      _buildStatusIndicator(context),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Permission explanation
            Text(
              _getPermissionExplanation(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Why it's needed
            _buildWhyNeededSection(context),
            
            if (showDetailedInstructions && !_isPermissionGranted()) ...[
              const SizedBox(height: 16),
              _buildInstructionsSection(context),
            ],
            
            const SizedBox(height: 16),
            
            // Action buttons
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionIcon(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isGranted = _isPermissionGranted();
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isGranted 
          ? colorScheme.primaryContainer
          : colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        _getPermissionIcon(),
        size: 24,
        color: isGranted 
          ? colorScheme.onPrimaryContainer
          : colorScheme.onErrorContainer,
      ),
    );
  }

  Widget _buildStatusIndicator(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    String statusText;
    Color statusColor;
    
    if (permissionResult == null) {
      statusText = 'Checking...';
      statusColor = colorScheme.onSurfaceVariant;
    } else if (permissionResult!.isGranted) {
      statusText = 'Granted ✓';
      statusColor = colorScheme.primary;
    } else if (permissionResult!.isPermanentlyDenied) {
      statusText = 'Permanently Denied - Settings Required';
      statusColor = colorScheme.error;
    } else if (permissionResult!.isDenied) {
      statusText = 'Not Granted';
      statusColor = colorScheme.error;
    } else if (permissionResult!.isRestricted) {
      statusText = 'Restricted by System';
      statusColor = colorScheme.error;
    } else {
      statusText = 'Unknown Status';
      statusColor = colorScheme.onSurfaceVariant;
    }
    
    return Text(
      statusText,
      style: theme.textTheme.bodySmall?.copyWith(
        color: statusColor,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildPriorityBadge(BuildContext context) {
    final priority = _getPermissionPriority();
    final colorScheme = Theme.of(context).colorScheme;
    
    Color badgeColor;
    String badgeText;
    
    switch (priority) {
      case PermissionPriority.critical:
        badgeColor = colorScheme.error;
        badgeText = 'CRITICAL';
        break;
      case PermissionPriority.high:
        badgeColor = colorScheme.primary;
        badgeText = 'HIGH';
        break;
      case PermissionPriority.medium:
        badgeColor = colorScheme.tertiary;
        badgeText = 'MEDIUM';
        break;
      case PermissionPriority.low:
        badgeColor = colorScheme.outline;
        badgeText = 'OPTIONAL';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: Text(
        badgeText,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: badgeColor,
        ),
      ),
    );
  }

  Widget _buildWhyNeededSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _getWhyNeededExplanation(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 16,
                color: colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 8),
              Text(
                'How to grant this permission:',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._getInstructionSteps().map((step) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• ',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                Expanded(
                  child: Text(
                    step,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    if (_isPermissionGranted()) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: colorScheme.onPrimaryContainer,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Permission granted successfully!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
    
    return Row(
      children: [
        if (!_isPermanentlyDenied()) ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onRequestPermission,
              icon: Icon(Icons.security),
              label: Text('Grant Permission'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onOpenSettings,
            icon: Icon(Icons.settings),
            label: Text(_isPermanentlyDenied() ? 'Open Settings' : 'Manual Setup'),
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  String _getPermissionTitle() {
    switch (permissionType) {
      case PermissionType.notification:
        return 'Notifications';
      case PermissionType.location:
        return 'Location Access';
      case PermissionType.usageStats:
        return 'Usage Statistics';
      case PermissionType.accessibility:
        return 'Accessibility Service';
      case PermissionType.deviceAdmin:
        return 'Device Administrator';
      case PermissionType.overlay:
        return 'Display Over Other Apps';
      case PermissionType.vpn:
        return 'VPN Connection';
    }
  }

  String _getPermissionExplanation() {
    switch (permissionType) {
      case PermissionType.notification:
        return 'Allows the app to send you helpful notifications about your focus sessions, blocking status, and productivity reminders.';
      case PermissionType.location:
        return 'Enables location-based blocking rules, so you can automatically block distracting apps when you\'re at work, school, or other important places.';
      case PermissionType.usageStats:
        return 'Essential for monitoring which apps you use and for how long. This data helps track your digital wellness and enables the app to block specific applications.';
      case PermissionType.accessibility:
        return 'Critical for detecting when blocked apps are opened and showing blocking screens. This is the core functionality that makes app blocking possible.';
      case PermissionType.deviceAdmin:
        return 'Provides enhanced blocking capabilities and prevents easy bypassing of restrictions. This makes the blocking more secure and effective.';
      case PermissionType.overlay:
        return 'Required to display blocking screens over other apps when they\'re opened. This is what you see when you try to open a blocked app.';
      case PermissionType.vpn:
        return 'Enables website blocking by routing your internet traffic through the app. This allows blocking distracting websites in addition to apps.';
    }
  }

  String _getWhyNeededExplanation() {
    switch (permissionType) {
      case PermissionType.notification:
        return 'Helps you stay informed about your blocking sessions and provides gentle reminders to maintain focus.';
      case PermissionType.location:
        return 'Optional feature that creates smarter blocking rules based on where you are, improving your productivity in specific environments.';
      case PermissionType.usageStats:
        return 'Without this permission, the app cannot see which apps you\'re using or provide usage statistics. This is fundamental to app blocking.';
      case PermissionType.accessibility:
        return 'This is the core permission that enables app blocking. Without it, the app cannot detect when blocked apps are opened or show blocking screens.';
      case PermissionType.deviceAdmin:
        return 'Prevents users from easily uninstalling the app during focus sessions and provides more robust blocking that\'s harder to bypass.';
      case PermissionType.overlay:
        return 'This permission is what allows the app to show you a blocking screen when you try to open a restricted app, redirecting you back to productive activities.';
      case PermissionType.vpn:
        return 'Extends blocking capabilities to websites and online distractions, creating a more comprehensive digital wellness solution.';
    }
  }

  List<String> _getInstructionSteps() {
    switch (permissionType) {
      case PermissionType.notification:
        return [
          'Tap "Grant Permission" button below',
          'Select "Allow" when prompted by the system',
          'You can also manually enable in Settings > Apps > Mind Fence > Notifications'
        ];
      case PermissionType.location:
        return [
          'Tap "Grant Permission" button below',
          'Select "While using the app" or "Allow all the time"',
          'For manual setup: Settings > Apps > Mind Fence > Permissions > Location'
        ];
      case PermissionType.usageStats:
        return [
          'Tap "Grant Permission" to open Usage Access settings',
          'Find "Mind Fence" in the list of apps',
          'Toggle the switch to enable Usage Access',
          'Return to the app - status will update automatically'
        ];
      case PermissionType.accessibility:
        return [
          'Tap "Grant Permission" to open Accessibility settings',
          'Find "Mind Fence" under Downloaded Apps',
          'Tap on it and toggle "Use service" to ON',
          'Confirm by tapping "OK" in the dialog',
          'Return to the app'
        ];
      case PermissionType.deviceAdmin:
        return [
          'Tap "Grant Permission" to open Device Admin settings',
          'Find "Mind Fence" in the list',
          'Tap "Activate" to enable device administration',
          'This adds extra security to prevent easy bypassing'
        ];
      case PermissionType.overlay:
        return [
          'Tap "Grant Permission" to open overlay settings',
          'Find "Mind Fence" in the list of apps',
          'Toggle "Allow display over other apps" to ON',
          'Return to the app'
        ];
      case PermissionType.vpn:
        return [
          'Tap "Grant Permission" button below',
          'Select "OK" when prompted to allow VPN connection',
          'This enables website blocking functionality'
        ];
    }
  }

  IconData _getPermissionIcon() {
    switch (permissionType) {
      case PermissionType.notification:
        return Icons.notifications;
      case PermissionType.location:
        return Icons.location_on;
      case PermissionType.usageStats:
        return Icons.analytics;
      case PermissionType.accessibility:
        return Icons.accessibility;
      case PermissionType.deviceAdmin:
        return Icons.admin_panel_settings;
      case PermissionType.overlay:
        return Icons.layers;
      case PermissionType.vpn:
        return Icons.vpn_lock;
    }
  }

  PermissionPriority _getPermissionPriority() {
    switch (permissionType) {
      case PermissionType.usageStats:
      case PermissionType.accessibility:
        return PermissionPriority.critical;
      case PermissionType.deviceAdmin:
      case PermissionType.overlay:
        return PermissionPriority.high;
      case PermissionType.vpn:
        return PermissionPriority.medium;
      case PermissionType.notification:
      case PermissionType.location:
        return PermissionPriority.low;
    }
  }

  bool _isPermissionGranted() {
    return permissionResult?.isGranted ?? false;
  }

  bool _isPermanentlyDenied() {
    return permissionResult?.isPermanentlyDenied ?? false;
  }
}