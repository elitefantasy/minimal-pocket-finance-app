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
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search transactions',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    ref.read(searchQueryProvider.notifier).state = value;
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    children: <Widget>[
                      FilterChip(
                        label: const Text('All'),
                        selected: selectedFilter == TransactionFilter.all,
                        onSelected: (_) {
                          ref.read(transactionFilterProvider.notifier).state =
                              TransactionFilter.all;
                        },
                      ),
                      FilterChip(
                        label: const Text('Income'),
                        selected: selectedFilter == TransactionFilter.income,
                        onSelected: (_) {
                          ref.read(transactionFilterProvider.notifier).state =
                              TransactionFilter.income;
                        },
                      ),
                      FilterChip(
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
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: DropdownMenu<TransactionSort>(
                    label: const Text('Sort'),
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
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(Icons.receipt_long_outlined, size: 48),
                            SizedBox(height: 12),
                            Text('No transactions yet'),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
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
