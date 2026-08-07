import 'package:minimal_pocket_finance_app/core/theme/app_icons.dart';
import 'package:minimal_pocket_finance_app/core/theme/app_sizes.dart';
import 'package:minimal_pocket_finance_app/core/theme/app_spacing.dart';
import 'package:minimal_pocket_finance_app/core/theme/theme_context_extensions.dart';
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
      color: context.colors.surfaceContainer,
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
                          IconThemeData(color: context.colors.onSurfaceVariant),
                        ),
                        labelTextStyle: WidgetStatePropertyAll<TextStyle?>(
                          context.text.labelMedium?.copyWith(
                            color: context.colors.onSurfaceVariant,
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
                      icon: const Icon(AppIcons.dashboard),
                      selectedIcon: Icon(
                        hasPrimarySelection
                            ? AppIcons.dashboardSelected
                            : AppIcons.dashboard,
                      ),
                      label: 'Dashboard',
                    ),
                    const NavigationDestination(
                      icon: Icon(AppIcons.add),
                      selectedIcon: Icon(AppIcons.addSelected),
                      label: 'Add',
                    ),
                    const NavigationDestination(
                      icon: Icon(AppIcons.historyOutlined),
                      selectedIcon: Icon(AppIcons.history),
                      label: 'History',
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: AppSizes.bottomNavigationHeight,
              height: AppSizes.bottomNavigationHeight,
              child: InkWell(
                onTap: () => _showMoreSheet(context, currentPath),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Icon(AppIcons.more),
                    const SizedBox(height: AppSpacing.xs),
                    Text('More', style: context.text.labelMedium),
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _MoreDestination(
                icon: AppIcons.statistics,
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
                icon: AppIcons.category,
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
                icon: AppIcons.repeat,
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
                icon: AppIcons.trash,
                title: 'Trash Bin',
                subtitle: 'Restore or permanently delete transactions',
                onTap: () =>
                    _openSecondary(context, sheetContext, currentPath, '/trash'),
              ),
              _MoreDestination(
                icon: AppIcons.database,
                title: 'Data Management',
                subtitle: 'Back up, import, and export app data',
                onTap: () =>
                    _openSecondary(context, sheetContext, currentPath, '/data'),
              ),
              _MoreDestination(
                icon: AppIcons.about,
                title: 'About',
                subtitle: 'App information and release details',
                onTap: () =>
                    _openSecondary(context, sheetContext, currentPath, '/about'),
              ),
            ],
          ),
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
