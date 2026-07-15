import 'package:akm_finance_manager/core/theme/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DayOfMonthField extends StatelessWidget {
  const DayOfMonthField({required this.controller, super.key});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Repeat every month on day',
        hintText: '1-31',
        prefixIcon: Icon(AppIcons.repeat),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(2),
      ],
      validator: (value) {
        final day = int.tryParse(value?.trim() ?? '');
        if (day == null || day < 1 || day > 31) {
          return 'Day must be between 1 and 31';
        }
        return null;
      },
    );
  }
}
