import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';

class BlockSetupPage extends StatelessWidget {
  const BlockSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Block Setup',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement app search
            },
          ),
        ],
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Block Categories Section
            _BlockCategoriesSection(),
            SizedBox(height: 24),
            
            // Currently Blocked Apps
            _BlockedAppsSection(),
            SizedBox(height: 24),
            
            // Available Apps Section
            _AvailableAppsSection(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Implement add custom app/website
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Custom'),
      ),
    );
  }
}

class _BlockCategoriesSection extends StatelessWidget {
  const _BlockCategoriesSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Block Categories',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Quickly block entire categories of apps',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.5,
          children: [
            _buildCategoryCard(
              context,
              'Social Media',
              Icons.people,
              AppColors.error,
              12,
              8,
            ),
            _buildCategoryCard(
              context,
              'Entertainment',
              Icons.play_circle,
              AppColors.warning,
              8,
              3,
            ),
            _buildCategoryCard(
              context,
              'News',
              Icons.newspaper,
              AppColors.info,
              5,
              2,
            ),
            _buildCategoryCard(
              context,
              'Games',
              Icons.games,
              AppColors.secondary,
              15,
              5,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    String category,
    IconData icon,
    Color color,
    int totalApps,
    int blockedApps,
  ) {
    return AppCard(
      onTap: () {
        // TODO: Navigate to category details
      },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  category,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$blockedApps/$totalApps blocked',
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

class _BlockedAppsSection extends StatelessWidget {
  const _BlockedAppsSection();

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
                '8 apps',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            children: [
              _buildAppListItem(
                context,
                'Instagram',
                'com.instagram.android',
                Icons.photo_camera,
                AppColors.error,
                true,
              ),
              const Divider(),
              _buildAppListItem(
                context,
                'TikTok',
                'com.tiktok.android',
                Icons.music_video,
                AppColors.error,
                true,
              ),
              const Divider(),
              _buildAppListItem(
                context,
                'Facebook',
                'com.facebook.android',
                Icons.facebook,
                AppColors.error,
                true,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  // TODO: Show all blocked apps
                },
                child: const Text('View All Blocked Apps'),
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
              // TODO: Toggle app blocking
            },
            activeColor: AppColors.error,
          ),
        ],
      ),
    );
  }
}

class _AvailableAppsSection extends StatelessWidget {
  const _AvailableAppsSection();

  @override
  Widget build(BuildContext context) {
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
        AppCard(
          child: Column(
            children: [
              _buildAppListItem(
                context,
                'Twitter',
                'com.twitter.android',
                Icons.alternate_email,
                AppColors.info,
                false,
              ),
              const Divider(),
              _buildAppListItem(
                context,
                'YouTube',
                'com.youtube.android',
                Icons.play_circle,
                AppColors.error,
                false,
              ),
              const Divider(),
              _buildAppListItem(
                context,
                'Snapchat',
                'com.snapchat.android',
                Icons.camera_alt,
                AppColors.warning,
                false,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  // TODO: Show all available apps
                },
                child: const Text('View All Available Apps'),
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
              // TODO: Toggle app blocking
            },
            activeColor: AppColors.error,
          ),
        ],
      ),
    );
  }
}