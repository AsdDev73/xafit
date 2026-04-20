import 'package:flutter/material.dart';

import 'history_screen.dart';
import 'home_screen.dart';
import 'progress_screen.dart';
import 'routines_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  int _homeRefreshToken = 0;
  int _historyRefreshToken = 0;

  List<Widget> _buildScreens() {
    return [
      HomeScreen(refreshToken: _homeRefreshToken),
      const ProgressScreen(),
      const RoutinesScreen(),
      HistoryScreen(refreshToken: _historyRefreshToken),
    ];
  }

  void _onDestinationSelected(int index) {
    setState(() {
      _currentIndex = index;

      if (index == 0) {
        _homeRefreshToken++;
      }

      if (index == 3) {
        _historyRefreshToken++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = _buildScreens();

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: NavigationBar(
          selectedIndex: _currentIndex,
          height: 64,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Inicio',
            ),
            NavigationDestination(
              icon: Icon(Icons.show_chart_outlined),
              selectedIcon: Icon(Icons.show_chart_rounded),
              label: 'Progreso',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book_rounded),
              label: 'Biblioteca',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history_rounded),
              label: 'Historial',
            ),
          ],
          onDestinationSelected: _onDestinationSelected,
        ),
      ),
    );
  }
}
