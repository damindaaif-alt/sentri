import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_constants.dart';

class HomeShell extends StatelessWidget {
  final Widget child;
  const HomeShell({super.key, required this.child});

  static const _tabs = [
    (icon: Icons.call_outlined, activeIcon: Icons.call, label: 'Calls', route: AppRoutes.home),
    (icon: Icons.block_outlined, activeIcon: Icons.block, label: 'Blocklist', route: AppRoutes.blocklist),
    (icon: Icons.security_outlined, activeIcon: Icons.security, label: 'Threats', route: AppRoutes.threatFeed),
    (icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'Settings', route: AppRoutes.settings),
  ];

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith(AppRoutes.blocklist)) return 1;
    if (location.startsWith(AppRoutes.threatFeed)) return 2;
    if (location.startsWith(AppRoutes.settings)) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex(context),
        onDestinationSelected: (i) => context.go(_tabs[i].route),
        destinations: _tabs
            .map(
              (t) => NavigationDestination(
                icon: Icon(t.icon),
                selectedIcon: Icon(t.activeIcon),
                label: t.label,
              ),
            )
            .toList(),
      ),
    );
  }
}
