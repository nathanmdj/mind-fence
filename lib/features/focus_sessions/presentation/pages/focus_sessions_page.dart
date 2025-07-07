import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';

class FocusSessionsPage extends StatelessWidget {
  const FocusSessionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Focus Sessions',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // TODO: Navigate to session history
            },
          ),
        ],
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Session Section
            _CurrentSessionSection(),
            SizedBox(height: 24),
            
            // Quick Start Section
            _QuickStartSection(),
            SizedBox(height: 24),
            
            // Session Templates Section
            _SessionTemplatesSection(),
            SizedBox(height: 24),
            
            // Recent Sessions Section
            _RecentSessionsSection(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Navigate to custom session creation
        },
        icon: const Icon(Icons.add),
        label: const Text('New Session'),
      ),
    );
  }
}

class _CurrentSessionSection extends StatelessWidget {
  const _CurrentSessionSection();

  @override
  Widget build(BuildContext context) {
    final hasActiveSession = false; // Mock data

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Current Session',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: hasActiveSession
              ? _buildActiveSessionContent(context)
              : _buildNoActiveSessionContent(context),
        ),
      ],
    );
  }

  Widget _buildActiveSessionContent(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.timer,
                color: AppColors.primary,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Deep Work Session',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Focus on important tasks',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                '23:45',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'remaining',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  // TODO: Pause session
                },
                child: const Text('Pause'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Stop session
                },
                child: const Text('Stop'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNoActiveSessionContent(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.outline.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                Icons.timer_off,
                size: 48,
                color: AppColors.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'No Active Session',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start a focus session to improve your productivity',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              // TODO: Start quick session
            },
            child: const Text('Start Quick Session'),
          ),
        ),
      ],
    );
  }
}

class _QuickStartSection extends StatelessWidget {
  const _QuickStartSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Start',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickStartCard(
                context,
                '15 min',
                'Quick Focus',
                Icons.flash_on,
                AppColors.secondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickStartCard(
                context,
                '30 min',
                'Work Block',
                Icons.work,
                AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickStartCard(
                context,
                '60 min',
                'Deep Work',
                Icons.psychology,
                AppColors.info,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickStartCard(
    BuildContext context,
    String duration,
    String name,
    IconData icon,
    Color color,
  ) {
    return AppCard(
      onTap: () {
        // TODO: Start quick session
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            duration,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SessionTemplatesSection extends StatelessWidget {
  const _SessionTemplatesSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Session Templates',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildTemplateItem(
          context,
          'Pomodoro',
          '25 min work, 5 min break',
          Icons.timer,
          AppColors.error,
          isCustomizable: true,
        ),
        const SizedBox(height: 12),
        _buildTemplateItem(
          context,
          'Study Session',
          '45 min focused study',
          Icons.book,
          AppColors.primary,
          isCustomizable: true,
        ),
        const SizedBox(height: 12),
        _buildTemplateItem(
          context,
          'Meeting Focus',
          '90 min distraction-free',
          Icons.meeting_room,
          AppColors.info,
          isCustomizable: true,
        ),
      ],
    );
  }

  Widget _buildTemplateItem(
    BuildContext context,
    String name,
    String description,
    IconData icon,
    Color color, {
    bool isCustomizable = false,
  }) {
    return AppCard(
      onTap: () {
        // TODO: Use template
      },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isCustomizable) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Custom',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.secondary,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: AppColors.outline,
          ),
        ],
      ),
    );
  }
}

class _RecentSessionsSection extends StatelessWidget {
  const _RecentSessionsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Recent Sessions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                // TODO: View all sessions
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildRecentSessionItem(
          context,
          'Deep Work',
          '45 min • Completed',
          '2 hours ago',
          AppColors.success,
        ),
        const SizedBox(height: 12),
        _buildRecentSessionItem(
          context,
          'Quick Focus',
          '15 min • Completed',
          'Yesterday',
          AppColors.success,
        ),
        const SizedBox(height: 12),
        _buildRecentSessionItem(
          context,
          'Study Session',
          '30 min • Interrupted',
          '2 days ago',
          AppColors.warning,
        ),
      ],
    );
  }

  Widget _buildRecentSessionItem(
    BuildContext context,
    String name,
    String duration,
    String time,
    Color statusColor,
  ) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  duration,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}