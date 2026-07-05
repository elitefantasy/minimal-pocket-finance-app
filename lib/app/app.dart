import 'package:flutter/material.dart';
import 'package:akm_finance_manager/core/theme/app_theme.dart';
import 'package:akm_finance_manager/routes/app_router.dart';

class AkmFinanceManagerApp extends StatelessWidget {
  const AkmFinanceManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AKM Finance Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}
