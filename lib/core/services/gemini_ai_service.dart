import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:vku_ocr_expense/core/utils/receipt_parser_engine.dart';
import 'package:vku_ocr_expense/domain/entities/transaction_entity.dart';

class GeminiReceiptResult {
  final double amount;
  final DateTime date;
  final String merchantName;
  final ExpenseCategory category;
  final TransactionType type;
  final String note;

  const GeminiReceiptResult({
    required this.amount,
    required this.date,
    required this.merchantName,
    required this.category,
    required this.type,
    required this.note,
  });
}

class GeminiAiService {
  // Configured Google AI API Key
  static String get apiKey => const String.fromEnvironment(
        'GEMINI_API_KEY',
        defaultValue: 'AQ.Ab8RN6LGB8Dg35QIf34oMsEjSr4GsWFVq0D2' '_v48bWp3b08L1Q',
      );

  /// Scans receipt image using Gemini 3.5 Flash Lite Vision
  static Future<GeminiReceiptResult?> analyzeReceipt({
    required String imagePath,
    required String fallbackOcrText,
  }) async {
    try {
      final file = File(imagePath);
      String? base64Image;
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        base64Image = base64Encode(bytes);
      }

      // Use active Gemini 3.5 Flash Lite model
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash-lite:generateContent?key=$apiKey',
      );

      final prompt = '''
Bạn là chuyên gia kế toán kiểm toán hóa đơn và biên lai bán lẻ tại Việt Nam.
Nhiệm vụ: Trích xuất thông tin tài chính từ ảnh hóa đơn (hoặc text thô: "$fallbackOcrText").

QUY TẮC BẮT BUỘC VỀ SỐ TIỀN ("amount"):
1. "amount" PHẢI LÀ TỔNG SỐ TIỀN THANH TOÁN THỰC TẾ (Tổng tiền, Tổng cộng, Thành tiền, Thanh toán, Total, Grand Total).
2. TUYỆT ĐỐI KHÔNG LẤY: Số hóa đơn (HD...), Số phiếu, Mã giao dịch, Mã đơn hàng, Số bàn, STT, Tiền khách đưa (Cash), Tiền thối/Tiền thừa (Change), Mã số thuế (MST), Số điện thoại.
3. Nếu trên hóa đơn có "Tổng cộng: 150.000 đ" và "Số phiếu: 202610", thì amount PHẢI LÀ 150000. Trả về kiểu số thực (number/double), không kèm chữ hay dấu chấm phân cách ngàn.

Định dạng JSON trả về duy nhất (không bọc trong markdown ```json):
{
  "merchantName": "Tên cửa hàng/quán (VD: Highlands Coffee, WinMart, Phúc Long)",
  "amount": 145000,
  "date": "YYYY-MM-DD",
  "category": "Food" hoặc "Study" hoặc "Travel" hoặc "Gear" hoặc "Entertainment",
  "type": "expense" hoặc "income",
  "note": "Tóm tắt các món/sản phẩm đã mua"
}
''';

      final Map<String, dynamic> requestBody = {
        "contents": [
          {
            "parts": [
              {"text": prompt},
              if (base64Image != null)
                {
                  "inline_data": {
                    "mime_type": "image/jpeg",
                    "data": base64Image,
                  }
                }
            ]
          }
        ],
        "generationConfig": {
          "temperature": 0.1,
          "response_mime_type": "application/json"
        }
      };

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidate = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
        if (candidate != null) {
          final cleanJson = candidate.trim().replaceAll('```json', '').replaceAll('```', '').trim();
          final parsedJson = jsonDecode(cleanJson);

          final double amount = (parsedJson['amount'] as num?)?.toDouble() ?? 0.0;
          final String merchantName = parsedJson['merchantName'] as String? ?? 'Cửa hàng';
          DateTime date = DateTime.now();
          if (parsedJson['date'] != null) {
            try {
              date = DateTime.parse(parsedJson['date']);
            } catch (_) {}
          }
          final catStr = parsedJson['category'] as String?;
          final typeStr = (parsedJson['type'] as String?)?.toLowerCase();

          return GeminiReceiptResult(
            amount: amount,
            date: date,
            merchantName: merchantName,
            category: ExpenseCategory.fromString(catStr),
            type: typeStr == 'income' ? TransactionType.income : TransactionType.expense,
            note: parsedJson['note'] as String? ?? '',
          );
        }
      } else {
        debugPrint('Gemini API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Gemini processing exception: $e');
    }

    // Fallback using local Regex Engine if network/API fails
    final localResult = ReceiptParserEngine.parse(fallbackOcrText);
    return GeminiReceiptResult(
      amount: localResult.amount,
      date: localResult.date,
      merchantName: localResult.merchantName,
      category: localResult.suggestedCategory,
      type: TransactionType.expense,
      note: 'Nhận diện tự động bằng Regex Heuristic',
    );
  }
}
