import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MainMobileNavBar extends StatelessWidget {
  const MainMobileNavBar({
    super.key,
    required this.currentRoute,
  });

  final String currentRoute;

  static const List<String> _routes = [
    '/dashboard',
    '/construction-power',
    '/audit',
    '/multitool',
  ];

  int get _selectedIndex {
    final index = _routes.indexOf(currentRoute);
    return index >= 0 ? index : 0;
  }

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: _selectedIndex,
      labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Start',
        ),
        NavigationDestination(
          icon: Icon(Icons.account_tree_outlined),
          selectedIcon: Icon(Icons.account_tree),
          label: 'Topologia',
        ),
        NavigationDestination(
          icon: Icon(Icons.assessment_outlined),
          selectedIcon: Icon(Icons.assessment),
          label: 'Audyt',
        ),
        NavigationDestination(
          icon: Icon(Icons.build_outlined),
          selectedIcon: Icon(Icons.build),
          label: 'Narzędzia',
        ),
      ],
      onDestinationSelected: (index) {
        final targetRoute = _routes[index];
        if (targetRoute == currentRoute) {
          return;
        }

        HapticFeedback.selectionClick();
        Navigator.of(context).pushReplacementNamed(targetRoute);
      },
    );
  }
}
