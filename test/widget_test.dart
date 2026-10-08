import 'package:flutter_test/flutter_test.dart';
import 'package:vku_ocr_expense/core/utils/receipt_parser_engine.dart';
import 'package:vku_ocr_expense/domain/entities/transaction_entity.dart';

void main() {
  group('ReceiptParserEngine Heuristics Tests', () {
    test('Correctly parses total amount with Vietnamese currency format', () {
      const sampleOcrText = '''
HIGHLANDS COFFEE
123 Nguyen Van Linh, Da Nang
HD: 0092384
Ngay: 07/10/2026 14:30
1 Freeze Tra Xanh     65.000 đ
1 Phin Sua Da Size L  45.000 đ
1 Banh Mi Thit Nuong  35.000 đ
--------------------------------
Tong cong: 145.000 VND
Tien mat: 200.000 VND
Tien thua: 55.000 VND
''';

      final result = ReceiptParserEngine.parse(sampleOcrText);

      expect(result.amount, 145000.0);
      expect(result.merchantName, 'HIGHLANDS COFFEE');
      expect(result.suggestedCategory, ExpenseCategory.food);
      expect(result.date.day, 7);
      expect(result.date.month, 10);
      expect(result.date.year, 2026);
    });

    test('Parses supermarket invoice with date and bookstore category', () {
      const sampleText = '''
NHA SACH FAHASA
Dia chi: 300 Le Duan, Da Nang
Ngay lap: 15/09/2026
Sach Lap Trinh Flutter: 120.000
Vo Ke Ngang 200T: 25.000
Thanh toan: 145.000 đ
''';

      final result = ReceiptParserEngine.parse(sampleText);
      expect(result.amount, 145000.0);
      expect(result.merchantName, 'NHA SACH FAHASA');
      expect(result.suggestedCategory, ExpenseCategory.study);
      expect(result.date.day, 15);
      expect(result.date.month, 9);
      expect(result.date.year, 2026);
    });
  });
}
