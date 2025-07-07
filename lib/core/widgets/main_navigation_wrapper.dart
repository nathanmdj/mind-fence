import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';

class MainNavigationWrapper extends StatelessWidget {
  final Widget child;
  
  const MainNavigationWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).uri.path;
    
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _getCurrentIndex(currentRoute),
        onTap: (index) => _onItemTapped(context, index),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.outline,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.block_outlined),
            activeIcon: Icon(Icons.block),
            label: 'Block Setup',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.timer_outlined),
            activeIcon: Icon(Icons.timer),
            label: 'Focus',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            activeIcon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
  
  int _getCurrentIndex(String currentRoute) {
    switch (currentRoute) {
      case '/dashboard':
        return 0;
      case '/block-setup':
        return 1;
      case '/focus-sessions':
        return 2;
      case '/analytics':
        return 3;
      case '/settings':
        return 4;
      default:
        return 0;
    }
  }
  
  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/block-setup');
        break;
      case 2:
        context.go('/focus-sessions');
        break;
      case 3:
        context.go('/analytics');
        break;
      case 4:
        context.go('/settings');
        break;
    }
  }
}