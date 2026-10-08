import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vku_ocr_expense/core/services/gemini_ai_service.dart';
import 'package:vku_ocr_expense/core/utils/receipt_parser_engine.dart';
import 'package:vku_ocr_expense/domain/entities/transaction_entity.dart';
import 'package:vku_ocr_expense/presentation/bloc/expense_bloc.dart';
import 'package:vku_ocr_expense/presentation/bloc/expense_event.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ReviewReceiptScreen extends StatefulWidget {
  final ParsedReceiptResult? parsedResult;
  final GeminiReceiptResult? geminiResult;
  final String imagePath;

  const ReviewReceiptScreen({
    super.key,
    this.parsedResult,
    this.geminiResult,
    required this.imagePath,
  });

  @override
  State<ReviewReceiptScreen> createState() => _ReviewReceiptScreenState();
}

class _ReviewReceiptScreenState extends State<ReviewReceiptScreen> {
  late TextEditingController _merchantController;
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late DateTime _selectedDate;
  late ExpenseCategory _selectedCategory;
  late TransactionType _selectedType;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final amount = widget.geminiResult?.amount ?? widget.parsedResult?.amount ?? 0.0;
    final merchant = widget.geminiResult?.merchantName ?? widget.parsedResult?.merchantName ?? '';
    // Always default to today's date when captured, so demoing with old receipts still shows up on today's calendar
    final date = DateTime.now();
    final cat = widget.geminiResult?.category ?? widget.parsedResult?.suggestedCategory ?? ExpenseCategory.food;
    final type = widget.geminiResult?.type ?? TransactionType.expense;
    final note = widget.geminiResult?.note ?? '';

    _merchantController = TextEditingController(text: merchant);
    _amountController = TextEditingController(
      text: amount > 0 ? amount.toStringAsFixed(0) : '',
    );
    _noteController = TextEditingController(text: note);
    _selectedDate = date;
    _selectedCategory = cat;
    _selectedType = type;
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _onSave() {
    final amount = double.tryParse(_amountController.text.replaceAll(RegExp(r'[,.\s]'), '')) ?? 0.0;
    final merchant = _merchantController.text.trim();

    if (merchant.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên giao dịch / cửa hàng')),
      );
      return;
    }

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số tiền hợp lệ (> 0)')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final newTransaction = TransactionEntity(
      amount: amount,
      date: _selectedDate,
      merchantName: merchant,
      category: _selectedCategory,
      type: _selectedType,
      receiptImagePath: widget.imagePath,
      note: _noteController.text.trim(),
    );

    context.read<ExpenseBloc>().add(AddTransactionEvent(newTransaction));

    final typeName = _selectedType.displayName;
    Navigator.of(context).popUntil((route) => route.isFirst);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('Đã lưu thành công: $typeName!'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green.shade700,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 150,
          left: 20,
          right: 20,
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fileExists = widget.imagePath.isNotEmpty && File(widget.imagePath).existsSync();
    final isExpense = _selectedType == TransactionType.expense;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Xác nhận thông tin hóa đơn'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Segmented control: Ô CHI và Ô THU riêng biệt
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedType = TransactionType.expense;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isExpense ? const Color(0xFFEF4444) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: isExpense
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : [],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.arrow_outward,
                              color: isExpense ? Colors.white : Colors.grey.shade700,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'TIỀN CHI (Expense)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isExpense ? Colors.white : Colors.grey.shade700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedType = TransactionType.income;
                          _selectedCategory = ExpenseCategory.salary;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !isExpense ? const Color(0xFF10B981) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: !isExpense
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : [],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.arrow_downward,
                              color: !isExpense ? Colors.white : Colors.grey.shade700,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'TIỀN THU (Income)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: !isExpense ? Colors.white : Colors.grey.shade700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Thumbnail preview card
            Container(
              height: 170,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              clipBehavior: Clip.antiAlias,
              child: fileExists
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(
                          File(widget.imagePath),
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  widget.geminiResult != null ? Icons.auto_awesome : Icons.check_circle,
                                  color: Colors.amberAccent,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.geminiResult != null ? 'AI Gemini Flash 1.5' : 'On-Device OCR',
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.receipt_long, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 4),
                          Text('Ảnh hóa đơn', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 16),

            // Input card
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tên Cửa Hàng / Đơn Vị',
                      style: theme.textTheme.labelMedium?.copyWith(color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _merchantController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.storefront_outlined),
                        hintText: 'Nhập tên cửa hàng...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Amount input
                    Text(
                      isExpense ? 'Số Tiền Chi (VND)' : 'Số Tiền Thu (VND)',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: isExpense ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isExpense ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                      ),
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.attach_money,
                          color: isExpense ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                        ),
                        suffixText: 'VND',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Date picker
                    Text(
                      'Ngày Giao Dịch',
                      style: theme.textTheme.labelMedium?.copyWith(color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('dd/MM/yyyy').format(_selectedDate),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                            const Icon(Icons.calendar_month, color: Color(0xFF2563EB)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Note input
                    Text(
                      'Ghi Chú Chi Tiết',
                      style: theme.textTheme.labelMedium?.copyWith(color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _noteController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.note_alt_outlined),
                        hintText: 'Món ăn, thiết bị, lý do chi tiêu...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Category selector Chips
            Text(
              'Danh Mục (${_selectedType.displayName})',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ExpenseCategory.values.map((cat) {
                final isSelected = _selectedCategory == cat;
                return ChoiceChip(
                  label: Text(cat.displayName),
                  selected: isSelected,
                  selectedColor: (isExpense ? const Color(0xFFEF4444) : const Color(0xFF10B981)).withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? (isExpense ? const Color(0xFFEF4444) : const Color(0xFF10B981))
                        : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedCategory = cat;
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Save button
            FilledButton.icon(
              onPressed: _isSaving ? null : _onSave,
              style: FilledButton.styleFrom(
                backgroundColor: isExpense ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save),
              label: Text(
                _isSaving ? 'Đang lưu...' : 'Lưu Giao Dịch (${_selectedType.displayName})',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
