import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vku_ocr_expense/domain/entities/transaction_entity.dart';
import 'package:vku_ocr_expense/domain/repositories/transaction_repository.dart';
import 'package:vku_ocr_expense/presentation/bloc/expense_event.dart';
import 'package:vku_ocr_expense/presentation/bloc/expense_state.dart';

class ExpenseBloc extends Bloc<ExpenseEvent, ExpenseState> {
  final TransactionRepository repository;

  ExpenseBloc({required this.repository}) : super(ExpenseInitialState()) {
    on<LoadDashboardDataEvent>(_onLoadDashboardData);
    on<AddTransactionEvent>(_onAddTransaction);
    on<UpdateTransactionEvent>(_onUpdateTransaction);
    on<DeleteTransactionEvent>(_onDeleteTransaction);
    on<ClearAllTransactionsEvent>(_onClearAllTransactions);
    on<SeedSampleDataEvent>(_onSeedSampleData);
  }

  Future<void> _onSeedSampleData(
    SeedSampleDataEvent event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(ExpenseLoadingState());
    try {
      await repository.seedSampleData();
      add(LoadDashboardDataEvent());
    } catch (e) {
      emit(ExpenseErrorState('Lỗi nạp dữ liệu mẫu: $e'));
    }
  }

  Future<void> _onLoadDashboardData(
    LoadDashboardDataEvent event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(ExpenseLoadingState());
    try {
      final transactions = await repository.getAllTransactions();
      final categorySpending = await repository.getSpendingByCategory(type: TransactionType.expense);
      final weeklySpending = await repository.getWeeklySpending(type: TransactionType.expense);

      double expense = 0.0;
      double income = 0.0;

      for (final tx in transactions) {
        if (tx.type == TransactionType.expense) {
          expense += tx.amount;
        } else {
          income += tx.amount;
        }
      }

      emit(ExpenseLoadedState(
        transactions: transactions,
        categorySpending: categorySpending,
        weeklySpending: weeklySpending,
        totalExpense: expense,
        totalIncome: income,
        netBalance: income - expense,
      ));
    } catch (e) {
      emit(ExpenseErrorState('Lỗi tải dữ liệu: $e'));
    }
  }

  Future<void> _onAddTransaction(
    AddTransactionEvent event,
    Emitter<ExpenseState> emit,
  ) async {
    try {
      await repository.insertTransaction(event.transaction);
      add(LoadDashboardDataEvent());
    } catch (e) {
      emit(ExpenseErrorState('Lỗi thêm giao dịch: $e'));
    }
  }

  Future<void> _onUpdateTransaction(
    UpdateTransactionEvent event,
    Emitter<ExpenseState> emit,
  ) async {
    try {
      await repository.updateTransaction(event.transaction);
      add(LoadDashboardDataEvent());
    } catch (e) {
      emit(ExpenseErrorState('Lỗi cập nhật giao dịch: $e'));
    }
  }

  Future<void> _onDeleteTransaction(
    DeleteTransactionEvent event,
    Emitter<ExpenseState> emit,
  ) async {
    try {
      await repository.deleteTransaction(event.id);
      add(LoadDashboardDataEvent());
    } catch (e) {
      emit(ExpenseErrorState('Lỗi xóa giao dịch: $e'));
    }
  }

  Future<void> _onClearAllTransactions(
    ClearAllTransactionsEvent event,
    Emitter<ExpenseState> emit,
  ) async {
    try {
      await repository.clearAllTransactions();
      add(LoadDashboardDataEvent());
    } catch (e) {
      emit(ExpenseErrorState('Lỗi xóa dữ liệu: $e'));
    }
  }
}
