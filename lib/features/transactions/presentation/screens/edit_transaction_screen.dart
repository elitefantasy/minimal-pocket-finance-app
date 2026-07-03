import 'package:akm_finance_manager/features/categories/application/category_notifier.dart';
import 'package:akm_finance_manager/features/transactions/application/transaction_notifier.dart';
import 'package:akm_finance_manager/features/transactions/presentation/widgets/amount_field.dart';
import 'package:akm_finance_manager/features/transactions/presentation/widgets/category_dropdown.dart';
import 'package:akm_finance_manager/features/transactions/presentation/widgets/note_field.dart';
import 'package:akm_finance_manager/models/transaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class EditTransactionScreen extends ConsumerStatefulWidget {
  const EditTransactionScreen({required this.transaction, super.key});

  final Transaction transaction;

  @override
  ConsumerState<EditTransactionScreen> createState() =>
      _EditTransactionScreenState();
}

class _EditTransactionScreenState extends ConsumerState<EditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late String _selectedCategory;
  late DateTime _selectedDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.transaction.amount.toString(),
    );
    _noteController = TextEditingController(text: widget.transaction.note);
    _selectedCategory = widget.transaction.category;
    _selectedDate = widget.transaction.date;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (date != null && mounted) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _save() async {
    if (_isSaving || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updatedTransaction = widget.transaction.copyWith(
        amount: double.parse(_amountController.text.trim()),
        category: _selectedCategory,
        note: _noteController.text.trim(),
        date: _selectedDate,
      );

      await ref
          .read(transactionNotifierProvider.notifier)
          .updateTransaction(updatedTransaction);
      if (mounted) {
        context.pop();
      }
    } on Object catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to update transaction: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Transaction')),
      body: SafeArea(
        child: categoriesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(child: Text(error.toString())),
          data: (categories) => Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                AmountField(controller: _amountController),
                const SizedBox(height: 16),
                CategoryDropdown(
                  categories: categories,
                  value: _selectedCategory,
                  onChanged: (category) {
                    if (category != null) {
                      setState(() => _selectedCategory = category);
                    }
                  },
                ),
                const SizedBox(height: 16),
                NoteField(controller: _noteController),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _selectDate,
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(
                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isSaving ? null : _save,
                  child: Text(_isSaving ? 'Saving...' : 'Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
