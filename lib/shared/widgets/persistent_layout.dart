import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/customer_provider.dart';
import 'persistent_drawer.dart';

class PersistentLayout extends StatelessWidget {
  final Widget child;
  final String? title;
  final List<Widget>? actions;
  final bool showAppBar;
  final bool showDrawer;

  const PersistentLayout({
    super.key,
    required this.child,
    this.title,
    this.actions,
    this.showAppBar = true,
    this.showDrawer = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: Text(title ?? 'WMS Customer App'),
              backgroundColor: const Color(0xFFCF2049),
              foregroundColor: Colors.white,
              actions: [
                // Notification button
                Consumer<CustomerProvider>(
                  builder: (context, customerProvider, child) {
                    return Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications),
                          onPressed: () {
                            // TODO: Navigate to notifications
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Notifications coming soon!'),
                              ),
                            );
                          },
                        ),
                        if (customerProvider.unreadNotificationsCount > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                '${customerProvider.unreadNotificationsCount}',
                                style: const TextStyle(
                                  color: const Color(0xFFCF2049),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                // Additional actions
                if (actions != null) ...actions!,
              ],
              elevation: 0,
            )
          : null,
      drawer: showDrawer ? const PersistentDrawer() : null,
      body: child,
    );
  }
}

// Convenience wrapper for pages that need the persistent layout
class PersistentPage extends StatelessWidget {
  final Widget child;
  final String? title;
  final List<Widget>? actions;
  final bool showAppBar;
  final bool showDrawer;

  const PersistentPage({
    super.key,
    required this.child,
    this.title,
    this.actions,
    this.showAppBar = true,
    this.showDrawer = true,
  });

  @override
  Widget build(BuildContext context) {
    return PersistentLayout(
      title: title,
      actions: actions,
      showAppBar: showAppBar,
      showDrawer: showDrawer,
      child: child,
    );
  }
}
