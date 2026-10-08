import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:vku_ocr_expense/domain/entities/transaction_entity.dart';
import 'package:vku_ocr_expense/presentation/bloc/expense_bloc.dart';
import 'package:vku_ocr_expense/presentation/bloc/expense_state.dart';

class CalendarHistoryTab extends StatefulWidget {
  const CalendarHistoryTab({super.key});

  @override
  State<CalendarHistoryTab> createState() => _CalendarHistoryTabState();
}

class _CalendarHistoryTabState extends State<CalendarHistoryTab> {
  DateTime _selectedDate = DateTime.now();
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return BlocBuilder<ExpenseBloc, ExpenseState>(
      builder: (context, state) {
        if (state is! ExpenseLoadedState) {
          return const Center(child: CircularProgressIndicator());
        }

        final allTransactions = state.transactions;

        // Group transactions by date
        final Map<String, List<TransactionEntity>> groupedByDate = {};
        for (final tx in allTransactions) {
          final key = DateFormat('yyyy-MM-dd').format(tx.date);
          groupedByDate.putIfAbsent(key, () => []).add(tx);
        }

        final selectedDateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);
        final selectedDayTransactions = groupedByDate[selectedDateKey] ?? [];

        // Daily total
        double dayExpense = 0.0;
        double dayIncome = 0.0;
        for (final tx in selectedDayTransactions) {
          if (tx.type == TransactionType.expense) {
            dayExpense += tx.amount;
          } else {
            dayIncome += tx.amount;
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Month selector header
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: _previousMonth,
                      ),
                      Text(
                        'Tháng ${DateFormat('MM / yyyy').format(_currentMonth)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: _nextMonth,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Calendar Grid View
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: _buildMonthCalendar(groupedByDate),
                ),
              ),
              const SizedBox(height: 20),

              // Selected day summary & receipt photo preview
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ngày ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Row(
                    children: [
                      if (dayExpense > 0)
                        Text(
                          '-${currencyFormatter.format(dayExpense)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      if (dayExpense > 0 && dayIncome > 0) const SizedBox(width: 8),
                      if (dayIncome > 0)
                        Text(
                          '+${currencyFormatter.format(dayIncome)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF10B981),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Gallery of receipt photos captured on this day
              _buildCapturedReceiptsForDay(selectedDayTransactions),
              const SizedBox(height: 14),

              // List of transactions on this day
              if (selectedDayTransactions.isEmpty)
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'Không có giao dịch nào trong ngày này',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: selectedDayTransactions.length,
                  separatorBuilder: (context, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final tx = selectedDayTransactions[index];
                    final isExpense = tx.type == TransactionType.expense;

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      color: Colors.white,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isExpense
                              ? const Color(0xFFEF4444).withValues(alpha: 0.12)
                              : const Color(0xFF10B981).withValues(alpha: 0.12),
                          child: Icon(
                            isExpense ? Icons.arrow_outward : Icons.arrow_downward,
                            color: isExpense ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                            size: 20,
                          ),
                        ),
                        title: Text(
                          tx.merchantName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: Text(
                          '${tx.category.displayName} • ${tx.type.displayName}${tx.note.isNotEmpty ? ' • ${tx.note}' : ''}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                        trailing: Text(
                          '${isExpense ? '-' : '+'}${currencyFormatter.format(tx.amount)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isExpense ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 100),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMonthCalendar(Map<String, List<TransactionEntity>> grouped) {
    final daysInWeek = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final daysInCurrentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final startWeekday = firstDayOfMonth.weekday; // 1 = Monday ... 7 = Sunday

    return Column(
      children: [
        // Week headers
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: daysInWeek.map((d) {
            return SizedBox(
              width: 38,
              child: Text(
                d,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: d == 'CN' ? Colors.redAccent : Colors.grey.shade600,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),

        // Calendar days grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 42, // 6 rows * 7
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
          ),
          itemBuilder: (context, index) {
            final dayOffset = index - (startWeekday - 1);
            if (dayOffset < 0 || dayOffset >= daysInCurrentMonth) {
              return const SizedBox.shrink();
            }

            final day = dayOffset + 1;
            final cellDate = DateTime(_currentMonth.year, _currentMonth.month, day);
            final dateKey = DateFormat('yyyy-MM-dd').format(cellDate);
            final hasTransactions = grouped.containsKey(dateKey);
            final isSelected = cellDate.year == _selectedDate.year &&
                cellDate.month == _selectedDate.month &&
                cellDate.day == _selectedDate.day;

            final txList = grouped[dateKey] ?? [];
            final hasPhoto = txList.any((t) => t.receiptImagePath.isNotEmpty);

            return InkWell(
              onTap: () {
                setState(() {
                  _selectedDate = cellDate;
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF2563EB)
                      : hasTransactions
                          ? const Color(0xFFEFF6FF)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF2563EB)
                        : hasTransactions
                            ? const Color(0xFFBFDBFE)
                            : Colors.transparent,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected || hasTransactions ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? Colors.white
                            : hasTransactions
                                ? const Color(0xFF1E3A8A)
                                : const Color(0xFF334155),
                      ),
                    ),
                    if (hasTransactions)
                      Positioned(
                        bottom: 4,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected ? Colors.white : const Color(0xFF2563EB),
                              ),
                            ),
                            if (hasPhoto) ...[
                              const SizedBox(width: 2),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected ? Colors.amberAccent : Colors.orange,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCapturedReceiptsForDay(List<TransactionEntity> transactions) {
    final photoTransactions = transactions.where((t) => t.receiptImagePath.isNotEmpty).toList();

    if (photoTransactions.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.photo_camera_outlined, color: Color(0xFF2563EB), size: 22),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Không có ảnh hóa đơn ngày này',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Hãy dùng tính năng "Quét Hóa Đơn AI" để lưu ảnh như Locket',
                    style: TextStyle(color: Colors.grey, fontSize: 11.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.camera_rounded, size: 16, color: Colors.orange),
                ),
                const SizedBox(width: 8),
                Text(
                  'Khoảnh khắc Locket (${photoTransactions.length} ảnh)',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
              ],
            ),
            Text(
              'Chạm để xem to',
              style: TextStyle(fontSize: 11.5, color: Colors.blue.shade600, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Locket style cards: khung to, bo góc lớn, bóng mờ đẹp
        SizedBox(
          height: 170,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: photoTransactions.length,
            separatorBuilder: (context, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final tx = photoTransactions[index];
              final file = File(tx.receiptImagePath);

              return GestureDetector(
                onTap: () => _showFullImageDialog(tx),
                child: Hero(
                  tag: 'locket_${tx.id}_${tx.receiptImagePath}',
                  child: Container(
                    width: 130,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.black87,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (file.existsSync())
                          Image.file(file, fit: BoxFit.cover)
                        else
                          const Center(
                            child: Icon(Icons.image_not_supported, color: Colors.white54, size: 36),
                          ),
                        // Dark gradient overlay on bottom
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.85),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  tx.merchantName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(tx.amount),
                                  style: const TextStyle(
                                    color: Colors.amberAccent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  void _showFullImageDialog(TransactionEntity tx) {
    final file = File(tx.receiptImagePath);
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Locket
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lens_blur, color: Colors.amberAccent, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          tx.merchantName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              // Big Locket Photo
              if (file.existsSync())
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 380),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.file(file, fit: BoxFit.contain),
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 50),
                  child: Column(
                    children: [
                      Icon(Icons.broken_image_outlined, color: Colors.white38, size: 48),
                      SizedBox(height: 8),
                      Text('Không tìm thấy tệp ảnh', style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
              // Footer Caption
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                color: const Color(0xFF1E293B),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(tx.amount),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: tx.type == TransactionType.expense
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF10B981),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            tx.category.displayName,
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Thời gian: ${DateFormat('dd/MM/yyyy HH:mm').format(tx.date)}${tx.note.isNotEmpty ? '\nGhi chú: ${tx.note}' : ''}',
                      style: const TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
