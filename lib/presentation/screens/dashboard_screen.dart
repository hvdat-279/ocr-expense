import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:vku_ocr_expense/domain/entities/transaction_entity.dart';
import 'package:vku_ocr_expense/presentation/bloc/expense_bloc.dart';
import 'package:vku_ocr_expense/presentation/bloc/expense_event.dart';
import 'package:vku_ocr_expense/presentation/bloc/expense_state.dart';
import 'package:vku_ocr_expense/presentation/screens/calendar_history_tab.dart';
import 'package:vku_ocr_expense/presentation/screens/camera_scanner_screen.dart';
import 'package:vku_ocr_expense/presentation/widgets/animated_bar_chart.dart';
import 'package:vku_ocr_expense/presentation/widgets/animated_donut_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF2563EB), size: 22),
            ),
            const SizedBox(width: 10),
            const Text(
              'VKU Sổ Chi Tiêu AI',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Xóa toàn bộ dữ liệu mẫu',
            icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
            onPressed: () {
              showDialog(
                context: context,
                builder: (dialogCtx) => AlertDialog(
                  title: const Text('Xóa dữ liệu?'),
                  content: const Text('Bạn có chắc chắn muốn xóa sạch toàn bộ giao dịch và dữ liệu mẫu không?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogCtx),
                      child: const Text('Hủy'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () {
                        context.read<ExpenseBloc>().add(ClearAllTransactionsEvent());
                        Navigator.pop(dialogCtx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text('Đã xóa sạch toàn bộ dữ liệu!'),
                              ],
                            ),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: const Color(0xFF1E293B),
                            margin: EdgeInsets.only(
                              bottom: MediaQuery.of(context).size.height - 150,
                              left: 20,
                              right: 20,
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: const Text('Xóa sạch', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Làm mới',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<ExpenseBloc>().add(LoadDashboardDataEvent());
            },
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CameraScannerScreen()),
          );
        },
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.document_scanner, size: 28),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: Colors.white,
        elevation: 10,
        height: 65,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Tab 1: Tổng quan & Biểu đồ
            Expanded(
              child: InkWell(
                onTap: () {
                  setState(() {
                    _currentTabIndex = 0;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _currentTabIndex == 0 ? Icons.dashboard : Icons.dashboard_outlined,
                      color: _currentTabIndex == 0 ? const Color(0xFF2563EB) : Colors.grey.shade500,
                      size: 22,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tổng quan',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: _currentTabIndex == 0 ? FontWeight.bold : FontWeight.w500,
                        color: _currentTabIndex == 0 ? const Color(0xFF2563EB) : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Khoảng trống ở giữa cho nút tròn quét camera
            const SizedBox(width: 60),
            // Tab 2: Lịch sử theo ngày & Ảnh
            Expanded(
              child: InkWell(
                onTap: () {
                  setState(() {
                    _currentTabIndex = 1;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _currentTabIndex == 1 ? Icons.calendar_month : Icons.calendar_month_outlined,
                      color: _currentTabIndex == 1 ? const Color(0xFF2563EB) : Colors.grey.shade500,
                      size: 22,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Lịch sử & Ảnh',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: _currentTabIndex == 1 ? FontWeight.bold : FontWeight.w500,
                        color: _currentTabIndex == 1 ? const Color(0xFF2563EB) : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _currentTabIndex,
        children: const [
          _OverviewTab(),
          CalendarHistoryTab(),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return BlocBuilder<ExpenseBloc, ExpenseState>(
      builder: (context, state) {
        if (state is ExpenseLoadingState) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ExpenseErrorState) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 12),
                Text(state.message),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    context.read<ExpenseBloc>().add(LoadDashboardDataEvent());
                  },
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        if (state is ExpenseLoadedState) {
          return RefreshIndicator(
            onRefresh: () async {
              context.read<ExpenseBloc>().add(LoadDashboardDataEvent());
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 90),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Ô Thu - Ô Chi riêng biệt rõ ràng
                  _buildIncomeExpenseRow(
                    expense: state.totalExpense,
                    income: state.totalIncome,
                    netBalance: state.netBalance,
                    formatter: currencyFormatter,
                  ),
                  const SizedBox(height: 20),

                  // 2. Section 1: Phân bổ chi tiêu nằm chính giữa
                  _buildSectionHeader('Phân bổ chi tiêu theo danh mục', Icons.pie_chart_outline),
                  const SizedBox(height: 10),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 22.0),
                      child: Center(
                        child: AnimatedDonutChart(data: state.categorySpending),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // 3. Section 2: Biểu đồ chi tiêu 7 ngày qua
                  _buildSectionHeader('Chi tiêu 7 ngày qua', Icons.bar_chart_rounded),
                  const SizedBox(height: 10),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: AnimatedBarChart(weeklyData: state.weeklySpending),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // 4. Section 3: Giao dịch gần đây
                  _buildSectionHeader('Giao dịch gần đây', Icons.receipt_long_outlined),
                  const SizedBox(height: 10),
                  if (state.transactions.isEmpty)
                    _buildEmptyTransactionsCard()
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: state.transactions.length,
                      separatorBuilder: (context, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final tx = state.transactions[index];
                        return _buildTransactionItem(context, tx, currencyFormatter);
                      },
                    ),
                ],
              ),
            ),
          );
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildIncomeExpenseRow({
    required double expense,
    required double income,
    required double netBalance,
    required NumberFormat formatter,
  }) {
    return Column(
      children: [
        // Net Balance Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Số dư hiện tại (Thu - Chi)',
                    style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatter.format(netBalance),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 14),
                    SizedBox(width: 4),
                    Text('Gemini AI On-device', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 2 Ô Thu - Chi riêng biệt đồng đều tuyệt đối
        Row(
          children: [
            // Ô TIỀN CHI
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.25)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 17,
                      backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.12),
                      child: const Icon(Icons.arrow_outward, color: Color(0xFFEF4444), size: 17),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tổng Chi',
                            style: TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              formatter.format(expense),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Ô TIỀN THU
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.25)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 17,
                      backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.12),
                      child: const Icon(Icons.arrow_downward, color: Color(0xFF10B981), size: 17),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tổng Thu',
                            style: TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              formatter.format(income),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF1E293B)),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyTransactionsCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.receipt_outlined, size: 48, color: Colors.grey),
              SizedBox(height: 10),
              Text(
                'Chưa có giao dịch nào',
                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 4),
              Text(
                'Bấm nút "Quét Hóa Đơn AI" bên dưới để chụp và bóc tách tự động!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionItem(
    BuildContext context,
    TransactionEntity tx,
    NumberFormat formatter,
  ) {
    final isExpense = tx.type == TransactionType.expense;

    return Dismissible(
      key: Key('tx_${tx.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        if (tx.id != null) {
          context.read<ExpenseBloc>().add(DeleteTransactionEvent(tx.id!));
        }
      },
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        color: Colors.white,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: (isExpense ? const Color(0xFFEF4444) : const Color(0xFF10B981)).withValues(alpha: 0.12),
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
            '${DateFormat('dd/MM/yyyy').format(tx.date)} • ${tx.category.displayName}${tx.note.isNotEmpty ? ' • ${tx.note}' : ''}',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          trailing: Text(
            '${isExpense ? '-' : '+'}${formatter.format(tx.amount)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isExpense ? const Color(0xFFEF4444) : const Color(0xFF10B981),
            ),
          ),
        ),
      ),
    );
  }
}
