import 'package:flutter/material.dart';
import '../services/permission_service.dart';

/// Visual indicator widget for permission status with progress and animations
class PermissionStatusIndicator extends StatefulWidget {
  final PermissionType permissionType;
  final PermissionResult? permissionResult;
  final bool showLabel;
  final bool showProgress;
  final bool animated;
  final double size;
  final VoidCallback? onTap;

  const PermissionStatusIndicator({
    super.key,
    required this.permissionType,
    this.permissionResult,
    this.showLabel = true,
    this.showProgress = false,
    this.animated = true,
    this.size = 48,
    this.onTap,
  });

  @override
  State<PermissionStatusIndicator> createState() => _PermissionStatusIndicatorState();
}

class _PermissionStatusIndicatorState extends State<PermissionStatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (widget.animated) {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(PermissionStatusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Trigger animation when permission status changes
    if (widget.animated && 
        oldWidget.permissionResult?.isGranted != widget.permissionResult?.isGranted) {
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: widget.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.animated)
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: _buildIndicator(context),
                );
              },
            )
          else
            _buildIndicator(context),
          
          if (widget.showLabel) ...[
            SizedBox(height: 8),
            Text(
              _getPermissionLabel(),
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIndicator(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final status = _getPermissionStatus();

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _getStatusColor(status, colorScheme),
        border: Border.all(
          color: _getStatusBorderColor(status, colorScheme),
          width: 2,
        ),
        boxShadow: [
          if (status == PermissionStatus.granted)
            BoxShadow(
              color: _getStatusColor(status, colorScheme).withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 2,
            ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Progress indicator for pending status
          if (widget.showProgress && status == PermissionStatus.pending)
            SizedBox(
              width: widget.size - 8,
              height: widget.size - 8,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  colorScheme.onSurface,
                ),
              ),
            ),

          // Main status icon
          Icon(
            _getStatusIcon(status),
            size: widget.size * 0.4,
            color: _getStatusIconColor(status, colorScheme),
          ),

          // Overlay for critical permissions
          if (_isCriticalPermission() && status != PermissionStatus.granted)
            Positioned(
              top: 2,
              right: 2,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: colorScheme.error,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.surface,
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.priority_high,
                  size: 8,
                  color: colorScheme.onError,
                ),
              ),
            ),
        ],
      ),
    );
  }

  PermissionStatus _getPermissionStatus() {
    final result = widget.permissionResult;
    
    if (result == null) {
      return PermissionStatus.unknown;
    }
    
    if (result.isGranted) {
      return PermissionStatus.granted;
    } else if (result.isPermanentlyDenied) {
      return PermissionStatus.permanentlyDenied;
    } else if (result.isDenied) {
      return PermissionStatus.denied;
    } else if (result.isRestricted) {
      return PermissionStatus.restricted;
    } else {
      return PermissionStatus.pending;
    }
  }

  Color _getStatusColor(PermissionStatus status, ColorScheme colorScheme) {
    switch (status) {
      case PermissionStatus.granted:
        return colorScheme.primaryContainer;
      case PermissionStatus.denied:
        return colorScheme.errorContainer;
      case PermissionStatus.permanentlyDenied:
        return colorScheme.errorContainer;
      case PermissionStatus.restricted:
        return colorScheme.secondaryContainer;
      case PermissionStatus.pending:
        return colorScheme.surfaceVariant;
      case PermissionStatus.unknown:
        return colorScheme.surfaceVariant;
    }
  }

  Color _getStatusBorderColor(PermissionStatus status, ColorScheme colorScheme) {
    switch (status) {
      case PermissionStatus.granted:
        return colorScheme.primary;
      case PermissionStatus.denied:
        return colorScheme.error;
      case PermissionStatus.permanentlyDenied:
        return colorScheme.error;
      case PermissionStatus.restricted:
        return colorScheme.secondary;
      case PermissionStatus.pending:
        return colorScheme.outline;
      case PermissionStatus.unknown:
        return colorScheme.outline;
    }
  }

  Color _getStatusIconColor(PermissionStatus status, ColorScheme colorScheme) {
    switch (status) {
      case PermissionStatus.granted:
        return colorScheme.onPrimaryContainer;
      case PermissionStatus.denied:
        return colorScheme.onErrorContainer;
      case PermissionStatus.permanentlyDenied:
        return colorScheme.onErrorContainer;
      case PermissionStatus.restricted:
        return colorScheme.onSecondaryContainer;
      case PermissionStatus.pending:
        return colorScheme.onSurfaceVariant;
      case PermissionStatus.unknown:
        return colorScheme.onSurfaceVariant;
    }
  }

  IconData _getStatusIcon(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return Icons.check;
      case PermissionStatus.denied:
        return Icons.close;
      case PermissionStatus.permanentlyDenied:
        return Icons.settings;
      case PermissionStatus.restricted:
        return Icons.admin_panel_settings;
      case PermissionStatus.pending:
        return _getPermissionIcon();
      case PermissionStatus.unknown:
        return Icons.help_outline;
    }
  }

  IconData _getPermissionIcon() {
    switch (widget.permissionType) {
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

  String _getPermissionLabel() {
    switch (widget.permissionType) {
      case PermissionType.notification:
        return 'Notifications';
      case PermissionType.location:
        return 'Location';
      case PermissionType.usageStats:
        return 'Usage Stats';
      case PermissionType.accessibility:
        return 'Accessibility';
      case PermissionType.deviceAdmin:
        return 'Device Admin';
      case PermissionType.overlay:
        return 'Overlay';
      case PermissionType.vpn:
        return 'VPN';
    }
  }

  bool _isCriticalPermission() {
    return widget.permissionType == PermissionType.usageStats ||
           widget.permissionType == PermissionType.accessibility;
  }
}

/// Enumeration for permission status display
enum PermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  pending,
  unknown,
}

/// Compact horizontal permission status list
class PermissionStatusList extends StatelessWidget {
  final Map<PermissionType, PermissionResult> permissionResults;
  final Function(PermissionType)? onPermissionTap;
  final bool showLabels;
  final bool animated;

  const PermissionStatusList({
    super.key,
    required this.permissionResults,
    this.onPermissionTap,
    this.showLabels = false,
    this.animated = true,
  });

  @override
  Widget build(BuildContext context) {
    final criticalPermissions = [
      PermissionType.usageStats,
      PermissionType.accessibility,
    ];
    
    final otherPermissions = [
      PermissionType.deviceAdmin,
      PermissionType.overlay,
      PermissionType.notification,
      PermissionType.location,
      PermissionType.vpn,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (criticalPermissions.any(permissionResults.containsKey)) ...[
          _buildPermissionGroup(
            context,
            'Critical Permissions',
            criticalPermissions.where(permissionResults.containsKey),
          ),
          SizedBox(height: 16),
        ],
        
        if (otherPermissions.any(permissionResults.containsKey))
          _buildPermissionGroup(
            context,
            'Additional Permissions',
            otherPermissions.where(permissionResults.containsKey),
          ),
      ],
    );
  }

  Widget _buildPermissionGroup(
    BuildContext context,
    String title,
    Iterable<PermissionType> permissions,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: permissions.map((type) {
            return PermissionStatusIndicator(
              permissionType: type,
              permissionResult: permissionResults[type],
              showLabel: showLabels,
              animated: animated,
              size: 40,
              onTap: () => onPermissionTap?.call(type),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Progress indicator for overall permission setup
class PermissionSetupProgress extends StatefulWidget {
  final Map<PermissionType, PermissionResult> permissionResults;
  final bool showPercentage;
  final bool animated;

  const PermissionSetupProgress({
    super.key,
    required this.permissionResults,
    this.showPercentage = true,
    this.animated = true,
  });

  @override
  State<PermissionSetupProgress> createState() => _PermissionSetupProgressState();
}

class _PermissionSetupProgressState extends State<PermissionSetupProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: _calculateProgress(),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (widget.animated) {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(PermissionSetupProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    final newProgress = _calculateProgress();
    if (widget.animated && newProgress != _progressAnimation.value) {
      _progressAnimation = Tween<double>(
        begin: _progressAnimation.value,
        end: newProgress,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ));
      
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final progress = _calculateProgress();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Permission Setup Progress',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (widget.showPercentage)
              widget.animated
                  ? AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) {
                        return Text(
                          '${(_progressAnimation.value * 100).round()}%',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        );
                      },
                    )
                  : Text(
                      '${(progress * 100).round()}%',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
          ],
        ),
        SizedBox(height: 8),
        widget.animated
            ? AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return LinearProgressIndicator(
                    value: _progressAnimation.value,
                    backgroundColor: colorScheme.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress == 1.0 ? Colors.green : colorScheme.primary,
                    ),
                  );
                },
              )
            : LinearProgressIndicator(
                value: progress,
                backgroundColor: colorScheme.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress == 1.0 ? Colors.green : colorScheme.primary,
                ),
              ),
        SizedBox(height: 8),
        Text(
          _getProgressDescription(progress),
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  double _calculateProgress() {
    if (widget.permissionResults.isEmpty) return 0.0;
    
    final grantedCount = widget.permissionResults.values
        .where((result) => result.isGranted)
        .length;
    
    return grantedCount / widget.permissionResults.length;
  }

  String _getProgressDescription(double progress) {
    final grantedCount = widget.permissionResults.values
        .where((result) => result.isGranted)
        .length;
    final totalCount = widget.permissionResults.length;
    
    if (progress == 1.0) {
      return 'All permissions granted! 🎉';
    } else if (progress >= 0.8) {
      return 'Almost complete! $grantedCount of $totalCount permissions granted.';
    } else if (progress >= 0.5) {
      return 'Good progress! $grantedCount of $totalCount permissions granted.';
    } else if (progress > 0) {
      return 'Getting started... $grantedCount of $totalCount permissions granted.';
    } else {
      return 'No permissions granted yet. Tap to get started.';
    }
  }
}