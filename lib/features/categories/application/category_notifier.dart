import 'package:akm_finance_manager/app/providers.dart';
import 'package:akm_finance_manager/features/transactions/application/transaction_notifier.dart';
import 'package:akm_finance_manager/models/category.dart';
import 'package:akm_finance_manager/models/tombstone.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CategoryNotifier extends AsyncNotifier<List<Category>> {
  @override
  Future<List<Category>> build() {
    return ref.read(categoryRepositoryProvider).getAll();
  }

  Future<String?> addCategory(String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return 'Category name cannot be empty.';
    }

    final categories = await _currentCategories();
    if (_containsName(categories, trimmedName)) {
      return 'Category already exists.';
    }

    await ref
        .read(categoryRepositoryProvider)
        .insert(Category(name: trimmedName));
    await _refresh();
    return null;
  }

  Future<String?> updateCategory(Category category, String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return 'Category name cannot be empty.';
    }

    final categories = await _currentCategories();
    final isDuplicate = categories.any(
      (existingCategory) =>
          existingCategory.id != category.id &&
          existingCategory.name.toLowerCase() == trimmedName.toLowerCase(),
    );
    if (isDuplicate) {
      return 'Category already exists.';
    }

    await ref
        .read(categoryRepositoryProvider)
        .update(category.copyWith(name: trimmedName));
    await _refresh();
    return null;
  }

  Future<String?> deletionBlockReason(Category category) async {
    final categories = await _currentCategories();
    if (categories.length <= 1) {
      return 'At least one category is required.';
    }

    final isInUse = await ref
        .read(categoryRepositoryProvider)
        .isCategoryInUse(category.name);
    if (isInUse) {
      return 'This category is used by existing transactions.';
    }

    return null;
  }

  Future<String?> deleteCategory(Category category) async {
    final id = category.id;
    if (id == null) {
      throw ArgumentError.value(
        category,
        'category',
        'The category must have an ID before it can be deleted.',
      );
    }

    await ref.read(categoryRepositoryProvider).delete(id);
    await _refresh();
    return null;
  }

  Future<String?> deleteCategoryAndTransactions(Category category) async {
    final id = category.id;
    if (id == null) {
      return 'Category ID is required.';
    }

    final dbHelper = ref.read(databaseProvider);
    final database = await dbHelper.database;
    final tombstoneRepo = ref.read(tombstoneRepositoryProvider);

    final maps = await database.query(
      'transactions',
      columns: ['id'],
      where: 'category = ?',
      whereArgs: [category.name],
    );
    final txIds = maps.map((e) => e['id'] as String).toList();

    if (txIds.isNotEmpty) {
      await database.delete(
        'transactions',
        where: 'category = ?',
        whereArgs: [category.name],
      );
      await tombstoneRepo.insertBatch(
        txIds
            .map((txId) => Tombstone(
                  id: txId,
                  tableName: 'transactions',
                  deletedAt: DateTime.now().toUtc(),
                ))
            .toList(),
      );
    }

    await ref.read(categoryRepositoryProvider).delete(id);
    await _refresh();
    ref.invalidate(transactionNotifierProvider);
    return null;
  }


  Future<List<Category>> _currentCategories() async {
    final categories = state.asData?.value;
    if (categories != null) {
      return categories;
    }
    return ref.read(categoryRepositoryProvider).getAll();
  }

  bool _containsName(List<Category> categories, String name) {
    final normalizedName = name.toLowerCase();
    return categories.any(
      (category) => category.name.toLowerCase() == normalizedName,
    );
  }

  Future<void> _refresh() async {
    state = AsyncData(await ref.read(categoryRepositoryProvider).getAll());
  }
}

final categoryNotifierProvider =
    AsyncNotifierProvider<CategoryNotifier, List<Category>>(
      CategoryNotifier.new,
    );
