import 'package:equatable/equatable.dart';
import 'package:vku_ocr_expense/domain/entities/transaction_entity.dart';

abstract class ExpenseEvent extends Equatable {
  const ExpenseEvent();
  @override
  List<Object?> get props => [];
}

class LoadDashboardDataEvent extends ExpenseEvent {}

class AddTransactionEvent extends ExpenseEvent {
  final TransactionEntity transaction;
  const AddTransactionEvent(this.transaction);
  @override
  List<Object?> get props => [transaction];
}

class UpdateTransactionEvent extends ExpenseEvent {
  final TransactionEntity transaction;
  const UpdateTransactionEvent(this.transaction);
  @override
  List<Object?> get props => [transaction];
}

class DeleteTransactionEvent extends ExpenseEvent {
  final int id;
  const DeleteTransactionEvent(this.id);
  @override
  List<Object?> get props => [id];
}

class ClearAllTransactionsEvent extends ExpenseEvent {}

