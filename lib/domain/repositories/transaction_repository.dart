import 'package:vku_ocr_expense/domain/entities/transaction_entity.dart';

abstract class TransactionRepository {
  Future<List<TransactionEntity>> getAllTransactions();
  Future<TransactionEntity?> getTransactionById(int id);
  Future<int> insertTransaction(TransactionEntity transaction);
  Future<int> updateTransaction(TransactionEntity transaction);
  Future<int> deleteTransaction(int id);
  Future<void> clearAllTransactions();
  Future<Map<ExpenseCategory, double>> getSpendingByCategory({TransactionType type = TransactionType.expense});
  Future<Map<String, double>> getWeeklySpending({TransactionType type = TransactionType.expense});
  Future<List<TransactionEntity>> getTransactionsByDate(DateTime date);
}
