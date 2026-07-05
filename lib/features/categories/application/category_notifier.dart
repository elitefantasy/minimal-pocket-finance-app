import 'package:akm_finance_manager/app/providers.dart';
import 'package:akm_finance_manager/models/category.dart';
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
    final blockReason = await deletionBlockReason(category);
    if (blockReason != null) {
      return blockReason;
    }

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
