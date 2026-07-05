import 'package:flutter/material.dart';

class TransactionTypeButtons extends StatelessWidget {
  const TransactionTypeButtons({
    required this.onIncome,
    required this.onExpense,
    this.isSaving = false,
    super.key,
  });

  final VoidCallback onIncome;
  final VoidCallback onExpense;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: FilledButton(
            onPressed: isSaving ? null : onIncome,
            child: const Text('Income'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: FilledButton(
            onPressed: isSaving ? null : onExpense,
            child: const Text('Expense'),
          ),
        ),
      ],
    );
  }
}
