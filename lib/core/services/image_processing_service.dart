import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ImageProcessingService {
  /// Compresses the original captured image and saves a lightweight thumbnail
  /// in the application's document directory.
  static Future<String> createThumbnail(String sourceImagePath) async {
    try {
      final file = File(sourceImagePath);
      if (!await file.exists()) {
        return sourceImagePath;
      }

      final Uint8List bytes = await file.readAsBytes();
      final img.Image? decoded = img.decodeImage(bytes);

      if (decoded == null) {
        return sourceImagePath;
      }

      // Resize image down to max width 800 while maintaining aspect ratio
      img.Image thumbnail = decoded;
      if (decoded.width > 800) {
        thumbnail = img.copyResize(decoded, width: 800);
      }

      final Directory appDir = await getApplicationDocumentsDirectory();
      final String thumbDir = p.join(appDir.path, 'receipt_thumbnails');
      await Directory(thumbDir).create(recursive: true);

      final String thumbPath = p.join(
        thumbDir,
        'thumb_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      final compressedBytes = img.encodeJpg(thumbnail, quality: 75);
      final thumbFile = File(thumbPath);
      await thumbFile.writeAsBytes(compressedBytes);

      return thumbFile.path;
    } catch (e) {
      // Fallback to original image path in case of encoding issues
      return sourceImagePath;
    }
  }
}
