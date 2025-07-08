import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/permission_service.dart';
import '../services/permission_status_service.dart';
import 'permission_guide_widget.dart';

/// Comprehensive permission setup flow widget with enhanced UX
class PermissionSetupFlowWidget extends StatefulWidget {
  final VoidCallback? onCompleted;
  final VoidCallback? onCancelled;
  final bool allowSkipOptional;
  final bool showProgress;
  final PermissionStatusService? permissionStatusService;
  final PermissionService? permissionService;

  const PermissionSetupFlowWidget({
    super.key,
    this.onCompleted,
    this.onCancelled,
    this.allowSkipOptional = true,
    this.showProgress = true,
    this.permissionStatusService,
    this.permissionService,
  });

  @override
  State<PermissionSetupFlowWidget> createState() => _PermissionSetupFlowWidgetState();
}

class _PermissionSetupFlowWidgetState extends State<PermissionSetupFlowWidget> {
  late final PermissionStatusService _permissionStatusService;
  late final PermissionService _permissionService;
  
  Map<PermissionType, PermissionResult> _permissionStatuses = {};
  bool _isLoading = false;
  bool _showOptionalPermissions = false;
  
  // Define permission order by priority
  static const List<PermissionType> _criticalPermissions = [
    PermissionType.usageStats,
    PermissionType.accessibility,
  ];
  
  static const List<PermissionType> _highPriorityPermissions = [
    PermissionType.deviceAdmin,
    PermissionType.overlay,
  ];
  
  static const List<PermissionType> _optionalPermissions = [
    PermissionType.notification,
    PermissionType.location,
    PermissionType.vpn,
  ];

  @override
  void initState() {
    super.initState();
    _permissionStatusService = widget.permissionStatusService ?? context.read<PermissionStatusService>();
    _permissionService = widget.permissionService ?? context.read<PermissionService>();
    
    // Load initial permission statuses
    _loadPermissionStatuses();
    
    // Listen to real-time permission updates
    _permissionStatusService.permissionStatusStream.listen((statuses) {
      if (mounted) {
        setState(() {
          _permissionStatuses = statuses;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Permission Setup'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        leading: widget.onCancelled != null
          ? IconButton(
              icon: Icon(Icons.close),
              onPressed: widget.onCancelled,
            )
          : null,
      ),
      body: _isLoading
        ? _buildLoadingState()
        : _buildPermissionSetupContent(),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Checking permission status...',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionSetupContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          if (widget.showProgress) _buildProgressHeader(),
          _buildIntroductionSection(),
          _buildCriticalPermissionsSection(),
          _buildHighPriorityPermissionsSection(),
          if (_showOptionalPermissions) _buildOptionalPermissionsSection(),
          if (!_showOptionalPermissions) _buildOptionalPermissionsToggle(),
          SizedBox(height: 100), // Space for bottom navigation
        ],
      ),
    );
  }

  Widget _buildProgressHeader() {
    final totalPermissions = _criticalPermissions.length + 
                            _highPriorityPermissions.length + 
                            (_showOptionalPermissions ? _optionalPermissions.length : 0);
    
    final grantedPermissions = _permissionStatuses.values
        .where((result) => result.isGranted)
        .length;
    
    final progress = totalPermissions > 0 ? grantedPermissions / totalPermissions : 0.0;
    
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Setup Progress',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '$grantedPermissions of $totalPermissions',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            progress == 1.0 
              ? 'All permissions granted! 🎉'
              : '${(progress * 100).round()}% complete',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroductionSection() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Why These Permissions Are Needed',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Mind Fence needs specific permissions to effectively block distracting apps and websites. These permissions are used solely for blocking functionality and protecting your privacy.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Critical permissions are required for core functionality, while optional permissions enhance your experience.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCriticalPermissionsSection() {
    return _buildPermissionSection(
      title: 'Critical Permissions',
      subtitle: 'Required for core app functionality',
      icon: Icons.warning,
      iconColor: Theme.of(context).colorScheme.error,
      permissions: _criticalPermissions,
    );
  }

  Widget _buildHighPriorityPermissionsSection() {
    return _buildPermissionSection(
      title: 'Enhanced Features',
      subtitle: 'Recommended for better blocking',
      icon: Icons.star,
      iconColor: Theme.of(context).colorScheme.primary,
      permissions: _highPriorityPermissions,
    );
  }

  Widget _buildOptionalPermissionsSection() {
    return _buildPermissionSection(
      title: 'Optional Features',
      subtitle: 'Additional functionality',
      icon: Icons.tune,
      iconColor: Theme.of(context).colorScheme.tertiary,
      permissions: _optionalPermissions,
    );
  }

  Widget _buildPermissionSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required List<PermissionType> permissions,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        ...permissions.map((permissionType) => PermissionGuideWidget(
          permissionType: permissionType,
          permissionResult: _permissionStatuses[permissionType],
          onRequestPermission: () => _requestPermission(permissionType),
          onOpenSettings: () => _openPermissionSettings(permissionType),
          showDetailedInstructions: true,
          showPriorityBadge: true,
        )),
      ],
    );
  }

  Widget _buildOptionalPermissionsToggle() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextButton.icon(
        onPressed: () {
          setState(() {
            _showOptionalPermissions = true;
          });
        },
        icon: Icon(Icons.expand_more),
        label: Text('Show Optional Permissions'),
        style: TextButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    final criticalGranted = _areCriticalPermissionsGranted();
    final allGranted = _areAllPermissionsGranted();
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (criticalGranted && !allGranted) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.onCompleted,
                icon: Icon(Icons.check),
                label: Text('Continue with Current Setup'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
            SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _requestAllMissingPermissions,
                icon: Icon(Icons.security),
                label: Text('Grant All Permissions'),
              ),
            ),
          ] else if (allGranted) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.onCompleted,
                icon: Icon(Icons.celebration),
                label: Text('Setup Complete!'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _requestAllMissingPermissions,
                icon: Icon(Icons.security),
                label: Text('Grant Required Permissions'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
            if (widget.allowSkipOptional) ...[
              SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: widget.onCancelled,
                  child: Text('Skip for Now'),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Future<void> _loadPermissionStatuses() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final statuses = await _permissionStatusService.checkAllPermissionStatus();
      setState(() {
        _permissionStatuses = statuses;
      });
    } catch (e) {
      debugPrint('Error loading permission statuses: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _requestPermission(PermissionType type) async {
    try {
      await _permissionStatusService.requestPermission(type);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to request permission: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _openPermissionSettings(PermissionType type) async {
    try {
      await _permissionService.openPermissionSettings(type);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open settings: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _requestAllMissingPermissions() async {
    final allPermissions = [
      ..._criticalPermissions,
      ..._highPriorityPermissions,
      if (_showOptionalPermissions) ..._optionalPermissions,
    ];
    
    for (final permission in allPermissions) {
      final result = _permissionStatuses[permission];
      if (result?.isGranted != true) {
        await _requestPermission(permission);
        // Small delay between requests to improve UX
        await Future.delayed(Duration(milliseconds: 500));
      }
    }
  }

  bool _areCriticalPermissionsGranted() {
    return _criticalPermissions.every((permission) => 
      _permissionStatuses[permission]?.isGranted == true
    );
  }

  bool _areAllPermissionsGranted() {
    final allPermissions = [
      ..._criticalPermissions,
      ..._highPriorityPermissions,
      if (_showOptionalPermissions) ..._optionalPermissions,
    ];
    
    return allPermissions.every((permission) => 
      _permissionStatuses[permission]?.isGranted == true
    );
  }
}