import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppBottomNavigationBar extends StatelessWidget {
  const AppBottomNavigationBar({super.key});

  static const _routes = <String>['/', '/add', '/history'];

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.path;
    final hasPrimarySelection = _routes.contains(currentPath);
    final selectedIndex = switch (currentPath) {
      '/add' => 1,
      '/history' => 2,
      _ => 0,
    };

    return Material(
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: SafeArea(
        top: false,
        child: Row(
          children: <Widget>[
            Expanded(
              child: NavigationBarTheme(
                data: hasPrimarySelection
                    ? const NavigationBarThemeData()
                    : NavigationBarThemeData(
                        indicatorColor: Colors.transparent,
                        iconTheme: WidgetStatePropertyAll<IconThemeData>(
                          IconThemeData(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        labelTextStyle: WidgetStatePropertyAll<TextStyle?>(
                          Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                child: NavigationBar(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (index) {
                    final destination = _routes[index];
                    if (destination != currentPath) {
                      context.go(destination);
                    }
                  },
                  destinations: <NavigationDestination>[
                    NavigationDestination(
                      icon: const Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(
                        hasPrimarySelection
                            ? Icons.dashboard
                            : Icons.dashboard_outlined,
                      ),
                      label: 'Dashboard',
                    ),
                    const NavigationDestination(
                      icon: Icon(Icons.add_circle_outline),
                      selectedIcon: Icon(Icons.add_circle),
                      label: 'Add',
                    ),
                    const NavigationDestination(
                      icon: Icon(Icons.history_outlined),
                      selectedIcon: Icon(Icons.history),
                      label: 'History',
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 80,
              height: 80,
              child: InkWell(
                onTap: () => _showMoreSheet(context, currentPath),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(Icons.more_horiz),
                    SizedBox(height: 4),
                    Text('More', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showMoreSheet(BuildContext context, String currentPath) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _MoreDestination(
              icon: Icons.bar_chart_outlined,
              title: 'Statistics',
              subtitle: 'View income and expense insights',
              onTap: () => _openSecondary(
                context,
                sheetContext,
                currentPath,
                '/statistics',
              ),
            ),
            _MoreDestination(
              icon: Icons.category_outlined,
              title: 'Categories',
              subtitle: 'Manage transaction categories',
              onTap: () => _openSecondary(
                context,
                sheetContext,
                currentPath,
                '/categories',
              ),
            ),
            _MoreDestination(
              icon: Icons.repeat,
              title: 'Recurring Transactions',
              subtitle: 'Manage monthly recurring transactions',
              onTap: () => _openSecondary(
                context,
                sheetContext,
                currentPath,
                '/recurring',
              ),
            ),
            _MoreDestination(
              icon: Icons.storage_outlined,
              title: 'Data Management',
              subtitle: 'Back up, import, and export app data',
              onTap: () =>
                  _openSecondary(context, sheetContext, currentPath, '/data'),
            ),
          ],
        ),
      ),
    );
  }

  void _openSecondary(
    BuildContext context,
    BuildContext sheetContext,
    String currentPath,
    String route,
  ) {
    Navigator.of(sheetContext).pop();
    if (currentPath != route) {
      context.push(route);
    }
  }
}

class _MoreDestination extends StatelessWidget {
  const _MoreDestination({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }
}
