import 'package:equatable/equatable.dart';
import 'package:vku_ocr_expense/domain/entities/transaction_entity.dart';

abstract class ExpenseState extends Equatable {
  const ExpenseState();
  @override
  List<Object?> get props => [];
}

class ExpenseInitialState extends ExpenseState {}

class ExpenseLoadingState extends ExpenseState {}

class ExpenseLoadedState extends ExpenseState {
  final List<TransactionEntity> transactions;
  final Map<ExpenseCategory, double> categorySpending;
  final Map<String, double> weeklySpending;
  final double totalExpense;
  final double totalIncome;
  final double netBalance;

  const ExpenseLoadedState({
    required this.transactions,
    required this.categorySpending,
    required this.weeklySpending,
    required this.totalExpense,
    required this.totalIncome,
    required this.netBalance,
  });

  @override
  List<Object?> get props => [
        transactions,
        categorySpending,
        weeklySpending,
        totalExpense,
        totalIncome,
        netBalance,
      ];
}

class ExpenseErrorState extends ExpenseState {
  final String message;
  const ExpenseErrorState(this.message);
  @override
  List<Object?> get props => [message];
}
