import 'package:akm_finance_manager/core/theme/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Reusable Material 3 date picker.
///
/// Used by:
/// - Add Transaction
/// - Edit Transaction
class DatePickerField extends StatelessWidget {
  const DatePickerField({
    required this.selectedDate,
    required this.onDateChanged,
    super.key,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  Future<void> _pickDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      onDateChanged(pickedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _pickDate(context),
      icon: const Icon(AppIcons.calendar),
      label: Text(DateFormat('dd MMM yyyy').format(selectedDate)),
    );
  }
}
