import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vku_ocr_expense/data/repositories/local_transaction_repository.dart';
import 'package:vku_ocr_expense/presentation/bloc/expense_bloc.dart';
import 'package:vku_ocr_expense/presentation/bloc/expense_event.dart';
import 'package:vku_ocr_expense/presentation/screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final repository = LocalTransactionRepository();

  runApp(MyApp(repository: repository));
}

class MyApp extends StatelessWidget {
  final LocalTransactionRepository repository;

  const MyApp({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ExpenseBloc(repository: repository)..add(LoadDashboardDataEvent()),
      child: MaterialApp(
        title: 'VKU OCR Expense Tracker',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2563EB),
            brightness: Brightness.light,
          ),
          appBarTheme: const AppBarTheme(
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: Color(0xFF1E293B),
            centerTitle: false,
          ),
          snackBarTheme: SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 6,
          ),
        ),
        home: const DashboardScreen(),
      ),
    );
  }
}
