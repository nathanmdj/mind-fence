import 'package:flutter/material.dart';
import '../services/permission_error_handler.dart';
import '../services/permission_service.dart';

/// Widget that displays permission errors with contextual messages and retry actions
class PermissionErrorWidget extends StatelessWidget {
  final PermissionResult permissionResult;
  final Function(RetryActionType)? onRetryAction;
  final VoidCallback? onDismiss;
  final bool showDismissButton;
  final bool showDetailedInfo;

  const PermissionErrorWidget({
    super.key,
    required this.permissionResult,
    this.onRetryAction,
    this.onDismiss,
    this.showDismissButton = true,
    this.showDetailedInfo = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!permissionResult.hasError || permissionResult.permissionError == null) {
      return SizedBox.shrink();
    }

    final error = permissionResult.permissionError!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Error header
            Row(
              children: [
                Icon(
                  _getErrorIcon(error.type),
                  color: _getErrorColor(error.type, colorScheme),
                  size: 24,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        error.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _getErrorColor(error.type, colorScheme),
                        ),
                      ),
                      if (error.isCritical) ...[
                        SizedBox(height: 4),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colorScheme.error.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            'CRITICAL',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (showDismissButton)
                  IconButton(
                    onPressed: onDismiss,
                    icon: Icon(Icons.close),
                    iconSize: 20,
                  ),
              ],
            ),

            SizedBox(height: 12),

            // User-friendly error message
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getErrorColor(error.type, colorScheme).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                error.userFriendlyMessage,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ),

            if (showDetailedInfo) ...[
              SizedBox(height: 12),
              ExpansionTile(
                title: Text(
                  'Technical Details',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        error.message,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            SizedBox(height: 16),

            // Retry actions
            _buildRetryActions(context, error),
          ],
        ),
      ),
    );
  }

  Widget _buildRetryActions(BuildContext context, PermissionError error) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // We'll simulate getting retry recommendations (in real implementation, this would come from the error handler)
    final retryActions = _getRetryRecommendations(error);

    if (retryActions.isEmpty) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What you can do:',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8),
        ...retryActions.asMap().entries.map((entry) {
          final index = entry.key;
          final action = entry.value;
          final isPrimary = index == 0;

          return Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: SizedBox(
              width: double.infinity,
              child: isPrimary
                  ? ElevatedButton.icon(
                      onPressed: () => onRetryAction?.call(action.type),
                      icon: Icon(_getRetryActionIcon(action.type)),
                      label: Text(action.title),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                      ),
                    )
                  : OutlinedButton.icon(
                      onPressed: () => onRetryAction?.call(action.type),
                      icon: Icon(_getRetryActionIcon(action.type)),
                      label: Text(action.title),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.primary,
                      ),
                    ),
            ),
          );
        }).take(3), // Limit to 3 actions to avoid overwhelming the user
      ],
    );
  }

  IconData _getErrorIcon(PermissionErrorType type) {
    switch (type) {
      case PermissionErrorType.denied:
        return Icons.block;
      case PermissionErrorType.permanentlyDenied:
        return Icons.settings;
      case PermissionErrorType.restricted:
        return Icons.admin_panel_settings;
      case PermissionErrorType.serviceNotAvailable:
        return Icons.warning;
      case PermissionErrorType.featureNotSupported:
        return Icons.info;
      case PermissionErrorType.timeout:
        return Icons.schedule;
      case PermissionErrorType.network:
        return Icons.wifi_off;
      case PermissionErrorType.security:
        return Icons.security;
      case PermissionErrorType.generic:
        return Icons.error;
    }
  }

  Color _getErrorColor(PermissionErrorType type, ColorScheme colorScheme) {
    switch (type) {
      case PermissionErrorType.denied:
      case PermissionErrorType.permanentlyDenied:
      case PermissionErrorType.restricted:
      case PermissionErrorType.security:
        return colorScheme.error;
      case PermissionErrorType.serviceNotAvailable:
      case PermissionErrorType.timeout:
      case PermissionErrorType.network:
        return colorScheme.secondary;
      case PermissionErrorType.featureNotSupported:
        return colorScheme.tertiary;
      case PermissionErrorType.generic:
        return colorScheme.outline;
    }
  }

  IconData _getRetryActionIcon(RetryActionType type) {
    switch (type) {
      case RetryActionType.requestAgain:
        return Icons.refresh;
      case RetryActionType.openSettings:
        return Icons.settings;
      case RetryActionType.showGuide:
        return Icons.help;
      case RetryActionType.contactSupport:
        return Icons.support;
      case RetryActionType.retryLater:
        return Icons.schedule;
      case RetryActionType.checkDevice:
        return Icons.phone_android;
      case RetryActionType.continueWithoutFeature:
        return Icons.skip_next;
      case RetryActionType.checkConnection:
        return Icons.wifi;
      case RetryActionType.reinstallApp:
        return Icons.download;
      case RetryActionType.restartApp:
        return Icons.restart_alt;
    }
  }

  // Simplified retry recommendations (in real implementation, this would come from PermissionErrorHandler)
  List<RetryAction> _getRetryRecommendations(PermissionError error) {
    switch (error.type) {
      case PermissionErrorType.denied:
        return [
          RetryAction(
            type: RetryActionType.requestAgain,
            title: 'Try Again',
            description: 'Request the permission again',
          ),
          RetryAction(
            type: RetryActionType.openSettings,
            title: 'Open Settings',
            description: 'Manually enable in system settings',
          ),
        ];
      
      case PermissionErrorType.permanentlyDenied:
        return [
          RetryAction(
            type: RetryActionType.openSettings,
            title: 'Open Settings',
            description: 'Enable permission in system settings',
          ),
          RetryAction(
            type: RetryActionType.showGuide,
            title: 'Show Guide',
            description: 'View step-by-step instructions',
          ),
        ];
      
      case PermissionErrorType.restricted:
        return [
          RetryAction(
            type: RetryActionType.contactSupport,
            title: 'Contact Support',
            description: 'Get help with device restrictions',
          ),
        ];
      
      case PermissionErrorType.serviceNotAvailable:
        return [
          RetryAction(
            type: RetryActionType.retryLater,
            title: 'Retry Later',
            description: 'Try again in a few moments',
          ),
          RetryAction(
            type: RetryActionType.checkDevice,
            title: 'Check Device',
            description: 'Ensure device supports this feature',
          ),
        ];
      
      case PermissionErrorType.featureNotSupported:
        return [
          RetryAction(
            type: RetryActionType.continueWithoutFeature,
            title: 'Continue Without',
            description: 'Skip this optional feature',
          ),
        ];
      
      case PermissionErrorType.timeout:
        return [
          RetryAction(
            type: RetryActionType.requestAgain,
            title: 'Try Again',
            description: 'Retry the permission request',
          ),
        ];
      
      case PermissionErrorType.network:
        return [
          RetryAction(
            type: RetryActionType.checkConnection,
            title: 'Check Connection',
            description: 'Verify internet connectivity',
          ),
          RetryAction(
            type: RetryActionType.retryLater,
            title: 'Retry Later',
            description: 'Try again when connection is stable',
          ),
        ];
      
      case PermissionErrorType.security:
        return [
          RetryAction(
            type: RetryActionType.reinstallApp,
            title: 'Reinstall App',
            description: 'Reinstall the app to fix security issues',
          ),
          RetryAction(
            type: RetryActionType.contactSupport,
            title: 'Contact Support',
            description: 'Get help with security-related issues',
          ),
        ];
      
      case PermissionErrorType.generic:
        return [
          RetryAction(
            type: RetryActionType.requestAgain,
            title: 'Try Again',
            description: 'Retry the operation',
          ),
          RetryAction(
            type: RetryActionType.restartApp,
            title: 'Restart App',
            description: 'Close and reopen the app',
          ),
        ];
    }
  }
}

/// Compact version of the permission error widget for inline display
class PermissionErrorBanner extends StatelessWidget {
  final PermissionResult permissionResult;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const PermissionErrorBanner({
    super.key,
    required this.permissionResult,
    this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (!permissionResult.hasError || permissionResult.permissionError == null) {
      return SizedBox.shrink();
    }

    final error = permissionResult.permissionError!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: _getErrorColor(error.type, colorScheme).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  _getErrorIcon(error.type),
                  color: _getErrorColor(error.type, colorScheme),
                  size: 20,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        error.title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _getErrorColor(error.type, colorScheme),
                        ),
                      ),
                      Text(
                        error.userFriendlyMessage,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (onTap != null)
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                if (onDismiss != null)
                  IconButton(
                    onPressed: onDismiss,
                    icon: Icon(Icons.close),
                    iconSize: 16,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getErrorIcon(PermissionErrorType type) {
    // Same implementation as in PermissionErrorWidget
    switch (type) {
      case PermissionErrorType.denied:
        return Icons.block;
      case PermissionErrorType.permanentlyDenied:
        return Icons.settings;
      case PermissionErrorType.restricted:
        return Icons.admin_panel_settings;
      case PermissionErrorType.serviceNotAvailable:
        return Icons.warning;
      case PermissionErrorType.featureNotSupported:
        return Icons.info;
      case PermissionErrorType.timeout:
        return Icons.schedule;
      case PermissionErrorType.network:
        return Icons.wifi_off;
      case PermissionErrorType.security:
        return Icons.security;
      case PermissionErrorType.generic:
        return Icons.error;
    }
  }

  Color _getErrorColor(PermissionErrorType type, ColorScheme colorScheme) {
    // Same implementation as in PermissionErrorWidget
    switch (type) {
      case PermissionErrorType.denied:
      case PermissionErrorType.permanentlyDenied:
      case PermissionErrorType.restricted:
      case PermissionErrorType.security:
        return colorScheme.error;
      case PermissionErrorType.serviceNotAvailable:
      case PermissionErrorType.timeout:
      case PermissionErrorType.network:
        return colorScheme.secondary;
      case PermissionErrorType.featureNotSupported:
        return colorScheme.tertiary;
      case PermissionErrorType.generic:
        return colorScheme.outline;
    }
  }
}