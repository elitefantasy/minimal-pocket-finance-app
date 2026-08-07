import 'package:minimal_pocket_finance_app/core/notifications/app_snackbar_service.dart';
import 'package:minimal_pocket_finance_app/core/constants/app_constants.dart';
import 'package:minimal_pocket_finance_app/core/theme/app_theme.dart';
import 'package:minimal_pocket_finance_app/routes/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MinimalPocketFinanceApp extends ConsumerWidget {
  const MinimalPocketFinanceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snackbarService = ref.watch(appSnackbarProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: snackbarService.messengerKey,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}
