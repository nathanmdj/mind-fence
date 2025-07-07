import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/di/injection_container.dart';
import '../bloc/block_setup_bloc.dart';
import '../bloc/block_setup_event.dart';
import '../bloc/block_setup_state.dart';
import '../../../../shared/domain/entities/blocked_app.dart';

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
            }
          },
          builder: (context, state) {
            if (state is BlockSetupLoading) {
              return const Center(child: CircularProgressIndicator());
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
                                       !state.hasOverlayPermission;
              
              return FloatingActionButton.extended(
                onPressed: () {
                  if (needsPermissions) {
                    context.read<BlockSetupBloc>().add(RequestPermissions());
                  } else if (state.isBlocking) {
                    context.read<BlockSetupBloc>().add(StopBlocking());
                  } else {
                    context.read<BlockSetupBloc>().add(StartBlocking());
                  }
                },
                icon: Icon(
                  needsPermissions
                      ? Icons.security
                      : state.isBlocking
                          ? Icons.stop
                          : Icons.play_arrow,
                ),
                label: Text(
                  needsPermissions
                      ? 'Grant Permissions'
                      : state.isBlocking
                          ? 'Stop Blocking'
                          : 'Start Blocking',
                ),
                backgroundColor: needsPermissions
                    ? AppColors.warning
                    : state.isBlocking
                        ? AppColors.error
                        : AppColors.primary,
              );
            }
            return const SizedBox();
          },
        ),
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
          _PermissionStatusSection(state),
          const SizedBox(height: 24),
          
          // Currently Blocked Apps
          _BlockedAppsSection(state.blockedApps),
          const SizedBox(height: 24),
          
          // Available Apps Section
          _AvailableAppsSection(state.filteredApps),
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
}

class _PermissionStatusSection extends StatelessWidget {
  final BlockSetupLoaded state;
  
  const _PermissionStatusSection(this.state);

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Permission Status',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildPermissionItem(
            context,
            'Usage Stats',
            state.hasUsageStatsPermission,
            'Required for monitoring app usage',
          ),
          const SizedBox(height: 8),
          _buildPermissionItem(
            context,
            'Accessibility Service',
            state.hasAccessibilityPermission,
            'Required for detecting app launches',
          ),
          const SizedBox(height: 8),
          _buildPermissionItem(
            context,
            'Overlay Permission',
            state.hasOverlayPermission,
            'Required for blocking app access',
          ),
          const SizedBox(height: 16),
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionItem(
    BuildContext context,
    String title,
    bool granted,
    String description,
  ) {
    return Row(
      children: [
        Icon(
          granted ? Icons.check_circle : Icons.error,
          color: granted ? AppColors.success : AppColors.error,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
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

class _AvailableAppsSection extends StatelessWidget {
  final List<BlockedApp> availableApps;
  
  const _AvailableAppsSection(this.availableApps);

  @override
  Widget build(BuildContext context) {
    final nonBlockedApps = availableApps.where((app) => !app.isBlocked).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Apps',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select apps to block',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        if (nonBlockedApps.isEmpty)
          AppCard(
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
          )
        else
          AppCard(
            child: Column(
              children: [
                ...nonBlockedApps.take(5).map((app) => Column(
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
                    if (app != nonBlockedApps.take(5).last) const Divider(),
                  ],
                )),
                if (nonBlockedApps.length > 5) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      _showAllAvailableApps(context, nonBlockedApps);
                    },
                    child: Text('View All ${nonBlockedApps.length} Available Apps'),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  void _showAllAvailableApps(BuildContext context, List<BlockedApp> apps) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('All Available Apps'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: apps.length,
            itemBuilder: (context, index) {
              final app = apps[index];
              return ListTile(
                leading: const Icon(Icons.apps, color: AppColors.primary),
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