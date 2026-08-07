import 'package:minimal_pocket_finance_app/core/database/database_helper.dart';
import 'package:minimal_pocket_finance_app/repositories/attachment_repository.dart';
import 'package:minimal_pocket_finance_app/repositories/category_repository.dart';
import 'package:minimal_pocket_finance_app/repositories/database_management_repository.dart';
import 'package:minimal_pocket_finance_app/repositories/recurring_repository.dart';
import 'package:minimal_pocket_finance_app/repositories/tombstone_repository.dart';
import 'package:minimal_pocket_finance_app/repositories/transaction_repository.dart';
import 'package:minimal_pocket_finance_app/services/attachment_service.dart';
import 'package:minimal_pocket_finance_app/services/transaction_service.dart';
import 'package:minimal_pocket_finance_app/services/export/export_service.dart';
import 'package:minimal_pocket_finance_app/services/url_launcher_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final urlLauncherServiceProvider = Provider<UrlLauncherService>((ref) {
  return const UrlLauncherService();
});

final databaseProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper.instance;
});

final attachmentRepositoryProvider = Provider<AttachmentRepository>((ref) {
  return AttachmentRepository(ref.watch(databaseProvider));
});

final attachmentServiceProvider = Provider<AttachmentService>((ref) {
  return AttachmentService();
});

final tombstoneRepositoryProvider = Provider<TombstoneRepository>((ref) {
  return TombstoneRepository(ref.watch(databaseProvider));
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(
    ref.watch(databaseProvider),
    attachmentRepository: ref.watch(attachmentRepositoryProvider),
    tombstoneRepository: ref.watch(tombstoneRepositoryProvider),
  );
});

final transactionServiceProvider = Provider<TransactionService>((ref) {
  return TransactionService(ref.watch(transactionRepositoryProvider));
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(
    ref.watch(databaseProvider),
    tombstoneRepository: ref.watch(tombstoneRepositoryProvider),
  );
});

final recurringRepositoryProvider = Provider<RecurringRepository>((ref) {
  return RecurringRepository(
    ref.watch(databaseProvider),
    tombstoneRepository: ref.watch(tombstoneRepositoryProvider),
  );
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
