import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/navigation/route_names.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFFCF2049),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Account Settings
          _buildSettingsSection(
            context,
            title: 'Account',
            children: [
              _buildSettingsItem(
                context,
                icon: Icons.person,
                title: 'Profile',
                subtitle: 'Manage your personal information',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile settings coming soon!'),
                    ),
                  );
                },
              ),
              _buildSettingsItem(
                context,
                icon: Icons.security,
                title: 'Privacy & Security',
                subtitle: 'Manage your privacy settings',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Privacy settings coming soon!'),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // App Settings
          _buildSettingsSection(
            context,
            title: 'App',
            children: [
              _buildSettingsItem(
                context,
                icon: Icons.notifications,
                title: 'Notifications',
                subtitle: 'Manage appointment reminders',
                onTap: () => context.push(RouteNames.notificationSettings),
              ),
              _buildSettingsItem(
                context,
                icon: Icons.language,
                title: 'Language',
                subtitle: 'Change app language',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Language settings coming soon!'),
                    ),
                  );
                },
              ),
              _buildSettingsItem(
                context,
                icon: Icons.dark_mode,
                title: 'Theme',
                subtitle: 'Change app appearance',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Theme settings coming soon!'),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Support
          _buildSettingsSection(
            context,
            title: 'Support',
            children: [
              _buildSettingsItem(
                context,
                icon: Icons.help,
                title: 'Help & Support',
                subtitle: 'Get help and contact support',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Help & Support coming soon!'),
                    ),
                  );
                },
              ),
              _buildSettingsItem(
                context,
                icon: Icons.info,
                title: 'About',
                subtitle: 'App version and information',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('About page coming soon!')),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // App Info
          Card(
            color: Colors.grey.shade100,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Icon(Icons.build, size: 48, color: Color(0xFFCF2049)),
                  const SizedBox(height: 8),
                  const Text(
                    'AutoAnywhere',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Version 1.0.0',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Workshop Management System',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFFCF2049),
            ),
          ),
        ),
        Card(child: Column(children: children)),
      ],
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFCF2049)),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
