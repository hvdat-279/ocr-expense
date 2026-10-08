import 'package:vku_ocr_expense/domain/entities/transaction_entity.dart';

class ParsedReceiptResult {
  final double amount;
  final DateTime date;
  final String merchantName;
  final ExpenseCategory suggestedCategory;
  final String rawText;

  const ParsedReceiptResult({
    required this.amount,
    required this.date,
    required this.merchantName,
    required this.suggestedCategory,
    required this.rawText,
  });

  @override
  String toString() {
    return 'ParsedReceiptResult(amount: $amount, date: $date, merchant: $merchantName, category: ${suggestedCategory.name})';
  }
}

class ReceiptParserEngine {
  /// Main entry point to parse raw OCR text into receipt data
  static ParsedReceiptResult parse(String rawText) {
    if (rawText.trim().isEmpty) {
      return ParsedReceiptResult(
        amount: 0.0,
        date: DateTime.now(),
        merchantName: 'Unknown Merchant',
        suggestedCategory: ExpenseCategory.food,
        rawText: rawText,
      );
    }

    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final merchantName = _extractMerchantName(lines);
    final date = _extractDate(rawText);
    final amount = _extractAmount(rawText, lines);
    final suggestedCategory = _classifyCategory(merchantName, rawText);

    return ParsedReceiptResult(
      amount: amount,
      date: date,
      merchantName: merchantName,
      suggestedCategory: suggestedCategory,
      rawText: rawText,
    );
  }

  /// Extracts the merchant / store name heuristics:
  /// - Usually line 0 or 1
  /// - Excludes keywords like "hoa don", "receipt", "phieu thanh toan", "tel", "dia chi", "ngay", etc.
  /// - Prefers uppercase or significant title text
  static String _extractMerchantName(List<String> lines) {
    final excludePattern = RegExp(
      r'(hóa đơn|phiếu|thanh toán|receipt|bill|invoice|ngày|date|giờ|time|thu ngân|cashier|bàn|table|địa chỉ|address|tel|sđt|hotline|mst|stt)',
      caseSensitive: false,
    );

    for (int i = 0; i < lines.length && i < 5; i++) {
      final line = lines[i];
      if (line.length < 3) continue;
      if (excludePattern.hasMatch(line)) continue;

      // Filter out lines that are purely numbers or special characters
      if (RegExp(r'^[\d\s\.\,\:\-\/\#]+$').hasMatch(line)) continue;

      return _cleanMerchantName(line);
    }

    if (lines.isNotEmpty) {
      return _cleanMerchantName(lines.first);
    }
    return 'Hóa Đơn Mua Hàng';
  }

  static String _cleanMerchantName(String name) {
    return name
        .replaceAll(RegExp(r'^[^\p{L}\p{N}]+|[^\p{L}\p{N}]+$', unicode: true), '')
        .trim();
  }

  /// Extracts date matching DD/MM/YYYY or DD-MM-YYYY or YYYY-MM-DD
  /// Defaults to today if not found
  static DateTime _extractDate(String text) {
    // Pattern 1: DD/MM/YYYY or DD-MM-YYYY or DD.MM.YYYY
    final dmyPattern = RegExp(
      r'\b(0?[1-9]|[12][0-9]|3[01])[\/\-\.](0?[1-9]|1[012])[\/\-\.](20\d\d)\b',
    );
    final match = dmyPattern.firstMatch(text);
    if (match != null) {
      try {
        final day = int.parse(match.group(1)!);
        final month = int.parse(match.group(2)!);
        final year = int.parse(match.group(3)!);
        return DateTime(year, month, day);
      } catch (_) {}
    }

    // Pattern 2: YYYY-MM-DD
    final ymdPattern = RegExp(
      r'\b(20\d\d)[\/\-\.](0?[1-9]|1[012])[\/\-\.](0?[1-9]|[12][0-9]|3[01])\b',
    );
    final matchYmd = ymdPattern.firstMatch(text);
    if (matchYmd != null) {
      try {
        final year = int.parse(matchYmd.group(1)!);
        final month = int.parse(matchYmd.group(2)!);
        final day = int.parse(matchYmd.group(3)!);
        return DateTime(year, month, day);
      } catch (_) {}
    }

    return DateTime.now();
  }

  /// Heuristics for Vietnamese currency total amount:
  /// 1. Prioritize lines near: "Tổng cộng", "Tổng tiền", "Thanh toán", "Total", "Grand Total"
  /// 2. Parse Vietnamese formatting: 150.000, 150,000, 150.000đ, 150000 VND
  /// 3. If no anchor keyword found, take the largest numeric monetary figure detected
  static double _extractAmount(String fullText, List<String> lines) {
    final anchorPattern = RegExp(
      r'(t[oổ]ng\s*c[oộ]ng|t[oổ]ng\s*ti[eề]n|thanh\s*to[aá]n|ph[aả]i\s*tr[aả]|c[aầ]n\s*tr[aả]|total\s*(due|amount)?|grand\s*total|\btotal\b)',
      caseSensitive: false,
    );

    // Check lines near anchors
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (anchorPattern.hasMatch(line)) {
        // Search inside this line first
        final lineAmount = _findLargestNumberInLine(line);
        if (lineAmount > 0) {
          return lineAmount;
        }
        // If not in this line, inspect next 2 lines
        for (int j = i + 1; j <= i + 2 && j < lines.length; j++) {
          final nextAmount = _findLargestNumberInLine(lines[j]);
          if (nextAmount > 0) {
            return nextAmount;
          }
        }
      }
    }

    // Fallback: search all monetary expressions in the entire text and choose the reasonable maximum
    double maxAmount = 0.0;
    for (final line in lines) {
      // Don't consider telephone, date, invoice IDs, order number, table number lines as amounts
      if (RegExp(r'(tel|sđt|phone|ngày|date|time|giờ|đ/c|mst|hđ|hd|phiếu|phieu|order|bill|stt|bàn|table|pos|thu\s*ngân|nv|cashier)', caseSensitive: false).hasMatch(line)) {
        continue;
      }
      final parsed = _findLargestNumberInLine(line);
      if (parsed > maxAmount && parsed <= 500000000) { // Reasonable cap (500M VND)
        maxAmount = parsed;
      }
    }

    return maxAmount;
  }

  /// Parses numbers from a string line with formats: 150.000, 150,000, 150000
  static double _findLargestNumberInLine(String line) {
    // Regex matches numbers with dot or comma thousands separators, optionally ending with đ, VND, vnđ
    // e.g.: 150.000 đ, 150,000VND, 25.000, 1.250.000
    final moneyRegex = RegExp(
      r'(?:(?:\b\d{1,3}(?:[.,]\d{3})+(?:[.,]\d{2})?)|(?:\b\d{4,9}\b))(?:\s*(?:đ|vnd|vnđ|d))?',
      caseSensitive: false,
    );

    final matches = moneyRegex.allMatches(line);
    double maxInLine = 0.0;

    for (final match in matches) {
      String cleanStr = match.group(0)!
          .toLowerCase()
          .replaceAll('đ', '')
          .replaceAll('vnd', '')
          .replaceAll('vnđ', '')
          .replaceAll('d', '')
          .trim();

      // Normalize Vietnamese thousands separators:
      // "150.000" or "150,000" -> 150000
      // Check if it has 2 decimals at the end like 150.000,00 or 150,000.00
      if (cleanStr.contains('.') && cleanStr.contains(',')) {
        if (cleanStr.lastIndexOf(',') > cleanStr.lastIndexOf('.')) {
          // European/VN style: 150.000,50
          cleanStr = cleanStr.replaceAll('.', '').replaceAll(',', '.');
        } else {
          // US style: 150,000.50
          cleanStr = cleanStr.replaceAll(',', '');
        }
      } else if (cleanStr.contains('.') && !cleanStr.contains(',')) {
        // e.g. 150.000 or 1.250.000
        cleanStr = cleanStr.replaceAll('.', '');
      } else if (cleanStr.contains(',') && !cleanStr.contains('.')) {
        // e.g. 150,000
        cleanStr = cleanStr.replaceAll(',', '');
      }

      final parsed = double.tryParse(cleanStr) ?? 0.0;
      if (parsed > maxInLine) {
        maxInLine = parsed;
      }
    }

    return maxInLine;
  }

  /// Smart categorization based on keywords found in store name or receipt items
  static ExpenseCategory _classifyCategory(String merchant, String fullText) {
    final combined = '$merchant $fullText'.toLowerCase();

    // Food & Dining keywords
    if (RegExp(r'(cafe|coffee|highlands|phúc long|starbucks|trà sữa|cơm|phở|bún|bánh|quán|nhà hàng|restaurant|lẩu|nướng|pizza|kfc|lotteria|mcdonald|food|bbq|bếp|chợ|coopmart|vinmart|winmart|bách hóa|siêu thị|circle k|7-eleven|ministop|gs25)').hasMatch(combined)) {
      return ExpenseCategory.food;
    }

    // Study & Education keywords
    if (RegExp(r'(nhà sách|fahasa|phương nam|sách|book|tiệm sách|giáo trình|văn phòng phẩm|bút|vở|study|university|trường|học phí|khóa học|course|stationery)').hasMatch(combined)) {
      return ExpenseCategory.study;
    }

    // Travel & Transport keywords
    if (RegExp(r'(grab|be\b|gojek|xanh sm|taxi|mai linh|vé xe|vé tàu|vé máy bay|flight|bến xe|xăng|petrolimex|gas|pvoil|gửi xe|bãi xe|hotel|khách sạn|homestay|travel)').hasMatch(combined)) {
      return ExpenseCategory.travel;
    }

    // Tech & Gear keywords
    if (RegExp(r'(fpt|thế giới di động|tgdd|điện máy|cellphones|hoangha|gear|laptop|chuột|bàn phím|tai nghe|phone|apple|samsung|shopee|lazada|tiki|túi|balo)').hasMatch(combined)) {
      return ExpenseCategory.gear;
    }

    // Entertainment keywords
    if (RegExp(r'(cgv|lotte cinema|bhd|galaxy|cinema|rạp|phim|game|bida|billiard|karaoke|bar|pub|vé vào cổng|công viên|zoo|bảo tàng|entertainment)').hasMatch(combined)) {
      return ExpenseCategory.entertainment;
    }

    return ExpenseCategory.food;
  }
}
