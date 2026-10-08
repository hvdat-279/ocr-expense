import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vku_ocr_expense/core/services/gemini_ai_service.dart';
import 'package:vku_ocr_expense/core/services/image_processing_service.dart';
import 'package:vku_ocr_expense/core/services/ocr_service.dart';
import 'package:vku_ocr_expense/core/utils/receipt_parser_engine.dart';
import 'package:vku_ocr_expense/domain/entities/transaction_entity.dart';
import 'package:vku_ocr_expense/presentation/screens/review_receipt_screen.dart';

class CameraScannerScreen extends StatefulWidget {
  const CameraScannerScreen({super.key});

  @override
  State<CameraScannerScreen> createState() => _CameraScannerScreenState();
}

class _CameraScannerScreenState extends State<CameraScannerScreen> {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isFlashOn = false;
  bool _isProcessing = false;
  String _statusMessage = 'Căn chỉnh hóa đơn vào khung';
  final OcrService _ocrService = OcrService();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        final backCamera = _cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => _cameras.first,
        );

        _cameraController = CameraController(
          backCamera,
          ResolutionPreset.high,
          enableAudio: false,
        );

        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    try {
      final newFlash = !_isFlashOn;
      await _cameraController!.setFlashMode(newFlash ? FlashMode.torch : FlashMode.off);
      HapticFeedback.selectionClick();
      setState(() {
        _isFlashOn = newFlash;
      });
    } catch (e) {
      debugPrint('Flash error: $e');
    }
  }

  Future<void> _handleTapToFocus(TapDownDetails details, BoxConstraints constraints) async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    try {
      final offset = Offset(
        details.localPosition.dx / constraints.maxWidth,
        details.localPosition.dy / constraints.maxHeight,
      );
      await _cameraController!.setFocusPoint(offset);
      HapticFeedback.lightImpact();
    } catch (e) {
      debugPrint('Focus error: $e');
    }
  }

  Future<void> _captureAndProcess() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _isProcessing) return;

    try {
      setState(() {
        _isProcessing = true;
        _statusMessage = 'Đang chụp & gọi AI nhận diện...';
      });
      HapticFeedback.mediumImpact();

      final XFile photo = await _cameraController!.takePicture();
      await _processImage(photo.path);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi chụp ảnh: $e')),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isProcessing) return;
    try {
      final XFile? picked = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() {
          _isProcessing = true;
          _statusMessage = 'AI đang quét chi tiết hóa đơn...';
        });
        await _processImage(picked.path);
      }
    } catch (e) {
      debugPrint('Pick image error: $e');
    }
  }

  Future<void> _processImage(String rawPath) async {
    try {
      // 1. OCR text recognition on-device as backup
      final rawOcrText = await _ocrService.recognizeText(rawPath);

      // 2. Call Gemini Vision AI for high-accuracy parsing
      setState(() {
        _statusMessage = 'Đang tính toán chính xác số tiền...';
      });
      final geminiResult = await GeminiAiService.analyzeReceipt(
        imagePath: rawPath,
        fallbackOcrText: rawOcrText,
      );

      // 3. Compress thumbnail for local storage
      final thumbnailPath = await ImageProcessingService.createThumbnail(rawPath);

      // 4. Haptic feedback on success
      HapticFeedback.heavyImpact();

      if (!mounted) return;
      final navigator = Navigator.of(context);
      setState(() {
        _isProcessing = false;
        _statusMessage = 'Căn chỉnh hóa đơn vào khung';
      });

      // Navigate to Review Screen
      await navigator.push(
        MaterialPageRoute(
          builder: (_) => ReviewReceiptScreen(
            geminiResult: geminiResult,
            imagePath: thumbnailPath,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusMessage = 'Căn chỉnh hóa đơn vào khung';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi xử lý OCR/AI: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera Preview or Fallback
          if (_isCameraInitialized && _cameraController != null)
            LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onTapDown: (details) => _handleTapToFocus(details, constraints),
                  child: Center(
                    child: CameraPreview(_cameraController!),
                  ),
                );
              },
            )
          else
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.camera_alt_outlined, color: Colors.white54, size: 64),
                    const SizedBox(height: 12),
                    const Text(
                      'Không phát hiện camera trực tiếp',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _pickFromGallery,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Chọn ảnh từ thư viện'),
                    ),
                  ],
                ),
              ),
            ),

          // Custom Framing Crop Grid Overlay
          CustomPaint(
            size: Size.infinite,
            painter: _CameraCropOverlayPainter(),
          ),

          // Top action bar (Back, AI Badge, Flash)
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 14),
                          const SizedBox(width: 5),
                          Text(
                            _isProcessing ? _statusMessage : 'Gemini AI Vision + ML Kit',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isFlashOn ? Icons.flash_on : Icons.flash_off,
                        color: _isFlashOn ? Colors.amberAccent : Colors.white,
                        size: 28,
                      ),
                      onPressed: _toggleFlash,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom control bar (Gallery, Capture button, Demo button)
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24, left: 32, right: 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Gallery Picker
                    IconButton(
                      icon: const Icon(Icons.photo_library, color: Colors.white, size: 36),
                      onPressed: _isProcessing ? null : _pickFromGallery,
                    ),

                    // Shutter button
                    GestureDetector(
                      onTap: _isProcessing ? null : _captureAndProcess,
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        child: Center(
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: _isProcessing
                                ? const Padding(
                                    padding: EdgeInsets.all(14.0),
                                    child: CircularProgressIndicator(strokeWidth: 3),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),

                    // Test OCR with sample button
                    IconButton(
                      tooltip: 'Demo AI Scan',
                      icon: const Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 34),
                      onPressed: _isProcessing
                          ? null
                          : () async {
                              setState(() {
                                _isProcessing = true;
                                _statusMessage = 'Đang phân tích AI...';
                              });
                              final navigator = Navigator.of(context);
                              final rawText = await _ocrService.recognizeText('');
                              final parsed = ReceiptParserEngine.parse(rawText);
                              final gemini = GeminiReceiptResult(
                                amount: parsed.amount,
                                date: parsed.date,
                                merchantName: parsed.merchantName,
                                category: parsed.suggestedCategory,
                                type: TransactionType.expense,
                                note: '1 Freeze Trà Xanh, 1 Phin Sữa Đá, 1 Bánh Mì',
                              );
                              if (!mounted) return;
                              setState(() {
                                _isProcessing = false;
                                _statusMessage = 'Căn chỉnh hóa đơn vào khung';
                              });
                              navigator.push(
                                MaterialPageRoute(
                                  builder: (_) => ReviewReceiptScreen(
                                    geminiResult: gemini,
                                    imagePath: '',
                                  ),
                                ),
                              );
                            },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraCropOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;

    final frameWidth = size.width * 0.82;
    final frameHeight = size.height * 0.62;
    final frameLeft = (size.width - frameWidth) / 2;
    final frameTop = (size.height - frameHeight) / 2 - 20;

    final frameRect = Rect.fromLTWH(frameLeft, frameTop, frameWidth, frameHeight);

    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final framePath = Path()
      ..addRRect(RRect.fromRectAndRadius(frameRect, const Radius.circular(16)));

    final overlayPath = Path.combine(PathOperation.difference, backgroundPath, framePath);
    canvas.drawPath(overlayPath, backgroundPaint);

    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(RRect.fromRectAndRadius(frameRect, const Radius.circular(16)), borderPaint);

    final cornerPaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;

    const cornerLen = 28.0;

    canvas.drawLine(Offset(frameLeft, frameTop + cornerLen), Offset(frameLeft, frameTop), cornerPaint);
    canvas.drawLine(Offset(frameLeft, frameTop), Offset(frameLeft + cornerLen, frameTop), cornerPaint);

    canvas.drawLine(Offset(frameLeft + frameWidth - cornerLen, frameTop), Offset(frameLeft + frameWidth, frameTop), cornerPaint);
    canvas.drawLine(Offset(frameLeft + frameWidth, frameTop), Offset(frameLeft + frameWidth, frameTop + cornerLen), cornerPaint);

    canvas.drawLine(Offset(frameLeft, frameTop + frameHeight - cornerLen), Offset(frameLeft, frameTop + frameHeight), cornerPaint);
    canvas.drawLine(Offset(frameLeft, frameTop + frameHeight), Offset(frameLeft + cornerLen, frameTop + frameHeight), cornerPaint);

    canvas.drawLine(Offset(frameLeft + frameWidth - cornerLen, frameTop + frameHeight), Offset(frameLeft + frameWidth, frameTop + frameHeight), cornerPaint);
    canvas.drawLine(Offset(frameLeft + frameWidth, frameTop + frameHeight), Offset(frameLeft + frameWidth, frameTop + frameHeight - cornerLen), cornerPaint);

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final thirdH = frameHeight / 3;
    final thirdW = frameWidth / 3;

    canvas.drawLine(Offset(frameLeft, frameTop + thirdH), Offset(frameLeft + frameWidth, frameTop + thirdH), gridPaint);
    canvas.drawLine(Offset(frameLeft, frameTop + 2 * thirdH), Offset(frameLeft + frameWidth, frameTop + 2 * thirdH), gridPaint);
    canvas.drawLine(Offset(frameLeft + thirdW, frameTop), Offset(frameLeft + thirdW, frameTop + frameHeight), gridPaint);
    canvas.drawLine(Offset(frameLeft + 2 * thirdW, frameTop), Offset(frameLeft + 2 * thirdW, frameTop + frameHeight), gridPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
