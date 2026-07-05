import 'package:akm_finance_manager/models/transaction.dart';
import 'package:akm_finance_manager/repositories/transaction_repository.dart';

/// Coordinates business operations for financial transactions.
class TransactionService {
  TransactionService(this._transactionRepository);

  final TransactionRepository _transactionRepository;

  Future<List<Transaction>> getAllTransactions() {
    return _transactionRepository.getAll();
  }

  Future<void> addTransaction(Transaction transaction) async {
    await _transactionRepository.insert(transaction);
  }

  Future<void> updateTransaction(Transaction transaction) {
    return _transactionRepository.update(transaction);
  }

  Future<void> deleteTransaction(int id) {
    return _transactionRepository.delete(id);
  }
}
