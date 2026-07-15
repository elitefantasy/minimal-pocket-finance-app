import 'package:akm_finance_manager/core/theme/app_icons.dart';
import 'package:akm_finance_manager/core/theme/app_spacing.dart';
import 'package:akm_finance_manager/core/theme/theme_context_extensions.dart';
import 'package:akm_finance_manager/features/recurring/presentation/widgets/day_of_month_field.dart';
import 'package:akm_finance_manager/features/transactions/presentation/widgets/amount_field.dart';
import 'package:akm_finance_manager/features/transactions/presentation/widgets/category_dropdown.dart';
import 'package:akm_finance_manager/features/transactions/presentation/widgets/note_field.dart';
import 'package:akm_finance_manager/models/category.dart';
import 'package:akm_finance_manager/models/recurring_transaction.dart';
import 'package:flutter/material.dart';

class RecurringTransactionDialog extends StatefulWidget {
  const RecurringTransactionDialog({
    required this.categories,
    this.recurring,
    super.key,
  });

  final List<Category> categories;
  final RecurringTransaction? recurring;

  @override
  State<RecurringTransactionDialog> createState() =>
      _RecurringTransactionDialogState();
}

class _RecurringTransactionDialogState
    extends State<RecurringTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late final TextEditingController _dayController;
  late String _type;
  String? _category;
  late bool _isEnabled;

  @override
  void initState() {
    super.initState();
    final recurring = widget.recurring;
    _amountController = TextEditingController(
      text: recurring?.amount.toString() ?? '',
    );
    _noteController = TextEditingController(text: recurring?.note ?? '');
    _dayController = TextEditingController(
      text: recurring?.dayOfMonth.toString() ?? '',
    );
    _type = recurring?.type ?? 'Expense';
    _category = recurring?.category;
    _isEnabled = recurring?.isEnabled ?? true;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _dayController.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final now = DateTime.now();
    final existing = widget.recurring;
    final recurring = existing == null
        ? RecurringTransaction(
            type: _type,
            amount: double.parse(_amountController.text.trim()),
            category: _category!,
            note: _noteController.text.trim(),
            dayOfMonth: int.parse(_dayController.text.trim()),
            isEnabled: _isEnabled,
            lastProcessedDate: null,
            createdAt: now,
            startDate: now,
            updatedAt: now,
          )
        : existing.copyWith(
            type: _type,
            amount: double.parse(_amountController.text.trim()),
            category: _category,
            note: _noteController.text.trim(),
            dayOfMonth: int.parse(_dayController.text.trim()),
            isEnabled: _isEnabled,
            updatedAt: now,
          );

    Navigator.of(context).pop(recurring);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.recurring == null ? 'Add Recurring' : 'Edit Recurring',
        style: context.text.titleLarge,
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Transaction Type', style: context.text.titleSmall),
              ),
              const SizedBox(height: AppSpacing.sm),
              SegmentedButton<String>(
                segments: const <ButtonSegment<String>>[
                  ButtonSegment<String>(
                    value: 'Income',
                    label: Text('Income'),
                    icon: Icon(AppIcons.income),
                  ),
                  ButtonSegment<String>(
                    value: 'Expense',
                    label: Text('Expense'),
                    icon: Icon(AppIcons.expense),
                  ),
                ],
                selected: <String>{_type},
                onSelectionChanged: (selection) {
                  setState(() => _type = selection.first);
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              AmountField(controller: _amountController),
              const SizedBox(height: AppSpacing.lg),
              CategoryDropdown(
                categories: widget.categories,
                value: _category,
                onChanged: (category) {
                  setState(() => _category = category);
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              NoteField(controller: _noteController),
              const SizedBox(height: AppSpacing.lg),
              DayOfMonthField(controller: _dayController),
              const SizedBox(height: AppSpacing.sm),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(AppIcons.repeat),
                title: Text('Enabled', style: context.text.titleSmall),
                value: _isEnabled,
                onChanged: (value) {
                  setState(() => _isEnabled = value);
                },
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
