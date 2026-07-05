import 'package:flutter_riverpod/flutter_riverpod.dart';

enum TransactionFilter { all, income, expense }

final transactionFilterProvider = StateProvider<TransactionFilter>(
  (ref) => TransactionFilter.all,
);
