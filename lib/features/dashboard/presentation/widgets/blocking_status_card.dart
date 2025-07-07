import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../bloc/dashboard_bloc.dart';

class BlockingStatusCard extends StatelessWidget {
  const BlockingStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        if (state is! DashboardLoaded) {
          return const SizedBox.shrink();
        }

        final isBlocking = state.data.isBlockingActive;
        final blockedAppsCount = state.data.blockedApps.where((app) => app.isBlocked).length;

        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isBlocking
                          ? AppColors.success.withOpacity(0.1)
                          : AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isBlocking ? Icons.shield : Icons.shield_outlined,
                      color: isBlocking ? AppColors.success : AppColors.error,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isBlocking ? 'Blocking Active' : 'Blocking Inactive',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isBlocking ? AppColors.success : AppColors.error,
                          ),
                        ),
                        Text(
                          '$blockedAppsCount apps blocked',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: isBlocking,
                    onChanged: (value) {
                      context.read<DashboardBloc>().add(const BlockingStatusToggled());
                    },
                    activeColor: AppColors.success,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatusItem(
                      context,
                      'Apps Blocked',
                      blockedAppsCount.toString(),
                      Icons.block,
                      AppColors.error,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatusItem(
                      context,
                      'Streak Days',
                      state.data.streakDays.toString(),
                      Icons.local_fire_department,
                      AppColors.warning,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}