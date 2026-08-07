import 'package:minimal_pocket_finance_app/core/theme/app_icons.dart';
import 'package:minimal_pocket_finance_app/core/theme/app_spacing.dart';
import 'package:minimal_pocket_finance_app/core/theme/theme_context_extensions.dart';
import 'package:minimal_pocket_finance_app/features/recurring/presentation/widgets/day_of_month_field.dart';
import 'package:minimal_pocket_finance_app/features/transactions/presentation/widgets/amount_field.dart';
import 'package:minimal_pocket_finance_app/features/transactions/presentation/widgets/category_search_field.dart';
import 'package:minimal_pocket_finance_app/features/transactions/presentation/widgets/note_field.dart';
import 'package:minimal_pocket_finance_app/models/category.dart';
import 'package:minimal_pocket_finance_app/models/recurring_transaction.dart';
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
    final isNewRecurring = widget.recurring == null;

    return AlertDialog(
      title: Row(
        children: <Widget>[
          Icon(AppIcons.repeat, color: context.colors.secondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              isNewRecurring ? 'Add recurring transaction' : 'Edit recurring transaction',
              style: context.text.titleLarge,
            ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const _SectionLabel('Transaction type'),
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
              const SizedBox(height: AppSpacing.xl),
              const _SectionLabel('Details'),
              const SizedBox(height: AppSpacing.sm),
              AmountField(controller: _amountController),
              const SizedBox(height: AppSpacing.lg),
              CategorySearchField(
                categories: widget.categories,
                value: _category,
                onChanged: (category) {
                  setState(() => _category = category);
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              NoteField(controller: _noteController),
              const SizedBox(height: AppSpacing.xl),
              const _SectionLabel('Schedule'),
              const SizedBox(height: AppSpacing.sm),
              DayOfMonthField(controller: _dayController),
              const SizedBox(height: AppSpacing.md),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(AppIcons.repeat),
                title: Text('Enabled', style: context.text.titleSmall),
                subtitle: Text(
                  _isEnabled
                      ? 'This transaction will be processed monthly.'
                      : 'This transaction is paused.',
                  style: context.text.bodyMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
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
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(AppIcons.check),
          label: Text(isNewRecurring ? 'Add recurring' : 'Save changes'),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label, style: context.text.titleSmall);
  }
}
