import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../bloc/dashboard_bloc.dart';

class FocusSessionCard extends StatelessWidget {
  const FocusSessionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        if (state is! DashboardLoaded) {
          return const SizedBox.shrink();
        }

        final currentSession = state.data.currentFocusSession;
        final hasActiveSession = currentSession != null;

        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: hasActiveSession
                          ? AppColors.primary.withOpacity(0.1)
                          : AppColors.outline.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      hasActiveSession ? Icons.timer : Icons.timer_outlined,
                      color: hasActiveSession ? AppColors.primary : AppColors.outline,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasActiveSession ? 'Focus Session Active' : 'No Active Session',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          hasActiveSession
                              ? currentSession.name
                              : 'Start a focus session to boost productivity',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (hasActiveSession) ...[
                _buildActiveSessionContent(context, currentSession),
              ] else ...[
                _buildInactiveSessionContent(context),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildActiveSessionContent(BuildContext context, currentSession) {
    return Column(
      children: [
        // Progress indicator
        LinearProgressIndicator(
          value: currentSession.progressPercentage,
          backgroundColor: AppColors.outline.withOpacity(0.3),
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatDuration(currentSession.remainingTime),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            Text(
              'remaining',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  context.read<DashboardBloc>().add(const FocusSessionStopped());
                },
                child: const Text('Stop Session'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Implement pause/resume functionality
                },
                child: const Text('Pause'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInactiveSessionContent(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildQuickSessionButton(
                context,
                '15 min',
                'Quick Focus',
                () => _startQuickSession(context, 15),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildQuickSessionButton(
                context,
                '30 min',
                'Work Block',
                () => _startQuickSession(context, 30),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildQuickSessionButton(
                context,
                '60 min',
                'Deep Work',
                () => _startQuickSession(context, 60),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              // TODO: Navigate to focus session setup
            },
            child: const Text('Start Custom Session'),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickSessionButton(
    BuildContext context,
    String duration,
    String label,
    VoidCallback onPressed,
  ) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              duration,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _startQuickSession(BuildContext context, int duration) {
    context.read<DashboardBloc>().add(
      FocusSessionStarted(
        sessionName: 'Quick Focus',
        duration: duration,
        blockedApps: ['com.instagram.android', 'com.tiktok.android'],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}