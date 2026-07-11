import 'package:akm_finance_manager/shared/widgets/app_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    super.key,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final FloatingActionButton? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    // final currentPath = GoRouterState.of(context).uri.path;
    final currentPath = GoRouter.of(context).state.uri.path;
    final isSecondary =
        currentPath != '/' &&
        currentPath != '/add' &&
        currentPath != '/history';

    return Scaffold(
      appBar: AppBar(
        leading: isSecondary
            ? BackButton(
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/');
                  }
                },
              )
            : null,
        title: Text(title),
        actions: actions,
      ),
      body: SafeArea(child: body),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: const AppBottomNavigationBar(),
    );
  }
}
