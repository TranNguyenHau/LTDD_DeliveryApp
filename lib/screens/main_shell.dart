// lib/screens/main_shell.dart
// Shell chính với bottom navigation: Trang chủ / Đơn hàng / Lịch sử / Profile

import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'order_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const _primaryColor = Color(0xFFFF6B35);

  final List<Widget> _pages = const [
    HomeScreen(),
    OrderScreen(),
    HistoryScreen(),
    ProfileScreen(),
  ];

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
    // Tab Profile — đảm bảo hồ sơ đã được tải
    if (index == 3) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ensureProfileLoaded(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabSelected,
        backgroundColor: Colors.white,
        indicatorColor: _primaryColor.withOpacity(0.15),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: _primaryColor),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long, color: _primaryColor),
            label: 'Đơn hàng',
          ),
          NavigationDestination(
            icon: Icon(Icons.history),
            selectedIcon: Icon(Icons.history, color: _primaryColor),
            label: 'Lịch sử',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: _primaryColor),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
