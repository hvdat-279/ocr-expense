import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:vku_ocr_expense/data/repositories/local_transaction_repository.dart';
import 'package:vku_ocr_expense/domain/entities/transaction_entity.dart';

class SampleDataService {
  /// Sinh ảnh hóa đơn chân thực bằng package:image
  static Future<String> _generateReceiptImage({
    required Directory storageDir,
    required String fileName,
    required String merchantName,
    required String invoiceNo,
    required String dateStr,
    required List<Map<String, String>> items,
    required String totalFormatted,
  }) async {
    final image = img.Image(width: 440, height: 620);
    // Màu giấy hóa đơn hơi kem nhẹ tự nhiên
    img.fill(image, color: img.ColorRgb8(248, 248, 245));

    // Khung viền hóa đơn
    img.drawRect(
      image,
      x1: 15,
      y1: 15,
      x2: 425,
      y2: 605,
      color: img.ColorRgb8(210, 210, 205),
    );

    // Tiêu đề cửa hàng
    img.drawString(
      image,
      merchantName.toUpperCase(),
      font: img.arial24,
      x: 35,
      y: 35,
      color: img.ColorRgb8(25, 25, 25),
    );

    // Số hóa đơn và thời gian
    img.drawString(
      image,
      'HD: $invoiceNo  |  Ngay: $dateStr',
      font: img.arial14,
      x: 35,
      y: 75,
      color: img.ColorRgb8(100, 100, 100),
    );

    // Đường kẻ phân cách nét đứt
    for (int x = 35; x < 405; x += 10) {
      img.drawLine(
        image,
        x1: x,
        y1: 105,
        x2: x + 6,
        y2: 105,
        color: img.ColorRgb8(160, 160, 160),
      );
    }

    // Danh sách các món / sản phẩm
    int currentY = 125;
    for (var item in items) {
      final name = item['name'] ?? '';
      final price = item['price'] ?? '';

      img.drawString(
        image,
        name,
        font: img.arial14,
        x: 35,
        y: currentY,
        color: img.ColorRgb8(45, 45, 45),
      );

      img.drawString(
        image,
        price,
        font: img.arial14,
        x: 310,
        y: currentY,
        color: img.ColorRgb8(45, 45, 45),
      );

      currentY += 32;
    }

    // Đường kẻ tổng kết
    for (int x = 35; x < 405; x += 8) {
      img.drawLine(
        image,
        x1: x,
        y1: currentY + 10,
        x2: x + 4,
        y2: currentY + 10,
        color: img.ColorRgb8(120, 120, 120),
      );
    }

    // Tổng tiền thanh toán
    currentY += 28;
    img.drawString(
      image,
      'TONG CONG / TOTAL:',
      font: img.arial14,
      x: 35,
      y: currentY,
      color: img.ColorRgb8(30, 30, 30),
    );

    img.drawString(
      image,
      totalFormatted,
      font: img.arial24,
      x: 240,
      y: currentY - 5,
      color: img.ColorRgb8(190, 30, 30),
    );

    // Lời cảm ơn và mã vạch mô phỏng
    currentY += 50;
    img.drawString(
      image,
      'CAM ON QUY KHACH - HEN GAP LAI!',
      font: img.arial14,
      x: 75,
      y: currentY,
      color: img.ColorRgb8(120, 120, 120),
    );

    // Vẽ mã vạch (Barcode mô phỏng)
    currentY += 35;
    for (int b = 60; b < 380; b += 7) {
      final width = (b % 3 == 0) ? 3 : 1;
      for (int w = 0; w < width; w++) {
        img.drawLine(
          image,
          x1: b + w,
          y1: currentY,
          x2: b + w,
          y2: currentY + 45,
          color: img.ColorRgb8(40, 40, 40),
        );
      }
    }

    final jpgBytes = img.encodeJpg(image, quality: 90);
    final filePath = p.join(storageDir.path, fileName);
    final file = File(filePath);
    await file.writeAsBytes(jpgBytes);
    return filePath;
  }

  /// Nạp danh sách giao dịch phong phú kèm ảnh cho các ngày trước
  static Future<void> seedRealisticData(LocalTransactionRepository repository) async {
    Directory storageDir;
    try {
      storageDir = await getApplicationDocumentsDirectory();
    } catch (_) {
      storageDir = Directory.current;
    }

    final imagesDir = Directory(p.join(storageDir.path, 'receipt_images'));
    if (!imagesDir.existsSync()) {
      imagesDir.createSync(recursive: true);
    }

    final now = DateTime.now();

    // 1. Hôm nay - Highlands Coffee (Ăn uống)
    final imgToday1 = await _generateReceiptImage(
      storageDir: imagesDir,
      fileName: 'highlands_${now.millisecondsSinceEpoch}.jpg',
      merchantName: 'Highlands Coffee',
      invoiceNo: 'HL-92813',
      dateStr: DateFormat('dd/MM/yyyy HH:mm').format(now),
      items: [
        {'name': '1 Freeze Tra Xanh L', 'price': '65.000 d'},
        {'name': '1 Phin Sua Da Size M', 'price': '45.000 d'},
        {'name': '1 Banh Mi Que Ga', 'price': '25.000 d'},
      ],
      totalFormatted: '135.000 VND',
    );

    await repository.insertTransaction(
      TransactionEntity(
        amount: 135000,
        date: now.subtract(const Duration(hours: 3)),
        merchantName: 'Highlands Coffee',
        category: ExpenseCategory.food,
        type: TransactionType.expense,
        receiptImagePath: imgToday1,
        note: 'Cà phê học bài cùng nhóm bạn tại quán',
      ),
    );

    // 2. Hôm nay - Bách Hóa Xanh (Ăn uống)
    final imgToday2 = await _generateReceiptImage(
      storageDir: imagesDir,
      fileName: 'bhx_${now.millisecondsSinceEpoch}.jpg',
      merchantName: 'Bach Hoa Xanh',
      invoiceNo: 'BHX-44120',
      dateStr: DateFormat('dd/MM/yyyy HH:mm').format(now.subtract(const Duration(hours: 6))),
      items: [
        {'name': '1 Thung Sua Tuoi 180ml', 'price': '62.000 d'},
        {'name': '2 Banh Quy Oreo', 'price': '30.000 d'},
      ],
      totalFormatted: '92.000 VND',
    );

    await repository.insertTransaction(
      TransactionEntity(
        amount: 92000,
        date: now.subtract(const Duration(hours: 6)),
        merchantName: 'Bách Hóa Xanh',
        category: ExpenseCategory.food,
        type: TransactionType.expense,
        receiptImagePath: imgToday2,
        note: 'Mua sữa và bánh ăn nhẹ ôn thi',
      ),
    );

    // 3. Hôm qua - Nhà Sách Fahasa (Học tập)
    final yesterday = now.subtract(const Duration(days: 1));
    final imgYesterday = await _generateReceiptImage(
      storageDir: imagesDir,
      fileName: 'fahasa_${yesterday.millisecondsSinceEpoch}.jpg',
      merchantName: 'Nha Sach Fahasa',
      invoiceNo: 'FAH-10842',
      dateStr: DateFormat('dd/MM/yyyy HH:mm').format(yesterday),
      items: [
        {'name': '1 Sach Lap Trinh Flutter', 'price': '135.000 d'},
        {'name': '2 Tap Vo Sinh Vien 200T', 'price': '36.000 d'},
        {'name': '3 But Bi Gel Den', 'price': '24.000 d'},
      ],
      totalFormatted: '195.000 VND',
    );

    await repository.insertTransaction(
      TransactionEntity(
        amount: 195000,
        date: yesterday,
        merchantName: 'Nhà Sách Fahasa',
        category: ExpenseCategory.study,
        type: TransactionType.expense,
        receiptImagePath: imgYesterday,
        note: 'Tài liệu giáo trình học phần Cross-Platform Mobile VKU',
      ),
    );

    // 4. 2 ngày trước - Grab Bike (Đi lại)
    final twoDaysAgo = now.subtract(const Duration(days: 2));
    final imgTwoDays = await _generateReceiptImage(
      storageDir: imagesDir,
      fileName: 'grab_${twoDaysAgo.millisecondsSinceEpoch}.jpg',
      merchantName: 'Grab Bike Vietnam',
      invoiceNo: 'GRB-77291',
      dateStr: DateFormat('dd/MM/yyyy HH:mm').format(twoDaysAgo),
      items: [
        {'name': 'Cuoc xe den Truong DH VKU', 'price': '38.000 d'},
        {'name': 'Phi cau duong / ung dung', 'price': '4.000 d'},
      ],
      totalFormatted: '42.000 VND',
    );

    await repository.insertTransaction(
      TransactionEntity(
        amount: 42000,
        date: twoDaysAgo,
        merchantName: 'Grab Bike',
        category: ExpenseCategory.travel,
        type: TransactionType.expense,
        receiptImagePath: imgTwoDays,
        note: 'Di chuyển từ trọ đến giảng đường khu C',
      ),
    );

    // 5. 3 ngày trước - Thế Giới Di Động (Thiết bị)
    final threeDaysAgo = now.subtract(const Duration(days: 3));
    final imgThreeDays = await _generateReceiptImage(
      storageDir: imagesDir,
      fileName: 'tgdd_${threeDaysAgo.millisecondsSinceEpoch}.jpg',
      merchantName: 'The Gioi Di Dong',
      invoiceNo: 'TGDD-88192',
      dateStr: DateFormat('dd/MM/yyyy HH:mm').format(threeDaysAgo),
      items: [
        {'name': '1 Chuot Quang Bluetooth', 'price': '180.000 d'},
        {'name': '1 Cap Sac Type-C 65W', 'price': '90.000 d'},
      ],
      totalFormatted: '270.000 VND',
    );

    await repository.insertTransaction(
      TransactionEntity(
        amount: 270000,
        date: threeDaysAgo,
        merchantName: 'Thế Giới Di Động',
        category: ExpenseCategory.gear,
        type: TransactionType.expense,
        receiptImagePath: imgThreeDays,
        note: 'Mua phụ kiện chuột và cáp sạc laptop làm đồ án',
      ),
    );

    // 6. 4 ngày trước - Vé xem phim CGV (Giải trí)
    final fourDaysAgo = now.subtract(const Duration(days: 4));
    final imgFourDays = await _generateReceiptImage(
      storageDir: imagesDir,
      fileName: 'cgv_${fourDaysAgo.millisecondsSinceEpoch}.jpg',
      merchantName: 'CGV Cinemas Da Nang',
      invoiceNo: 'CGV-33129',
      dateStr: DateFormat('dd/MM/yyyy HH:mm').format(fourDaysAgo),
      items: [
        {'name': '2 Ve Xem Phim 2D 19:30', 'price': '160.000 d'},
        {'name': '1 Combo Bap Nuoc Vua', 'price': '65.000 d'},
      ],
      totalFormatted: '225.000 VND',
    );

    await repository.insertTransaction(
      TransactionEntity(
        amount: 225000,
        date: fourDaysAgo,
        merchantName: 'Rạp Chiếu Phim CGV',
        category: ExpenseCategory.entertainment,
        type: TransactionType.expense,
        receiptImagePath: imgFourDays,
        note: 'Xem phim thư giãn cuối tuần',
      ),
    );

    // 7. Khoản Tiền Thu: Lương trợ cấp / Làm thêm đầu tuần để số dư dương đẹp mắt
    final fiveDaysAgo = now.subtract(const Duration(days: 5));
    await repository.insertTransaction(
      TransactionEntity(
        amount: 2500000,
        date: fiveDaysAgo,
        merchantName: 'Công Ty CP Công Nghệ VKU',
        category: ExpenseCategory.salary,
        type: TransactionType.income,
        receiptImagePath: '',
        note: 'Tiền thưởng dự án & trợ cấp thực tập tháng này',
      ),
    );
  }

  /// Xuất danh sách giao dịch sang định dạng CSV (Hỗ trợ mở bằng Excel không lỗi font UTF-8)
  static String generateCsv(List<TransactionEntity> transactions) {
    final buffer = StringBuffer();
    // Thêm ký tự UTF-8 BOM (\uFEFF) để Excel trên Windows hiển thị đúng tiếng Việt
    buffer.writeln('\uFEFF"ID","Ngày Giao Dịch","Cửa Hàng / Đơn Vị","Danh Mục","Loại","Số Tiền (VND)","Ghi Chú"');

    final dateFormatter = DateFormat('dd/MM/yyyy HH:mm');
    for (final tx in transactions) {
      final id = tx.id ?? 0;
      final date = dateFormatter.format(tx.date);
      final merchant = tx.merchantName.replaceAll('"', '""');
      final category = tx.category.displayName;
      final type = tx.type.displayName;
      final amount = tx.amount.toStringAsFixed(0);
      final note = tx.note.replaceAll('"', '""');

      buffer.writeln('"$id","$date","$merchant","$category","$type","$amount","$note"');
    }

    return buffer.toString();
  }

  /// Lưu file CSV vào bộ nhớ máy
  static Future<File> exportCsvToFile(List<TransactionEntity> transactions) async {
    Directory exportDir;
    try {
      exportDir = await getApplicationDocumentsDirectory();
    } catch (_) {
      exportDir = Directory.current;
    }

    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File(p.join(exportDir.path, 'vku_sotietkiem_export_$timestamp.csv'));
    final csvContent = generateCsv(transactions);
    return await file.writeAsString(csvContent);
  }
}
