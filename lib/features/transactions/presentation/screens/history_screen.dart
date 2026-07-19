import 'package:akm_finance_manager/core/theme/app_icons.dart';
import 'package:akm_finance_manager/core/theme/app_sizes.dart';
import 'package:akm_finance_manager/core/theme/app_spacing.dart';
import 'package:akm_finance_manager/core/theme/theme_context_extensions.dart';
import 'package:akm_finance_manager/features/transactions/application/search_query_provider.dart';
import 'package:akm_finance_manager/features/transactions/application/transaction_filter_provider.dart';
import 'package:akm_finance_manager/features/transactions/application/transaction_notifier.dart';
import 'package:akm_finance_manager/features/transactions/application/transaction_sort_provider.dart';
import 'package:akm_finance_manager/features/transactions/presentation/widgets/transaction_tile.dart';
import 'package:akm_finance_manager/features/transactions/presentation/widgets/year_selector.dart';
import 'package:akm_finance_manager/shared/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({this.initialFilters, super.key});

  final HistoryFilters? initialFilters;

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  late final TextEditingController _searchController;
  HistoryFilters? _appliedInitialFilters;
  HistoryFilters? _pendingInitialFilters;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _scheduleInitialFilters(widget.initialFilters);
  }

  @override
  void didUpdateWidget(covariant HistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialFilters != widget.initialFilters) {
      _scheduleInitialFilters(widget.initialFilters);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _scheduleInitialFilters(HistoryFilters? filters) {
    if (filters == null || filters == _appliedInitialFilters) {
      return;
    }
    _pendingInitialFilters = filters;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          _pendingInitialFilters != filters ||
          _appliedInitialFilters == filters) {
        return;
      }
      _applyInitialFilters(filters);
      _appliedInitialFilters = filters;
      _pendingInitialFilters = null;
    });
  }

  void _applyInitialFilters(HistoryFilters filters) {
    ref.read(historyFiltersProvider.notifier).state = filters;
    ref.read(searchQueryProvider.notifier).state = '';
    _searchController.text = '';
  }

  void _setType(TransactionFilter type) {
    final filters = ref.read(historyFiltersProvider);
    ref.read(historyFiltersProvider.notifier).state = filters.copyWith(
      transactionType: type,
    );
  }

  void _clearFilters() {
    ref.read(historyFiltersProvider.notifier).state = const HistoryFilters();
    ref.read(searchQueryProvider.notifier).state = '';
    _searchController.clear();
  }

  void _clearCategory() {
    final filters = ref.read(historyFiltersProvider);
    ref.read(historyFiltersProvider.notifier).state = HistoryFilters(
      transactionType: filters.transactionType,
      month: filters.month,
      year: filters.year,
      isRecurring: filters.isRecurring,
    );
  }

  void _clearMonth() {
    final filters = ref.read(historyFiltersProvider);
    ref.read(historyFiltersProvider.notifier).state = HistoryFilters(
      transactionType: filters.transactionType,
      category: filters.category,
      isRecurring: filters.isRecurring,
    );
  }

  void _clearRecurring() {
    final filters = ref.read(historyFiltersProvider);
    ref.read(historyFiltersProvider.notifier).state = HistoryFilters(
      transactionType: filters.transactionType,
      category: filters.category,
      month: filters.month,
      year: filters.year,
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionNotifierProvider);
    final filteredTransactions = ref.watch(filteredTransactionsProvider);
    final filters = ref.watch(historyFiltersProvider);
    final selectedSort = ref.watch(transactionSortProvider);

    return AppScaffold(
      title: 'History',
      actions: const <Widget>[YearSelector()],
      body: transactionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text(error.toString())),
        data: (_) => Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.none,
              ),
              child: TextField(
                controller: _searchController,
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
                  runSpacing: AppSpacing.sm,
                  children: <Widget>[
                    FilterChip(
                      avatar: const Icon(AppIcons.filter),
                      label: const Text('All'),
                      selected: filters.transactionType == TransactionFilter.all,
                      onSelected: (_) => _setType(TransactionFilter.all),
                    ),
                    FilterChip(
                      avatar: Icon(
                        AppIcons.income,
                        color: context.semantic.success,
                      ),
                      label: const Text('Income'),
                      selected: filters.transactionType == TransactionFilter.income,
                      onSelected: (_) => _setType(TransactionFilter.income),
                    ),
                    FilterChip(
                      avatar: Icon(
                        AppIcons.expense,
                        color: context.colors.error,
                      ),
                      label: const Text('Expense'),
                      selected: filters.transactionType == TransactionFilter.expense,
                      onSelected: (_) => _setType(TransactionFilter.expense),
                    ),
                    if (filters.category case final category?)
                      InputChip(
                        label: Text(category),
                        onDeleted: _clearCategory,
                        deleteButtonTooltipMessage: 'Clear category filter',
                      ),
                    if (filters.month case final month?)
                      InputChip(
                        label: Text('Month $month/${filters.year}'),
                        onDeleted: _clearMonth,
                        deleteButtonTooltipMessage: 'Clear month filter',
                      ),
                    if (filters.isRecurring case final isRecurring?)
                      InputChip(
                        label: Text(isRecurring ? 'Recurring' : 'One-time'),
                        onDeleted: _clearRecurring,
                        deleteButtonTooltipMessage: 'Clear recurring filter',
                      ),
                    if (filters.hasActiveFilter)
                      TextButton(
                        onPressed: _clearFilters,
                        child: const Text('Clear filters'),
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
                  dropdownMenuEntries: const <DropdownMenuEntry<TransactionSort>>[
                    DropdownMenuEntry(
                      value: TransactionSort.newestFirst,
                      label: 'Newest First',
                    ),
                    DropdownMenuEntry(
                      value: TransactionSort.oldestFirst,
                      label: 'Oldest First',
                    ),
                    DropdownMenuEntry(
                      value: TransactionSort.highestAmount,
                      label: 'Highest Amount',
                    ),
                    DropdownMenuEntry(
                      value: TransactionSort.lowestAmount,
                      label: 'Lowest Amount',
                    ),
                    DropdownMenuEntry(
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
                  ? _HistoryEmptyState(hasActiveFilter: filters.hasActiveFilter)
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemCount: filteredTransactions.length,
                      itemBuilder: (context, index) => TransactionTile(
                        transaction: filteredTransactions[index],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryEmptyState extends StatelessWidget {
  const _HistoryEmptyState({required this.hasActiveFilter});

  final bool hasActiveFilter;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            AppIcons.receipt,
            size: AppSizes.avatarLarge,
            color: context.colors.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.md),
          Text('No transactions found', style: context.text.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            hasActiveFilter
                ? 'Try clearing a filter or changing your search.'
                : 'Try a different search or add a transaction.',
            style: context.text.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
