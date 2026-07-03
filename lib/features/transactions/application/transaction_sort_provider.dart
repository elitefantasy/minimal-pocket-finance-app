import 'package:flutter_riverpod/flutter_riverpod.dart';

enum TransactionSort {
  newestFirst,
  oldestFirst,
  highestAmount,
  lowestAmount,
  categoryAZ,
}

final transactionSortProvider = StateProvider<TransactionSort>(
  (ref) => TransactionSort.newestFirst,
);
