import 'package:minimal_pocket_finance_app/models/transaction.dart';
import 'package:minimal_pocket_finance_app/repositories/transaction_repository.dart';

/// Coordinates business operations for financial transactions.
class TransactionService {
  TransactionService(this._transactionRepository);

  final TransactionRepository _transactionRepository;

  Future<List<Transaction>> getAllTransactions({int? year}) {
    return _transactionRepository.getAll(year: year);
  }

  Future<List<Transaction>> getAllIncludingTrashed() {
    return _transactionRepository.getAllIncludingTrashed();
  }

  Future<void> addTransaction(Transaction transaction) async {
    await _transactionRepository.insert(transaction);
  }

  Future<List<Transaction>> getTrashedTransactions() {
    return _transactionRepository.getTrashed();
  }

  Future<void> restoreDeletedTransaction(String id) {
    return _transactionRepository.restore(id);
  }

  Future<void> updateTransaction(Transaction transaction) {
    return _transactionRepository.update(transaction);
  }

  Future<void> deleteTransaction(String id) {
    return _transactionRepository.moveToTrash(id);
  }

  Future<void> permanentlyDeleteTransaction(String id) {
    return _transactionRepository.permanentlyDelete(id);
  }

  Future<void> emptyTrash() {
    return _transactionRepository.emptyTrash();
  }
}
