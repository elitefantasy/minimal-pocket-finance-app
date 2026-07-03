import 'package:akm_finance_manager/core/database/database_helper.dart';
import 'package:akm_finance_manager/repositories/category_repository.dart';
import 'package:akm_finance_manager/repositories/database_management_repository.dart';
import 'package:akm_finance_manager/repositories/recurring_repository.dart';
import 'package:akm_finance_manager/repositories/transaction_repository.dart';
import 'package:akm_finance_manager/services/transaction_service.dart';
import 'package:akm_finance_manager/services/export/export_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final databaseProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper.instance;
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(ref.watch(databaseProvider));
});

final transactionServiceProvider = Provider<TransactionService>((ref) {
  return TransactionService(ref.watch(transactionRepositoryProvider));
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(ref.watch(databaseProvider));
});

final recurringRepositoryProvider = Provider<RecurringRepository>((ref) {
  return RecurringRepository(ref.watch(databaseProvider));
});

final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService();
});

final databaseManagementRepositoryProvider =
    Provider<DatabaseManagementRepository>((ref) {
      return DatabaseManagementRepository(
        ref.watch(databaseProvider),
        ref.watch(transactionRepositoryProvider),
        ref.watch(exportServiceProvider),
      );
    });
