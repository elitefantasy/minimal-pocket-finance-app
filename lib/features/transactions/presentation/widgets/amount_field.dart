import 'package:minimal_pocket_finance_app/core/theme/theme_context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AmountField extends StatelessWidget {
  const AmountField({required this.controller, super.key});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(labelText: 'Amount', prefixText: '₹'),
      style: context.text.headlineSmall,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      validator: (value) {
        final amountText = value?.trim() ?? '';
        if (amountText.isEmpty) {
          return 'Amount is required';
        }
        final amount = double.tryParse(amountText);
        if (amount == null || amount <= 0) {
          return 'Amount must be greater than zero';
        }
        return null;
      },
    );
  }
}
