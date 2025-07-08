import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'permission_service.dart';

/// Enhanced error handling service for permission-related errors
@injectable
class PermissionErrorHandler {
  
  /// Convert platform exceptions to user-friendly error messages
  PermissionError handlePlatformException(PlatformException exception, PermissionType permissionType) {
    switch (exception.code) {
      case 'PERMISSION_DENIED':
        return _createPermissionDeniedError(permissionType);
      case 'PERMISSION_PERMANENTLY_DENIED':
        return _createPermissionPermanentlyDeniedError(permissionType);
      case 'PERMISSION_RESTRICTED':
        return _createPermissionRestrictedError(permissionType);
      case 'SERVICE_NOT_AVAILABLE':
        return _createServiceNotAvailableError(permissionType);
      case 'FEATURE_NOT_SUPPORTED':
        return _createFeatureNotSupportedError(permissionType);
      default:
        return _createGenericError(exception, permissionType);
    }
  }

  /// Handle general exceptions with contextual information
  PermissionError handleGeneralException(Exception exception, PermissionType permissionType) {
    final errorMessage = exception.toString();
    
    // Check for specific error patterns
    if (errorMessage.contains('timeout')) {
      return _createTimeoutError(permissionType);
    } else if (errorMessage.contains('network') || errorMessage.contains('connection')) {
      return _createNetworkError(permissionType);
    } else if (errorMessage.contains('security') || errorMessage.contains('unauthorized')) {
      return _createSecurityError(permissionType);
    } else {
      return _createGenericError(exception, permissionType);
    }
  }

  /// Get retry recommendations for a specific error
  List<RetryAction> getRetryRecommendations(PermissionError error) {
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

  PermissionError _createPermissionDeniedError(PermissionType permissionType) {
    return PermissionError(
      type: PermissionErrorType.denied,
      permissionType: permissionType,
      title: '${_getPermissionName(permissionType)} Permission Denied',
      message: _getPermissionDeniedMessage(permissionType),
      userFriendlyMessage: _getPermissionDeniedUserMessage(permissionType),
      canRetry: true,
      isRecoverable: true,
    );
  }

  PermissionError _createPermissionPermanentlyDeniedError(PermissionType permissionType) {
    return PermissionError(
      type: PermissionErrorType.permanentlyDenied,
      permissionType: permissionType,
      title: '${_getPermissionName(permissionType)} Permission Blocked',
      message: _getPermissionPermanentlyDeniedMessage(permissionType),
      userFriendlyMessage: _getPermissionPermanentlyDeniedUserMessage(permissionType),
      canRetry: true,
      isRecoverable: true,
      requiresManualIntervention: true,
    );
  }

  PermissionError _createPermissionRestrictedError(PermissionType permissionType) {
    return PermissionError(
      type: PermissionErrorType.restricted,
      permissionType: permissionType,
      title: '${_getPermissionName(permissionType)} Permission Restricted',
      message: 'This permission is restricted by device policy or parental controls.',
      userFriendlyMessage: 'Your device administrator has restricted this permission. Contact your IT department or device owner for assistance.',
      canRetry: false,
      isRecoverable: false,
      requiresManualIntervention: true,
    );
  }

  PermissionError _createServiceNotAvailableError(PermissionType permissionType) {
    return PermissionError(
      type: PermissionErrorType.serviceNotAvailable,
      permissionType: permissionType,
      title: 'Service Temporarily Unavailable',
      message: 'The system service for this permission is not currently available.',
      userFriendlyMessage: 'This feature is temporarily unavailable. Please try again in a few moments.',
      canRetry: true,
      isRecoverable: true,
    );
  }

  PermissionError _createFeatureNotSupportedError(PermissionType permissionType) {
    return PermissionError(
      type: PermissionErrorType.featureNotSupported,
      permissionType: permissionType,
      title: 'Feature Not Supported',
      message: 'This permission is not supported on your device or Android version.',
      userFriendlyMessage: 'This feature is not available on your device. You can continue using the app without this optional feature.',
      canRetry: false,
      isRecoverable: false,
    );
  }

  PermissionError _createTimeoutError(PermissionType permissionType) {
    return PermissionError(
      type: PermissionErrorType.timeout,
      permissionType: permissionType,
      title: 'Request Timed Out',
      message: 'The permission request took too long to complete.',
      userFriendlyMessage: 'The request took too long. Please try again.',
      canRetry: true,
      isRecoverable: true,
    );
  }

  PermissionError _createNetworkError(PermissionType permissionType) {
    return PermissionError(
      type: PermissionErrorType.network,
      permissionType: permissionType,
      title: 'Network Error',
      message: 'A network error occurred while processing the permission request.',
      userFriendlyMessage: 'Please check your internet connection and try again.',
      canRetry: true,
      isRecoverable: true,
    );
  }

  PermissionError _createSecurityError(PermissionType permissionType) {
    return PermissionError(
      type: PermissionErrorType.security,
      permissionType: permissionType,
      title: 'Security Error',
      message: 'A security issue prevented the permission request.',
      userFriendlyMessage: 'There was a security issue. Try reinstalling the app or contact support if the problem persists.',
      canRetry: false,
      isRecoverable: true,
      requiresManualIntervention: true,
    );
  }

  PermissionError _createGenericError(Exception exception, PermissionType permissionType) {
    return PermissionError(
      type: PermissionErrorType.generic,
      permissionType: permissionType,
      title: 'Permission Error',
      message: exception.toString(),
      userFriendlyMessage: 'Something went wrong while requesting the permission. Please try again.',
      canRetry: true,
      isRecoverable: true,
    );
  }

  String _getPermissionName(PermissionType permissionType) {
    switch (permissionType) {
      case PermissionType.notification:
        return 'Notification';
      case PermissionType.location:
        return 'Location';
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

  String _getPermissionDeniedMessage(PermissionType permissionType) {
    switch (permissionType) {
      case PermissionType.notification:
        return 'Notification permission was denied. You won\'t receive app notifications.';
      case PermissionType.location:
        return 'Location permission was denied. Location-based features will be unavailable.';
      case PermissionType.usageStats:
        return 'Usage statistics permission was denied. The app cannot monitor app usage or provide blocking functionality.';
      case PermissionType.accessibility:
        return 'Accessibility service permission was denied. The app cannot detect app launches or show blocking screens.';
      case PermissionType.deviceAdmin:
        return 'Device administrator permission was denied. Enhanced blocking features will be limited.';
      case PermissionType.overlay:
        return 'Display over other apps permission was denied. The app cannot show blocking screens.';
      case PermissionType.vpn:
        return 'VPN permission was denied. Website blocking features will be unavailable.';
    }
  }

  String _getPermissionDeniedUserMessage(PermissionType permissionType) {
    switch (permissionType) {
      case PermissionType.notification:
        return 'To receive helpful reminders and status updates, please allow notification access in your device settings.';
      case PermissionType.location:
        return 'For location-based blocking rules, please enable location access. This feature is optional.';
      case PermissionType.usageStats:
        return 'This permission is essential for app blocking to work. Please enable Usage Access in your device settings.';
      case PermissionType.accessibility:
        return 'This permission is required for the app to detect and block restricted apps. Please enable the accessibility service.';
      case PermissionType.deviceAdmin:
        return 'For stronger blocking protection, please enable device administrator access in your settings.';
      case PermissionType.overlay:
        return 'To show blocking screens when you open restricted apps, please enable "Display over other apps" permission.';
      case PermissionType.vpn:
        return 'To block websites and online distractions, please allow VPN connection when prompted.';
    }
  }

  String _getPermissionPermanentlyDeniedMessage(PermissionType permissionType) {
    return 'You previously chose "Don\'t ask again" for ${_getPermissionName(permissionType).toLowerCase()} permission. Please enable it manually in your device settings.';
  }

  String _getPermissionPermanentlyDeniedUserMessage(PermissionType permissionType) {
    return 'To enable this permission, go to Settings > Apps > Mind Fence > Permissions and turn on ${_getPermissionName(permissionType).toLowerCase()}.';
  }
}

/// Types of permission errors
enum PermissionErrorType {
  denied,
  permanentlyDenied,
  restricted,
  serviceNotAvailable,
  featureNotSupported,
  timeout,
  network,
  security,
  generic,
}

/// Types of retry actions
enum RetryActionType {
  requestAgain,
  openSettings,
  showGuide,
  contactSupport,
  retryLater,
  checkDevice,
  continueWithoutFeature,
  checkConnection,
  reinstallApp,
  restartApp,
}

/// Detailed permission error with user-friendly messaging
class PermissionError {
  final PermissionErrorType type;
  final PermissionType permissionType;
  final String title;
  final String message;
  final String userFriendlyMessage;
  final bool canRetry;
  final bool isRecoverable;
  final bool requiresManualIntervention;

  const PermissionError({
    required this.type,
    required this.permissionType,
    required this.title,
    required this.message,
    required this.userFriendlyMessage,
    required this.canRetry,
    required this.isRecoverable,
    this.requiresManualIntervention = false,
  });

  bool get isCritical {
    return permissionType == PermissionType.usageStats || 
           permissionType == PermissionType.accessibility;
  }

  bool get isOptional {
    return permissionType == PermissionType.notification || 
           permissionType == PermissionType.location;
  }
}

/// Action that can be taken to retry or recover from a permission error
class RetryAction {
  final RetryActionType type;
  final String title;
  final String description;

  const RetryAction({
    required this.type,
    required this.title,
    required this.description,
  });
}