import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/permission_setup_flow_widget.dart';
import '../../../../core/widgets/permission_status_indicator.dart';
import '../../../../core/services/permission_service.dart';
import '../../../../core/services/permission_status_service.dart';
import '../../../../core/di/injection_container.dart';
import '../bloc/block_setup_bloc.dart';
import '../bloc/block_setup_event.dart';
import '../bloc/block_setup_state.dart';
import '../../../../shared/domain/entities/blocked_app.dart';
import '../widgets/searchable_apps_modal.dart';

class BlockSetupPage extends StatelessWidget {
  const BlockSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<BlockSetupBloc>()..add(LoadInstalledApps()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Block Setup',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            BlocBuilder<BlockSetupBloc, BlockSetupState>(
              builder: (context, state) {
                return IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    _showSearchDialog(context);
                  },
                );
              },
            ),
          ],
        ),
        body: BlocConsumer<BlockSetupBloc, BlockSetupState>(
          listener: (context, state) {
            if (state is BlockSetupError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            } else if (state is PermissionRequesting) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Requesting permissions...')),
              );
            } else if (state is PermissionDenied) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Permission denied: ${state.message}')),
              );
            } else if (state is PermissionSequentialRequesting) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Requesting ${state.currentPermission} (${state.currentStep}/${state.totalSteps})'),
                  duration: const Duration(seconds: 3),
                ),
              );
            } else if (state is PermissionSequentialCompleted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All permissions granted successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is BlockSetupLoading) {
              return _buildSkeletonScreen();
            }
            
            if (state is BlockSetupLoaded) {
              return _buildLoadedContent(context, state);
            }
            
            if (state is BlockSetupError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(state.message),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<BlockSetupBloc>().add(LoadInstalledApps());
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            
            return const Center(child: CircularProgressIndicator());
          },
        ),
        floatingActionButton: BlocBuilder<BlockSetupBloc, BlockSetupState>(
          builder: (context, state) {
            if (state is BlockSetupLoaded) {
              final needsPermissions = !state.hasUsageStatsPermission || 
                                       !state.hasAccessibilityPermission ||
                                       !state.hasDeviceAdminPermission ||
                                       !state.hasOverlayPermission;
              
              if (needsPermissions) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FloatingActionButton.extended(
                              onPressed: () {
                                context.read<BlockSetupBloc>().add(RequestPermissions());
                              },
                              icon: const Icon(Icons.security),
                              label: const Text('Step by Step'),
                              backgroundColor: AppColors.warning,
                              heroTag: 'step_permissions',
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: FloatingActionButton.extended(
                              onPressed: () {
                                _showPermissionOptionsDialog(context);
                              },
                              icon: const Icon(Icons.settings),
                              label: const Text('App Settings'),
                              backgroundColor: AppColors.primary,
                              heroTag: 'app_settings',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              } else {
                return FloatingActionButton.extended(
                  onPressed: () {
                    if (state.isBlocking) {
                      context.read<BlockSetupBloc>().add(StopBlocking());
                    } else {
                      context.read<BlockSetupBloc>().add(StartBlocking());
                    }
                  },
                  icon: Icon(
                    state.isBlocking ? Icons.stop : Icons.play_arrow,
                  ),
                  label: Text(
                    state.isBlocking ? 'Stop Blocking' : 'Start Blocking',
                  ),
                  backgroundColor: state.isBlocking ? AppColors.error : AppColors.primary,
                );
              }
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }

  Widget _buildSkeletonScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Permission Status Skeleton
          _buildPermissionStatusSkeleton(),
          const SizedBox(height: 24),
          
          // Blocked Apps Skeleton
          _buildBlockedAppsSkeleton(),
          const SizedBox(height: 24),
          
          // Available Apps Skeleton
          _buildAvailableAppsSkeleton(),
        ],
      ),
    );
  }

  Widget _buildPermissionStatusSkeleton() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SkeletonBox(width: 150, height: 24),
          const SizedBox(height: 8),
          _SkeletonBox(width: double.infinity, height: 4),
          const SizedBox(height: 16),
          
          // Permission groups skeleton
          for (int i = 0; i < 2; i++) ...[
            Row(
              children: [
                _SkeletonBox(width: 16, height: 16),
                const SizedBox(width: 6),
                _SkeletonBox(width: 120, height: 16),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (int j = 0; j < 2; j++)
                  _SkeletonBox(width: 80, height: 32, borderRadius: 16),
              ],
            ),
            const SizedBox(height: 12),
          ],
          
          Row(
            children: [
              _SkeletonBox(width: 24, height: 24),
              const SizedBox(width: 8),
              _SkeletonBox(width: 100, height: 16),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedAppsSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _SkeletonBox(width: 140, height: 24),
            const Spacer(),
            _SkeletonBox(width: 60, height: 20, borderRadius: 12),
          ],
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            children: [
              for (int i = 0; i < 3; i++) ...[
                _buildAppItemSkeleton(),
                if (i < 2) const Divider(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvailableAppsSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _SkeletonBox(width: 120, height: 24),
            const Spacer(),
            _SkeletonBox(width: 60, height: 16),
          ],
        ),
        const SizedBox(height: 8),
        _SkeletonBox(width: 200, height: 16),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            children: [
              for (int i = 0; i < 5; i++) ...[
                _buildAppItemSkeleton(),
                if (i < 4) const Divider(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppItemSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          _SkeletonBox(width: 40, height: 40, borderRadius: 8),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonBox(width: double.infinity, height: 16),
                const SizedBox(height: 4),
                _SkeletonBox(width: 150, height: 12),
              ],
            ),
          ),
          _SkeletonBox(width: 50, height: 30, borderRadius: 15),
        ],
      ),
    );
  }

  Widget _buildLoadedContent(BuildContext context, BlockSetupLoaded state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Permission Status
          _EnhancedPermissionStatusSection(state, onShowSetupGuide: () => _showEnhancedPermissionSetup(context)),
          const SizedBox(height: 24),
          
          // Currently Blocked Apps
          _BlockedAppsSection(state.blockedApps),
          const SizedBox(height: 24),
          
          // Available Apps Section with pagination support
          _EnhancedAvailableAppsSection(state),
        ],
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Apps'),
        content: TextField(
          onChanged: (query) {
            context.read<BlockSetupBloc>().add(FilterApps(query));
          },
          decoration: const InputDecoration(
            hintText: 'Search apps...',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
  
  void _showPermissionOptionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Management'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose how you want to grant permissions:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.auto_awesome, color: AppColors.primary),
                    title: const Text('Enhanced Setup (Recommended)'),
                    subtitle: const Text('Step-by-step guide with detailed instructions'),
                    contentPadding: EdgeInsets.zero,
                    onTap: () {
                      Navigator.pop(context);
                      _showEnhancedPermissionSetup(context);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.settings, color: AppColors.secondary),
              title: const Text('Quick Settings'),
              subtitle: const Text('Direct access to app settings'),
              contentPadding: EdgeInsets.zero,
              onTap: () {
                Navigator.pop(context);
                context.read<BlockSetupBloc>().add(const RequestAllPermissions());
              },
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.open_in_new, color: AppColors.secondary),
              title: const Text('System Settings'),
              subtitle: const Text('Manual permission management'),
              contentPadding: EdgeInsets.zero,
              onTap: () {
                Navigator.pop(context);
                context.read<BlockSetupBloc>().add(const OpenAppSettings());
              },
            ),
            const SizedBox(height: 12),
            Text(
              'Note: You\'ll need to return to Mind Fence after granting permissions.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showEnhancedPermissionSetup(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PermissionSetupFlowWidget(
          onCompleted: () {
            Navigator.pop(context);
            // Refresh permission status
            context.read<BlockSetupBloc>().add(CheckPermissions());
          },
          onCancelled: () {
            Navigator.pop(context);
          },
          showProgress: true,
          allowSkipOptional: true,
          permissionStatusService: getIt<PermissionStatusService>(),
          permissionService: getIt<PermissionService>(),
        ),
        fullscreenDialog: true,
      ),
    );
  }
}

class _EnhancedPermissionStatusSection extends StatelessWidget {
  final BlockSetupLoaded state;
  final VoidCallback? onShowSetupGuide;
  
  const _EnhancedPermissionStatusSection(this.state, {this.onShowSetupGuide});

  @override
  Widget build(BuildContext context) {
    final criticalPermissions = [
      PermissionType.usageStats,
      PermissionType.accessibility,
    ];
    
    final highPriorityPermissions = [
      PermissionType.deviceAdmin,
      PermissionType.overlay,
    ];
    
    final grantedCritical = criticalPermissions.where((type) => 
      _isPermissionGranted(type)).length;
    final grantedHigh = highPriorityPermissions.where((type) => 
      _isPermissionGranted(type)).length;
    
    final totalGranted = grantedCritical + grantedHigh;
    final totalPermissions = criticalPermissions.length + highPriorityPermissions.length;
    final progress = totalPermissions > 0 ? totalGranted / totalPermissions : 0.0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Permission Status',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '$totalGranted/$totalPermissions',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: progress == 1.0 ? AppColors.success : AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(
              progress == 1.0 ? AppColors.success : AppColors.warning,
            ),
          ),
          const SizedBox(height: 16),
          
          // Critical permissions
          _buildPermissionGroup(
            context,
            'Critical Permissions',
            'Required for core functionality',
            Icons.warning,
            AppColors.error,
            criticalPermissions,
          ),
          
          const SizedBox(height: 12),
          
          // High priority permissions
          _buildPermissionGroup(
            context,
            'Enhanced Features',
            'Recommended for better blocking',
            Icons.star,
            AppColors.primary,
            highPriorityPermissions,
          ),
          
          const SizedBox(height: 16),
          
          // Blocking status
          Row(
            children: [
              Icon(
                state.isBlocking ? Icons.shield : Icons.shield_outlined,
                color: state.isBlocking ? AppColors.success : AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                state.isBlocking ? 'Blocking Active' : 'Blocking Inactive',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: state.isBlocking ? AppColors.success : AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (progress < 1.0)
                TextButton.icon(
                  onPressed: onShowSetupGuide,
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  label: const Text('Setup Guide'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionGroup(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color iconColor,
    List<PermissionType> permissions,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 16),
            const SizedBox(width: 6),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: permissions.map((type) => _buildPermissionChip(
            context, 
            type, 
            _isPermissionGranted(type),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildPermissionChip(
    BuildContext context,
    PermissionType type,
    bool isGranted,
  ) {
    final name = _getPermissionName(type);
    
    return Chip(
      avatar: Icon(
        isGranted ? Icons.check_circle : Icons.error,
        color: isGranted ? AppColors.success : AppColors.error,
        size: 16,
      ),
      label: Text(
        name,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      backgroundColor: isGranted 
        ? AppColors.success.withOpacity(0.1)
        : AppColors.error.withOpacity(0.1),
      side: BorderSide(
        color: isGranted ? AppColors.success : AppColors.error,
        width: 0.5,
      ),
      visualDensity: VisualDensity.compact,
    );
  }


  bool _isPermissionGranted(PermissionType type) {
    switch (type) {
      case PermissionType.usageStats:
        return state.hasUsageStatsPermission;
      case PermissionType.accessibility:
        return state.hasAccessibilityPermission;
      case PermissionType.deviceAdmin:
        return state.hasDeviceAdminPermission;
      case PermissionType.overlay:
        return state.hasOverlayPermission;
      default:
        return false;
    }
  }

  String _getPermissionName(PermissionType type) {
    switch (type) {
      case PermissionType.usageStats:
        return 'Usage Stats';
      case PermissionType.accessibility:
        return 'Accessibility';
      case PermissionType.deviceAdmin:
        return 'Device Admin';
      case PermissionType.overlay:
        return 'Overlay';
      default:
        return type.toString();
    }
  }
}

class _BlockedAppsSection extends StatelessWidget {
  final List<BlockedApp> blockedApps;
  
  const _BlockedAppsSection(this.blockedApps);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Currently Blocked',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${blockedApps.length} apps',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (blockedApps.isEmpty)
          AppCard(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.apps,
                      size: 48,
                      color: AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No apps blocked yet',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select apps below to start blocking them',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          AppCard(
            child: Column(
              children: [
                ...blockedApps.take(3).map((app) => Column(
                  children: [
                    _buildAppListItem(
                      context,
                      app.name,
                      app.packageName,
                      Icons.apps,
                      AppColors.error,
                      app.isBlocked,
                      app,
                    ),
                    if (app != blockedApps.take(3).last) const Divider(),
                  ],
                )),
                if (blockedApps.length > 3) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      _showAllBlockedApps(context, blockedApps);
                    },
                    child: Text('View All ${blockedApps.length} Blocked Apps'),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  void _showAllBlockedApps(BuildContext context, List<BlockedApp> apps) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('All Blocked Apps'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: apps.length,
            itemBuilder: (context, index) {
              final app = apps[index];
              return ListTile(
                leading: const Icon(Icons.apps, color: AppColors.error),
                title: Text(app.name),
                subtitle: Text(app.packageName),
                trailing: Switch(
                  value: app.isBlocked,
                  onChanged: (value) {
                    context.read<BlockSetupBloc>().add(
                      ToggleAppBlocking(app, value),
                    );
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildAppListItem(
    BuildContext context,
    String appName,
    String packageName,
    IconData icon,
    Color iconColor,
    bool isBlocked,
    BlockedApp app,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  packageName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isBlocked,
            onChanged: (value) {
              context.read<BlockSetupBloc>().add(
                ToggleAppBlocking(app, value),
              );
            },
            activeColor: AppColors.error,
          ),
        ],
      ),
    );
  }
}

class _EnhancedAvailableAppsSection extends StatelessWidget {
  final BlockSetupLoaded state;
  
  const _EnhancedAvailableAppsSection(this.state);

  @override
  Widget build(BuildContext context) {
    final nonBlockedApps = state.filteredApps.where((app) => !app.isBlocked).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Available Apps',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (state.searchQuery.isNotEmpty)
              Chip(
                label: Text('"${state.searchQuery}"'),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {
                  context.read<BlockSetupBloc>().add(const FilterApps(''));
                },
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                _getSubtitleText(state),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
            if (state.filteredApps.isNotEmpty)
              Text(
                'Page ${state.currentPage}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        
        if (nonBlockedApps.isEmpty)
          _buildEmptyState(context)
        else
          _buildAppsList(context, nonBlockedApps),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    if (state.searchQuery.isNotEmpty) {
      return AppCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(
                  Icons.search_off,
                  size: 48,
                  color: AppColors.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  'No apps found',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try a different search term',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      return AppCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 48,
                  color: AppColors.success,
                ),
                const SizedBox(height: 16),
                Text(
                  'All apps are blocked',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You have maximum protection enabled',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildAppsList(BuildContext context, List<BlockedApp> apps) {
    return Column(
      children: [
        AppCard(
          child: Column(
            children: [
              ...apps.map((app) => Column(
                children: [
                  _buildAppListItem(
                    context,
                    app.name,
                    app.packageName,
                    Icons.apps,
                    AppColors.primary,
                    app.isBlocked,
                    app,
                  ),
                  if (app != apps.last) const Divider(),
                ],
              )),
            ],
          ),
        ),
        
        // Pagination controls
        if (state.hasMoreApps || state.isLoadingMore) ...[
          const SizedBox(height: 16),
          _buildPaginationControls(context),
        ],
      ],
    );
  }

  Widget _buildPaginationControls(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (state.isLoadingMore)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('Loading more apps...'),
              ],
            ),
          )
        else if (state.hasMoreApps)
          ElevatedButton.icon(
            onPressed: () {
              context.read<BlockSetupBloc>().add(LoadMoreApps());
            },
            icon: const Icon(Icons.expand_more),
            label: Text('Load ${state.appsPerPage} More'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check,
                  color: AppColors.success,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'All apps loaded',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAppListItem(
    BuildContext context,
    String appName,
    String packageName,
    IconData icon,
    Color iconColor,
    bool isBlocked,
    BlockedApp app,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  packageName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isBlocked,
            onChanged: (value) {
              context.read<BlockSetupBloc>().add(
                ToggleAppBlocking(app, value),
              );
            },
            activeColor: AppColors.error,
          ),
        ],
      ),
    );
  }

  String _getSubtitleText(BlockSetupLoaded state) {
    if (state.searchQuery.isNotEmpty) {
      final totalResults = state.installedApps
          .where((app) => !app.isBlocked && 
              (app.name.toLowerCase().contains(state.searchQuery.toLowerCase()) ||
               app.packageName.toLowerCase().contains(state.searchQuery.toLowerCase())))
          .length;
      return 'Found $totalResults apps matching your search';
    } else {
      return 'Prioritized social media and distracting apps';
    }
  }
}

class _SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const _SkeletonBox({
    required this.width,
    required this.height,
    this.borderRadius = 4,
  });

  @override
  State<_SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<_SkeletonBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.1, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: AppColors.onSurfaceVariant.withOpacity(0.1 * _animation.value),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}