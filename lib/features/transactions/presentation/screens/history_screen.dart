import 'package:akm_finance_manager/core/theme/app_icons.dart';
import 'package:akm_finance_manager/core/theme/app_sizes.dart';
import 'package:akm_finance_manager/core/theme/app_spacing.dart';
import 'package:akm_finance_manager/core/theme/theme_context_extensions.dart';
import 'package:akm_finance_manager/features/transactions/application/search_query_provider.dart';
import 'package:akm_finance_manager/features/transactions/application/transaction_filter_provider.dart';
import 'package:akm_finance_manager/features/transactions/application/transaction_notifier.dart';
import 'package:akm_finance_manager/features/transactions/application/transaction_sort_provider.dart';
import 'package:akm_finance_manager/features/transactions/presentation/widgets/transaction_tile.dart';
import 'package:akm_finance_manager/shared/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionNotifierProvider);
    final filteredTransactions = ref.watch(filteredTransactionsProvider);
    final selectedFilter = ref.watch(transactionFilterProvider);
    final selectedSort = ref.watch(transactionSortProvider);

    return AppScaffold(
      title: 'History',
      body: transactionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text(error.toString())),
        data: (_) {
          return Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.none,
                ),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search transactions',
                    prefixIcon: Icon(AppIcons.search),
                  ),
                  onChanged: (value) {
                    ref.read(searchQueryProvider.notifier).state = value;
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.none,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    children: <Widget>[
                      FilterChip(
                        avatar: const Icon(AppIcons.filter),
                        label: const Text('All'),
                        selected: selectedFilter == TransactionFilter.all,
                        onSelected: (_) {
                          ref.read(transactionFilterProvider.notifier).state =
                              TransactionFilter.all;
                        },
                      ),
                      FilterChip(
                        avatar: Icon(
                          AppIcons.income,
                          color: context.semantic.success,
                        ),
                        label: const Text('Income'),
                        selected: selectedFilter == TransactionFilter.income,
                        onSelected: (_) {
                          ref.read(transactionFilterProvider.notifier).state =
                              TransactionFilter.income;
                        },
                      ),
                      FilterChip(
                        avatar: Icon(
                          AppIcons.expense,
                          color: context.colors.error,
                        ),
                        label: const Text('Expense'),
                        selected: selectedFilter == TransactionFilter.expense,
                        onSelected: (_) {
                          ref.read(transactionFilterProvider.notifier).state =
                              TransactionFilter.expense;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.none,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: DropdownMenu<TransactionSort>(
                    label: const Text('Sort'),
                    leadingIcon: const Icon(AppIcons.sort),
                    initialSelection: selectedSort,
                    dropdownMenuEntries:
                        const <DropdownMenuEntry<TransactionSort>>[
                          DropdownMenuEntry<TransactionSort>(
                            value: TransactionSort.newestFirst,
                            label: 'Newest First',
                          ),
                          DropdownMenuEntry<TransactionSort>(
                            value: TransactionSort.oldestFirst,
                            label: 'Oldest First',
                          ),
                          DropdownMenuEntry<TransactionSort>(
                            value: TransactionSort.highestAmount,
                            label: 'Highest Amount',
                          ),
                          DropdownMenuEntry<TransactionSort>(
                            value: TransactionSort.lowestAmount,
                            label: 'Lowest Amount',
                          ),
                          DropdownMenuEntry<TransactionSort>(
                            value: TransactionSort.categoryAZ,
                            label: 'Category A-Z',
                          ),
                        ],
                    onSelected: (sort) {
                      if (sort != null) {
                        ref.read(transactionSortProvider.notifier).state = sort;
                      }
                    },
                  ),
                ),
              ),
              Expanded(
                child: filteredTransactions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              AppIcons.receipt,
                              size: AppSizes.avatarLarge,
                              color: context.colors.onSurfaceVariant,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'No transactions found',
                              style: context.text.titleMedium,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Try a different search or add a transaction.',
                              style: context.text.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        itemCount: filteredTransactions.length,
                        itemBuilder: (context, index) {
                          return TransactionTile(
                            transaction: filteredTransactions[index],
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
