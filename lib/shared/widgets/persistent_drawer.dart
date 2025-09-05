import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/navigation/route_names.dart';
import '../../shared/providers/customer_provider.dart';

class PersistentDrawer extends StatelessWidget {
  const PersistentDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Header with user info
          Consumer<CustomerProvider>(
            builder: (context, customerProvider, child) {
              return UserAccountsDrawerHeader(
                decoration: const BoxDecoration(
                  color: const Color(0xFFCF2049),
                ),
                accountName: Text(
                  customerProvider.currentCustomer?.fullName ?? 'Guest User',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                accountEmail: Text(
                  customerProvider.currentCustomer?.email ?? 'guest@example.com',
                  style: const TextStyle(fontSize: 14),
                ),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(
                    customerProvider.currentCustomer?.fullName.isNotEmpty == true
                        ? customerProvider.currentCustomer!.fullName[0].toUpperCase()
                        : 'G',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFCF2049),
                    ),
                  ),
                ),
              );
            },
          ),

          // Navigation items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Home
                _buildDrawerItem(
                  context,
                  icon: Icons.home,
                  title: 'Home',
                  route: RouteNames.home,
                  isSelected: _isCurrentRoute(context, RouteNames.home),
                ),

                // Schedule
                _buildDrawerItem(
                  context,
                  icon: Icons.calendar_today,
                  title: 'Service Schedule',
                  route: RouteNames.schedule,
                  isSelected: _isCurrentRoute(context, RouteNames.schedule),
                ),

                // Service Booking
                _buildDrawerItem(
                  context,
                  icon: Icons.book_online,
                  title: 'Book Service',
                  route: RouteNames.booking,
                  isSelected: _isCurrentRoute(context, RouteNames.booking),
                ),

                // Search Shops
                _buildDrawerItem(
                  context,
                  icon: Icons.search,
                  title: 'Search Shops',
                  route: RouteNames.searchShops,
                  isSelected: _isCurrentRoute(context, RouteNames.searchShops),
                ),

                // Billing
                _buildDrawerItem(
                  context,
                  icon: Icons.receipt,
                  title: 'Billing & Invoices',
                  route: RouteNames.billing,
                  isSelected: _isCurrentRoute(context, RouteNames.billing),
                ),

                // E-Wallet
                _buildDrawerItem(
                  context,
                  icon: Icons.account_balance_wallet,
                  title: 'E-Wallet',
                  route: RouteNames.wallet,
                  isSelected: _isCurrentRoute(context, RouteNames.wallet),
                ),

                // Feedback
                _buildDrawerItem(
                  context,
                  icon: Icons.feedback,
                  title: 'Feedback',
                  route: RouteNames.feedback,
                  isSelected: _isCurrentRoute(context, RouteNames.feedback),
                ),

                const Divider(),

                // Settings
                _buildDrawerItem(
                  context,
                  icon: Icons.settings,
                  title: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Navigate to settings
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Settings coming soon!')),
                    );
                  },
                ),

                // Help & Support
                _buildDrawerItem(
                  context,
                  icon: Icons.help,
                  title: 'Help & Support',
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Navigate to help
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Help & Support coming soon!')),
                    );
                  },
                ),

                const Divider(),

                // Logout
                _buildDrawerItem(
                  context,
                  icon: Icons.logout,
                  title: 'Logout',
                  onTap: () => _handleLogout(context),
                  textColor: const Color(0xFFCF2049),
                ),
              ],
            ),
          ),

          // Footer with app info
          Container(
            padding: const EdgeInsets.all(16.0),
            child: const Column(
              children: [
                Text(
                  'WMS Customer App',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? route,
    VoidCallback? onTap,
    bool isSelected = false,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? const Color(0xFFCF2049) : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? (isSelected ? const Color(0xFFCF2049) : null),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: const Color(0xFFCF2049).withOpacity(0.1),
      onTap: () {
        Navigator.pop(context); // Close drawer
        if (onTap != null) {
          onTap();
        } else if (route != null) {
          context.go(route);
        }
      },
    );
  }

  bool _isCurrentRoute(BuildContext context, String route) {
    final currentLocation = GoRouterState.of(context).uri.path;
    return currentLocation == route;
  }

  Future<void> _handleLogout(BuildContext context) async {
    final customerProvider = context.read<CustomerProvider>();

    // Show confirmation dialog
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      await customerProvider.logout();
      if (context.mounted) {
        context.go(RouteNames.login);
      }
    }
  }
}
