import 'package:akm_finance_manager/core/notifications/app_snackbar_service.dart';
import 'package:akm_finance_manager/features/categories/application/category_notifier.dart';
import 'package:akm_finance_manager/features/categories/widgets/category_tile.dart';
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
        _showMessage('Category added.');
      } else {
        _showMessage(message);
      }
    } on Object catch (error) {
      if (mounted) {
        _showMessage('Unable to add category: $error');
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
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Category'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Category name'),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
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
        _showMessage(message ?? 'Category updated.');
      }
    } on Object catch (error) {
      if (mounted) {
        _showMessage('Unable to update category: $error');
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
        _showMessage(blockReason);
        return;
      }

      final confirmed =
          await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Delete Category?'),
              content: Text('Delete "${category.name}"?'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Delete'),
                ),
              ],
            ),
          ) ??
          false;
      if (!confirmed || !mounted) {
        return;
      }

      final message = await ref
          .read(categoryNotifierProvider.notifier)
          .deleteCategory(category);
      if (mounted) {
        _showMessage(message ?? 'Category deleted.');
      }
    } on Object catch (error) {
      if (mounted) {
        _showMessage('Unable to delete category: $error');
      }
    }
  }

  void _showMessage(String message) {
    ref.read(appSnackbarProvider).showInfo(message);
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryNotifierProvider);

    return AppScaffold(
      title: 'Categories',
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'New Category',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _addCategory(),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _isAdding ? null : _addCategory,
                  child: Text(_isAdding ? 'Adding...' : 'Add Category'),
                ),
              ],
            ),
          ),
          Expanded(
            child: categoriesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) =>
                  Center(child: Text(error.toString())),
              data: (categories) => ListView.builder(
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return CategoryTile(
                    category: category,
                    onEdit: () => _editCategory(category),
                    onDelete: () => _deleteCategory(category),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
