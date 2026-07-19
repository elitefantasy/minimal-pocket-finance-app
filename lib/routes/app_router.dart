import 'package:akm_finance_manager/features/about/presentation/screens/about_screen.dart';
import 'package:akm_finance_manager/features/categories/presentation/screens/category_screen.dart';
import 'package:akm_finance_manager/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:akm_finance_manager/features/data_management/presentation/screens/data_management_screen.dart';
import 'package:akm_finance_manager/features/recurring/presentation/screens/recurring_screen.dart';
import 'package:akm_finance_manager/features/statistics/presentation/screens/statistics_screen.dart';
import 'package:akm_finance_manager/features/transactions/presentation/screens/add_transaction_screen.dart';
import 'package:akm_finance_manager/features/transactions/presentation/screens/edit_transaction_screen.dart';
import 'package:akm_finance_manager/features/transactions/presentation/screens/history_screen.dart';
import 'package:akm_finance_manager/features/transactions/application/transaction_filter_provider.dart';
import 'package:akm_finance_manager/models/transaction.dart';
import 'package:go_router/go_router.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    GoRoute(path: '/', builder: (context, state) => const DashboardScreen()),
    GoRoute(
      path: '/add',
      builder: (context, state) => const AddTransactionScreen(),
    ),
    GoRoute(
      path: '/history',
      builder: (context, state) => HistoryScreen(
        initialFilters: _historyFiltersFrom(state.uri.queryParameters),
      ),
    ),
    GoRoute(
      path: '/edit',
      builder: (context, state) =>
          EditTransactionScreen(transaction: state.extra! as Transaction),
    ),
    GoRoute(
      path: '/statistics',
      builder: (context, state) => const StatisticsScreen(),
    ),
    GoRoute(
      path: '/categories',
      builder: (context, state) => const CategoryScreen(),
    ),
    GoRoute(
      path: '/recurring',
      builder: (context, state) => const RecurringScreen(),
    ),
    GoRoute(
      path: '/data',
      builder: (context, state) => const DataManagementScreen(),
    ),
    GoRoute(path: '/about', builder: (context, state) => const AboutScreen()),
  ],
);

HistoryFilters? _historyFiltersFrom(Map<String, String> queryParameters) {
  final type = switch (queryParameters['type']) {
    'income' => TransactionFilter.income,
    'expense' => TransactionFilter.expense,
    _ => TransactionFilter.all,
  };
  final month = int.tryParse(queryParameters['month'] ?? '');
  final year = int.tryParse(queryParameters['year'] ?? '');
  final recurring = switch (queryParameters['recurring']) {
    'true' => true,
    'false' => false,
    _ => null,
  };
  final category = queryParameters['category'];

  if (category == null &&
      type == TransactionFilter.all &&
      month == null &&
      year == null &&
      recurring == null) {
    return null;
  }

  return HistoryFilters(
    transactionType: type,
    category: category,
    month: month,
    year: year,
    isRecurring: recurring,
  );
}
