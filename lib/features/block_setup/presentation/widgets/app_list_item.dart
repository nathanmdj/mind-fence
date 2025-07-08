import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/domain/entities/blocked_app.dart';
import '../bloc/block_setup_bloc.dart';
import '../bloc/block_setup_event.dart';

class AppListItem extends StatelessWidget {
  final BlockedApp app;
  final VoidCallback? onTap;
  final Function(BlockedApp, bool)? onToggle;
  
  const AppListItem({
    super.key,
    required this.app,
    this.onTap,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.apps,
          color: AppColors.primary,
          size: 24,
        ),
      ),
      title: Text(
        app.name,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        app.packageName,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
      ),
      trailing: Switch(
        value: app.isBlocked,
        onChanged: (value) {
          if (onToggle != null) {
            onToggle!(app, value);
          } else {
            context.read<BlockSetupBloc>().add(
              ToggleAppBlocking(app, value),
            );
          }
        },
        activeColor: AppColors.error,
      ),
      onTap: onTap,
    );
  }
}