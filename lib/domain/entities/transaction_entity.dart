import 'package:equatable/equatable.dart';

enum TransactionType {
  expense,
  income;

  String get displayName => this == TransactionType.expense ? 'Chi tiêu' : 'Thu nhập';
}

enum ExpenseCategory {
  food,
  study,
  travel,
  gear,
  entertainment,
  salary,
  gift,
  other;

  String get displayName {
    switch (this) {
      case ExpenseCategory.food:
        return 'Food';
      case ExpenseCategory.study:
        return 'Study';
      case ExpenseCategory.travel:
        return 'Travel';
      case ExpenseCategory.gear:
        return 'Gear';
      case ExpenseCategory.entertainment:
        return 'Entertainment';
      case ExpenseCategory.salary:
        return 'Lương / Thưởng';
      case ExpenseCategory.gift:
        return 'Quà tặng / Trợ cấp';
      case ExpenseCategory.other:
        return 'Khác';
    }
  }

  static ExpenseCategory fromString(String? name) {
    if (name == null) return ExpenseCategory.food;
    for (var cat in ExpenseCategory.values) {
      if (cat.name.toLowerCase() == name.toLowerCase() ||
          cat.displayName.toLowerCase() == name.toLowerCase()) {
        return cat;
      }
    }
    return ExpenseCategory.food;
  }
}

class TransactionEntity extends Equatable {
  final int? id;
  final double amount;
  final DateTime date;
  final String merchantName;
  final ExpenseCategory category;
  final TransactionType type;
  final String receiptImagePath;
  final String note;

  const TransactionEntity({
    this.id,
    required this.amount,
    required this.date,
    required this.merchantName,
    required this.category,
    this.type = TransactionType.expense,
    required this.receiptImagePath,
    this.note = '',
  });

  TransactionEntity copyWith({
    int? id,
    double? amount,
    DateTime? date,
    String? merchantName,
    ExpenseCategory? category,
    TransactionType? type,
    String? receiptImagePath,
    String? note,
  }) {
    return TransactionEntity(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      merchantName: merchantName ?? this.merchantName,
      category: category ?? this.category,
      type: type ?? this.type,
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
      note: note ?? this.note,
    );
  }

  @override
  List<Object?> get props => [
        id,
        amount,
        date,
        merchantName,
        category,
        type,
        receiptImagePath,
        note,
      ];
}
