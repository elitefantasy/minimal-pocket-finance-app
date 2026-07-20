import 'package:akm_finance_manager/core/theme/app_spacing.dart';
import 'package:akm_finance_manager/core/theme/app_icons.dart';
import 'package:akm_finance_manager/features/transactions/application/available_transaction_years_provider.dart';
import 'package:akm_finance_manager/features/transactions/application/selected_year_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class YearSelector extends ConsumerWidget {
  const YearSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedYear = ref.watch(selectedYearProvider);
    final yearsAsync = ref.watch(availableTransactionYearsProvider);
    final years = yearsAsync.asData?.value ?? const <int>[];

    return PopupMenuButton<_YearOption>(
      tooltip: 'Select year',
      onSelected: (option) {
        ref.read(selectedYearProvider.notifier).selectYear(option.year);
      },
      itemBuilder: (context) => <PopupMenuEntry<_YearOption>>[
        CheckedPopupMenuItem<_YearOption>(
          value: const _YearOption(null),
          checked: selectedYear == null,
          child: const Text('All Years'),
        ),
        const PopupMenuDivider(),
        ...years.map(
          (year) => CheckedPopupMenuItem<_YearOption>(
            value: _YearOption(year),
            checked: selectedYear == year,
            child: Text(year.toString()),
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(selectedYear?.toString() ?? 'All Years'),
            const SizedBox(width: AppSpacing.xs),
            const Icon(AppIcons.yearSelector),
          ],
        ),
      ),
    );
  }
}

class _YearOption {
  const _YearOption(this.year);

  final int? year;
}
