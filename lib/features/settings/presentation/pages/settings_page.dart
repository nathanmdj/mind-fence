import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            _ProfileSection(),
            SizedBox(height: 24),
            
            // Blocking Settings
            _BlockingSettingsSection(),
            SizedBox(height: 24),
            
            // Notifications Settings
            _NotificationsSection(),
            SizedBox(height: 24),
            
            // Appearance Settings
            _AppearanceSection(),
            SizedBox(height: 24),
            
            // Privacy & Security
            _PrivacySecuritySection(),
            SizedBox(height: 24),
            
            // Support & About
            _SupportAboutSection(),
          ],
        ),
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              Icons.person,
              color: AppColors.primary,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'John Doe',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'john.doe@example.com',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Premium',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
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

class _BlockingSettingsSection extends StatelessWidget {
  const _BlockingSettingsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Blocking Settings',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildSettingsItem(
          context,
          'Block Mode',
          'Strict blocking with no overrides',
          Icons.security,
          AppColors.error,
          trailing: Switch(
            value: true,
            onChanged: (value) {
              // TODO: Toggle block mode
            },
            activeColor: AppColors.error,
          ),
        ),
        const SizedBox(height: 12),
        _buildSettingsItem(
          context,
          'Emergency Override',
          'Allow emergency access with delay',
          Icons.warning,
          AppColors.warning,
          trailing: Switch(
            value: true,
            onChanged: (value) {
              // TODO: Toggle emergency override
            },
            activeColor: AppColors.warning,
          ),
        ),
        const SizedBox(height: 12),
        _buildSettingsItem(
          context,
          'Website Blocking',
          'Block distracting websites',
          Icons.web,
          AppColors.info,
          trailing: Switch(
            value: false,
            onChanged: (value) {
              // TODO: Toggle website blocking
            },
            activeColor: AppColors.info,
          ),
        ),
        const SizedBox(height: 12),
        _buildSettingsItem(
          context,
          'Schedule Settings',
          'Configure automatic blocking schedules',
          Icons.schedule,
          AppColors.primary,
          onTap: () {
            // TODO: Navigate to schedule settings
          },
        ),
      ],
    );
  }

  Widget _buildSettingsItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color, {
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return AppCard(
      onTap: onTap,
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
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          trailing ??
              const Icon(
                Icons.chevron_right,
                color: AppColors.outline,
              ),
        ],
      ),
    );
  }
}

class _NotificationsSection extends StatelessWidget {
  const _NotificationsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notifications',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildSettingsItem(
          context,
          'Push Notifications',
          'Receive app notifications',
          Icons.notifications,
          AppColors.primary,
          trailing: Switch(
            value: true,
            onChanged: (value) {
              // TODO: Toggle push notifications
            },
            activeColor: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        _buildSettingsItem(
          context,
          'Focus Reminders',
          'Reminders to start focus sessions',
          Icons.timer,
          AppColors.success,
          trailing: Switch(
            value: true,
            onChanged: (value) {
              // TODO: Toggle focus reminders
            },
            activeColor: AppColors.success,
          ),
        ),
        const SizedBox(height: 12),
        _buildSettingsItem(
          context,
          'Weekly Reports',
          'Weekly productivity reports',
          Icons.analytics,
          AppColors.info,
          trailing: Switch(
            value: false,
            onChanged: (value) {
              // TODO: Toggle weekly reports
            },
            activeColor: AppColors.info,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color, {
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return AppCard(
      onTap: onTap,
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
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          trailing ??
              const Icon(
                Icons.chevron_right,
                color: AppColors.outline,
              ),
        ],
      ),
    );
  }
}

class _AppearanceSection extends StatelessWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Appearance',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildSettingsItem(
          context,
          'Dark Mode',
          'Switch to dark theme',
          Icons.dark_mode,
          AppColors.outline,
          trailing: Switch(
            value: Theme.of(context).brightness == Brightness.dark,
            onChanged: (value) {
              // TODO: Toggle dark mode
            },
            activeColor: AppColors.outline,
          ),
        ),
        const SizedBox(height: 12),
        _buildSettingsItem(
          context,
          'Language',
          'English (US)',
          Icons.language,
          AppColors.info,
          onTap: () {
            // TODO: Navigate to language settings
          },
        ),
        const SizedBox(height: 12),
        _buildSettingsItem(
          context,
          'Text Size',
          'Adjust text size for better readability',
          Icons.text_fields,
          AppColors.secondary,
          onTap: () {
            // TODO: Navigate to text size settings
          },
        ),
      ],
    );
  }

  Widget _buildSettingsItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color, {
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return AppCard(
      onTap: onTap,
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
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          trailing ??
              const Icon(
                Icons.chevron_right,
                color: AppColors.outline,
              ),
        ],
      ),
    );
  }
}

class _PrivacySecuritySection extends StatelessWidget {
  const _PrivacySecuritySection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Privacy & Security',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildSettingsItem(
          context,
          'Data Backup',
          'Backup your settings and data',
          Icons.backup,
          AppColors.primary,
          onTap: () {
            // TODO: Navigate to backup settings
          },
        ),
        const SizedBox(height: 12),
        _buildSettingsItem(
          context,
          'Privacy Policy',
          'Read our privacy policy',
          Icons.privacy_tip,
          AppColors.info,
          onTap: () {
            // TODO: Open privacy policy
          },
        ),
        const SizedBox(height: 12),
        _buildSettingsItem(
          context,
          'Terms of Service',
          'Read our terms of service',
          Icons.description,
          AppColors.secondary,
          onTap: () {
            // TODO: Open terms of service
          },
        ),
        const SizedBox(height: 12),
        _buildSettingsItem(
          context,
          'Clear Data',
          'Reset all app data',
          Icons.delete_forever,
          AppColors.error,
          onTap: () {
            // TODO: Show clear data confirmation
          },
        ),
      ],
    );
  }

  Widget _buildSettingsItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color, {
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return AppCard(
      onTap: onTap,
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
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          trailing ??
              const Icon(
                Icons.chevron_right,
                color: AppColors.outline,
              ),
        ],
      ),
    );
  }
}

class _SupportAboutSection extends StatelessWidget {
  const _SupportAboutSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Support & About',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildSettingsItem(
          context,
          'Help Center',
          'Get help and support',
          Icons.help,
          AppColors.info,
          onTap: () {
            // TODO: Open help center
          },
        ),
        const SizedBox(height: 12),
        _buildSettingsItem(
          context,
          'Contact Us',
          'Send feedback or report issues',
          Icons.contact_support,
          AppColors.primary,
          onTap: () {
            // TODO: Open contact form
          },
        ),
        const SizedBox(height: 12),
        _buildSettingsItem(
          context,
          'Rate App',
          'Rate Mind Fence on the App Store',
          Icons.star,
          AppColors.warning,
          onTap: () {
            // TODO: Open app store rating
          },
        ),
        const SizedBox(height: 12),
        _buildSettingsItem(
          context,
          'About',
          'Version 1.0.0',
          Icons.info,
          AppColors.secondary,
          onTap: () {
            // TODO: Show about dialog
          },
        ),
      ],
    );
  }

  Widget _buildSettingsItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color, {
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return AppCard(
      onTap: onTap,
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
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          trailing ??
              const Icon(
                Icons.chevron_right,
                color: AppColors.outline,
              ),
        ],
      ),
    );
  }
}