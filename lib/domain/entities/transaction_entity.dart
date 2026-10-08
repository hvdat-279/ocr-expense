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
        return 'Ăn uống';
      case ExpenseCategory.study:
        return 'Học tập';
      case ExpenseCategory.travel:
        return 'Đi lại';
      case ExpenseCategory.gear:
        return 'Thiết bị';
      case ExpenseCategory.entertainment:
        return 'Giải trí';
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
    final lower = name.toLowerCase().trim();
    for (var cat in ExpenseCategory.values) {
      if (cat.name.toLowerCase() == lower ||
          cat.displayName.toLowerCase() == lower) {
        return cat;
      }
    }
    if (lower.contains('ăn') || lower.contains('uống') || lower.contains('food') || lower.contains('cà phê') || lower.contains('coffee')) return ExpenseCategory.food;
    if (lower.contains('học') || lower.contains('study') || lower.contains('sách') || lower.contains('vở') || lower.contains('book')) return ExpenseCategory.study;
    if (lower.contains('đi') || lower.contains('travel') || lower.contains('xăng') || lower.contains('xe') || lower.contains('grab')) return ExpenseCategory.travel;
    if (lower.contains('thiết bị') || lower.contains('gear') || lower.contains('máy') || lower.contains('phụ kiện')) return ExpenseCategory.gear;
    if (lower.contains('giải trí') || lower.contains('entertainment') || lower.contains('phim') || lower.contains('game')) return ExpenseCategory.entertainment;
    if (lower.contains('lương') || lower.contains('salary') || lower.contains('thu nhập')) return ExpenseCategory.salary;
    if (lower.contains('quà') || lower.contains('gift') || lower.contains('trợ cấp')) return ExpenseCategory.gift;
    return ExpenseCategory.other;
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
