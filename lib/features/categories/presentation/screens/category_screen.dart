import 'package:akm_finance_manager/core/notifications/app_snackbar_service.dart';
import 'package:akm_finance_manager/core/theme/app_icons.dart';
import 'package:akm_finance_manager/core/theme/app_spacing.dart';
import 'package:akm_finance_manager/core/theme/theme_context_extensions.dart';
import 'package:akm_finance_manager/features/categories/application/category_notifier.dart';
import 'package:akm_finance_manager/features/categories/widgets/category_tile.dart';
import 'package:akm_finance_manager/features/transactions/presentation/history_navigation.dart';
import 'package:akm_finance_manager/models/category.dart';
import 'package:akm_finance_manager/shared/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CategoryScreen extends ConsumerStatefulWidget {
  const CategoryScreen({super.key});

  @override
  ConsumerState<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends ConsumerState<CategoryScreen> {
  final _nameController = TextEditingController();
  bool _isAdding = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _addCategory() async {
    if (_isAdding) {
      return;
    }

    setState(() => _isAdding = true);
    try {
      final message = await ref
          .read(categoryNotifierProvider.notifier)
          .addCategory(_nameController.text);
      if (!mounted) {
        return;
      }

      if (message == null) {
        _nameController.clear();
        _showSuccess('Category added.');
      } else {
        _showMessage(message);
      }
    } on Object catch (error) {
      if (mounted) {
        _showError('Unable to add category: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _isAdding = false);
      }
    }
  }

  Future<void> _editCategory(Category category) async {
    final controller = TextEditingController(text: category.name);
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => _EditCategoryDialog(controller: controller),
    );
    controller.dispose();

    if (name == null || !mounted) {
      return;
    }

    try {
      final message = await ref
          .read(categoryNotifierProvider.notifier)
          .updateCategory(category, name);
      if (mounted) {
        if (message == null) {
          _showSuccess('Category updated.');
        } else {
          _showMessage(message);
        }
      }
    } on Object catch (error) {
      if (mounted) {
        _showError('Unable to update category: $error');
      }
    }
  }

  Future<void> _deleteCategory(Category category) async {
    try {
      final blockReason = await ref
          .read(categoryNotifierProvider.notifier)
          .deletionBlockReason(category);
      if (!mounted) {
        return;
      }
      if (blockReason != null) {
        _showError(blockReason);
        return;
      }

      final confirmed =
          await showDialog<bool>(
            context: context,
            builder: (dialogContext) => _DeleteCategoryDialog(category: category),
          ) ??
          false;
      if (!confirmed || !mounted) {
        return;
      }

      final message = await ref
          .read(categoryNotifierProvider.notifier)
          .deleteCategory(category);
      if (mounted) {
        if (message == null) {
          _showSuccess('Category deleted.');
        } else {
          _showMessage(message);
        }
      }
    } on Object catch (error) {
      if (mounted) {
        _showError('Unable to delete category: $error');
      }
    }
  }

  void _showMessage(String message) {
    ref.read(appSnackbarProvider).showInfo(message);
  }

  void _showSuccess(String message) {
    ref.read(appSnackbarProvider).showSuccess(message);
  }

  void _showError(String message) {
    ref.read(appSnackbarProvider).showError(message);
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryNotifierProvider);

    return AppScaffold(
      title: 'Categories',
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.lg,
              AppSpacing.page,
              AppSpacing.md,
            ),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.card),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Add a category', style: context.text.titleMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Keep your transactions organized with clear labels.',
                      style: context.text.bodyMedium?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Category name',
                        hintText: 'e.g. Groceries',
                        prefixIcon: Icon(AppIcons.category),
                      ),
                      onSubmitted: (_) => _addCategory(),
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: _isAdding ? null : _addCategory,
                        icon: const Icon(AppIcons.add),
                        label: Text(_isAdding ? 'Adding...' : 'Add Category'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: categoriesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) =>
                  Center(child: Text(error.toString())),
              data: (categories) {
                if (categories.isEmpty) {
                  return const _CategoriesEmptyState();
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page,
                    AppSpacing.sm,
                    AppSpacing.page,
                    AppSpacing.page,
                  ),
                  itemCount: categories.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return CategoryTile(
                      category: category,
                      onTap: () => HistoryNavigation.open(
                        context,
                        category: category.name,
                      ),
                      onEdit: () => _editCategory(category),
                      onDelete: () => _deleteCategory(category),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoriesEmptyState extends StatelessWidget {
  const _CategoriesEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.page),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              AppIcons.category,
              size: AppIcons.largeSize,
              color: context.colors.secondary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('No categories yet', style: context.text.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Create a category to keep your transactions organized.',
              style: context.text.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _EditCategoryDialog extends StatelessWidget {
  const _EditCategoryDialog({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: <Widget>[
          Icon(AppIcons.edit, color: context.colors.secondary),
          const SizedBox(width: AppSpacing.sm),
          Text('Rename category', style: context.text.titleLarge),
        ],
      ),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Category name',
          prefixIcon: Icon(AppIcons.category),
        ),
        textInputAction: TextInputAction.done,
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _DeleteCategoryDialog extends StatelessWidget {
  const _DeleteCategoryDialog({required this.category});

  final Category category;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: <Widget>[
          Icon(AppIcons.delete, color: context.colors.error),
          const SizedBox(width: AppSpacing.sm),
          Text('Delete category?', style: context.text.titleLarge),
        ],
      ),
      content: Text(
        'Delete "${category.name}"? This cannot be undone.',
        style: context.text.bodyMedium,
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: context.colors.error,
            foregroundColor: context.colors.onError,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
