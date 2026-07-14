// Flutter imports
import 'package:flutter/material.dart';

// Package imports
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Application Core/Shared imports
import 'package:akm_finance_manager/core/notifications/app_snackbar_service.dart';
import 'package:akm_finance_manager/shared/widgets/app_scaffold.dart';

// Model imports
import 'package:akm_finance_manager/models/recurring_transaction.dart';
import 'package:akm_finance_manager/models/transaction.dart';

// Feature Feature Notifiers & Providers
import 'package:akm_finance_manager/features/categories/application/category_notifier.dart';
import 'package:akm_finance_manager/features/recurring/application/recurring_notifier.dart';
import 'package:akm_finance_manager/features/recurring/application/recurring_processing_provider.dart';
import 'package:akm_finance_manager/features/transactions/application/selected_transaction_date_provider.dart';
import 'package:akm_finance_manager/features/transactions/application/transaction_notifier.dart';

// Feature UI Widgets
import 'package:akm_finance_manager/features/recurring/presentation/widgets/day_of_month_field.dart';
import 'package:akm_finance_manager/features/transactions/presentation/widgets/amount_field.dart';
import 'package:akm_finance_manager/features/transactions/presentation/widgets/category_dropdown.dart';
import 'package:akm_finance_manager/features/transactions/presentation/widgets/date_picker_field.dart';
import 'package:akm_finance_manager/features/transactions/presentation/widgets/note_field.dart';
import 'package:akm_finance_manager/features/transactions/presentation/widgets/transaction_type_buttons.dart';

/// Screen allowing users to input and create either standard or recurring 
/// income and expense transactions.
class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  // Form handling keys and controllers
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _dayOfMonthController = TextEditingController();

  // Local UI and validation states
  String? _selectedCategory;
  bool _repeatMonthly = false;
  bool _isSaving = false;
  bool _showNoteField = false;

  @override
  void dispose() {
    // Prevent memory leaks by properly disposing controllers
    _amountController.dispose();
    _noteController.dispose();
    _dayOfMonthController.dispose();
    super.dispose();
  }

  /// Validates input values and saves either a standard or recurring 
  /// transaction to the local storage/state.
  Future<void> _saveTransaction(String type) async {
    final wasRecurring = _repeatMonthly;

    // Early exit if currently processing or form inputs are invalid
    if (_isSaving || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Read the currently selected date from the Riverpod provider
      final selectedDate = ref.read(selectedTransactionDateProvider);

      if (wasRecurring) {
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
          startDate: selectedDate,
          updatedAt: now,
        );

        // Add recurring template
        await ref
            .read(recurringNotifierProvider.notifier)
            .addRecurring(recurring);

        // Process any occurrences that are instantly due from the new rule
        final generatedCount = await ref
            .read(recurringProcessingServiceProvider)
            .processDueTransactions();

        if (generatedCount > 0) {
          ref
            ..invalidate(transactionNotifierProvider)
            ..invalidate(recurringNotifierProvider);
        }

        // Refresh transactions list view state
        await ref.read(transactionNotifierProvider.notifier).refresh();
      } else {
        final transaction = Transaction(
          type: type,
          amount: double.parse(_amountController.text.trim()),
          category: _selectedCategory!,
          note: _noteController.text.trim(),
          date: selectedDate,
        );

        // Add a normal one-off transaction
        await ref.read(transactionNotifierProvider.notifier).add(transaction);
      }

      // Safeguard async boundary across BuildContext lines
      if (!mounted) return;

      // Reset form states upon successful save
      _amountController.clear();
      _noteController.clear();
      _dayOfMonthController.clear();

      setState(() {
        _repeatMonthly = false;
        _showNoteField = false;
      });

      // Show success notification banner
      ref.read(appSnackbarProvider).showSuccess(
            wasRecurring
                ? 'Recurring transaction created.'
                : 'Transaction added.',
          );
    } on Object catch (error) {
      if (!mounted) return;

      // Handle fallback processing errors gracefully
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
    // Watches the live states of categories and selected entry dates
    final categoriesAsync = ref.watch(categoryNotifierProvider);
    final selectedDate = ref.watch(selectedTransactionDateProvider);

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
              // Amount text input
              AmountField(controller: _amountController),
              const SizedBox(height: 16),

              // Category mapping dropdown selection
              CategoryDropdown(
                categories: categories,
                value: _selectedCategory,
                onChanged: (category) {
                  setState(() => _selectedCategory = category);
                },
              ),
              const SizedBox(height: 16),

              // Note Visibility Toggle Checkbox
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Add note'),
                value: _showNoteField,
                onChanged: (value) {
                  setState(() {
                    _showNoteField = value ?? false;
                    if (!_showNoteField) {
                      _noteController.clear();
                    }
                  });
                },
              ),

              // Animated Transition Container for Contextual Note Field
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  return SizeTransition(
                    sizeFactor: animation,
                    axisAlignment: -1,
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  );
                },
                child: _showNoteField
                    ? Padding(
                        key: const ValueKey('note_field'),
                        padding: const EdgeInsets.only(top: 8),
                        child: NoteField(
                          controller: _noteController,
                        ),
                      )
                    : const SizedBox(
                        key: ValueKey('empty_note'),
                      ),
              ),
              const SizedBox(height: 16),

              // Transaction Target Date Picker Field
              DatePickerField(
                selectedDate: selectedDate,
                onDateChanged: (date) {
                  ref
                      .read(selectedTransactionDateProvider.notifier)
                      .setDate(date);
                },
              ),
              const SizedBox(height: 8),

              // Switch to control if transaction repeats periodically
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Repeat monthly'),
                value: _repeatMonthly,
                onChanged: (value) {
                  setState(() => _repeatMonthly = value);
                },
              ),

              // Conditional Day of Month display field if repetition is requested
              if (_repeatMonthly) ...<Widget>[
                const SizedBox(height: 8),
                DayOfMonthField(controller: _dayOfMonthController),
              ],
              const SizedBox(height: 24),

              // Income / Expense trigger submission button row
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