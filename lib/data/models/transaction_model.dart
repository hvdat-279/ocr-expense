import 'package:vku_ocr_expense/domain/entities/transaction_entity.dart';

class TransactionModel extends TransactionEntity {
  const TransactionModel({
    super.id,
    required super.amount,
    required super.date,
    required super.merchantName,
    required super.category,
    super.type = TransactionType.expense,
    required super.receiptImagePath,
    super.note = '',
  });

  factory TransactionModel.fromEntity(TransactionEntity entity) {
    return TransactionModel(
      id: entity.id,
      amount: entity.amount,
      date: entity.date,
      merchantName: entity.merchantName,
      category: entity.category,
      type: entity.type,
      receiptImagePath: entity.receiptImagePath,
      note: entity.note,
    );
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      merchantName: map['merchant_name'] as String,
      category: ExpenseCategory.fromString(map['category'] as String?),
      type: (map['type'] as String?) == 'income' ? TransactionType.income : TransactionType.expense,
      receiptImagePath: map['receipt_image_path'] as String? ?? '',
      note: map['note'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'amount': amount,
      'date': date.toIso8601String(),
      'merchant_name': merchantName,
      'category': category.name,
      'type': type.name,
      'receipt_image_path': receiptImagePath,
      'note': note,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }
}
