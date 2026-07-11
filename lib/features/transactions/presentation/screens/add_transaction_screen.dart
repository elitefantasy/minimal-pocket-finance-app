import 'package:akm_finance_manager/core/notifications/app_snackbar_service.dart';
import 'package:akm_finance_manager/features/categories/application/category_notifier.dart';
import 'package:akm_finance_manager/features/recurring/application/recurring_processing_provider.dart';
import 'package:akm_finance_manager/features/recurring/application/recurring_notifier.dart';
import 'package:akm_finance_manager/features/recurring/presentation/widgets/day_of_month_field.dart';
import 'package:akm_finance_manager/features/transactions/application/transaction_notifier.dart';
import 'package:akm_finance_manager/features/transactions/presentation/widgets/amount_field.dart';
import 'package:akm_finance_manager/features/transactions/presentation/widgets/category_dropdown.dart';
import 'package:akm_finance_manager/features/transactions/presentation/widgets/note_field.dart';
import 'package:akm_finance_manager/features/transactions/presentation/widgets/transaction_type_buttons.dart';
import 'package:akm_finance_manager/models/recurring_transaction.dart';
import 'package:akm_finance_manager/models/transaction.dart';
import 'package:akm_finance_manager/shared/widgets/app_scaffold.dart';
import 'package:akm_finance_manager/features/transactions/presentation/widgets/date_picker_field.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _dayOfMonthController = TextEditingController();

  String? _selectedCategory;
  bool _repeatMonthly = false;
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _dayOfMonthController.dispose();
    super.dispose();
  }

  Future<void> _saveTransaction(String type) async {
    if (_isSaving || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (_repeatMonthly) {
		  final now = DateTime.now();
		  final recurring = RecurringTransaction(
			type: type,
			amount: double.parse(_amountController.text.trim()),
			category: _selectedCategory!,
			note: _noteController.text.trim(),
			dayOfMonth: int.parse(_dayOfMonthController.text.trim()),
			isEnabled: true,
			lastProcessedDate: null,
			createdAt: now,
			startDate: _selectedDate,
			updatedAt: now,
		  );

		  await ref
			  .read(recurringNotifierProvider.notifier)
			  .addRecurring(recurring);

		  // NEW
		  final generatedCount = await ref
			.read(recurringProcessingServiceProvider)
			.processDueTransactions();

		if (generatedCount > 0) {
		  ref
			..invalidate(transactionNotifierProvider)
			..invalidate(recurringNotifierProvider);
		}

		  // Refresh transactions after processing.
		  await ref.read(transactionNotifierProvider.notifier).refresh();
		} else {
		  final transaction = Transaction(
			type: type,
			amount: double.parse(_amountController.text.trim()),
			category: _selectedCategory!,
			note: _noteController.text.trim(),
			date: _selectedDate,
		  );

		  await ref.read(transactionNotifierProvider.notifier).add(transaction);
		}
      if (!mounted) {
        return;
      }

      _amountController.clear();
      _noteController.clear();
      _dayOfMonthController.clear();

      setState(() {
        _selectedDate = DateTime.now();
        _repeatMonthly = false;
      });
      if (_repeatMonthly) {
		  ref.read(appSnackbarProvider).showSuccess(
			'Recurring transaction created.',
		  );
		} else {
		  ref.read(appSnackbarProvider).showSuccess(
			'Transaction added.',
		  );
		}
    } on Object catch (error) {
      if (!mounted) {
        return;
      }

      ref
          .read(appSnackbarProvider)
          .showError('Unable to add transaction: $error');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryNotifierProvider);

    return AppScaffold(
      title: 'Add Transaction',
      body: categoriesAsync.when(
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
                  setState(() => _selectedCategory = category);
                },
              ),
              const SizedBox(height: 16),
              NoteField(controller: _noteController),

              const SizedBox(height: 16),

              DatePickerField(
                selectedDate: _selectedDate,
                onDateChanged: (date) {
                  setState(() {
                    _selectedDate = date;
                  });
                },
              ),

              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Repeat monthly'),
                value: _repeatMonthly,
                onChanged: (value) {
                  setState(() => _repeatMonthly = value);
                },
              ),

              if (_repeatMonthly) ...<Widget>[
                const SizedBox(height: 8),
                DayOfMonthField(controller: _dayOfMonthController),
              ],
              const SizedBox(height: 24),
              TransactionTypeButtons(
                isSaving: _isSaving,
                onIncome: () => _saveTransaction('Income'),
                onExpense: () => _saveTransaction('Expense'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
