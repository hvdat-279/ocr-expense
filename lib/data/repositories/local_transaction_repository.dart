import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:vku_ocr_expense/data/models/transaction_model.dart';
import 'package:vku_ocr_expense/domain/entities/transaction_entity.dart';
import 'package:vku_ocr_expense/domain/repositories/transaction_repository.dart';

class LocalTransactionRepository implements TransactionRepository {
  static const String _tableName = 'transactions';
  Database? _database;

  // In-memory fallback if sqflite native binary is unavailable
  final List<TransactionModel> _fallbackMemoryDb = [];
  int _fallbackIdCounter = 1;
  bool _useFallback = false;

  Future<Database?> get database async {
    if (_useFallback) return null;
    if (_database != null) return _database;
    try {
      _database = await _initDb();
      return _database;
    } catch (e) {
      debugPrint('Sqflite init failed, falling back to memory DB: $e');
      _useFallback = true;
      return null;
    }
  }

  Future<Database> _initDb() async {
    String dbPath;
    if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
      dbPath = await getDatabasesPath();
    } else {
      final docDir = await getApplicationDocumentsDirectory();
      dbPath = docDir.path;
    }
    final path = p.join(dbPath, 'vku_expense_v2.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            amount REAL NOT NULL,
            date TEXT NOT NULL,
            merchant_name TEXT NOT NULL,
            category TEXT NOT NULL,
            type TEXT NOT NULL,
            receipt_image_path TEXT NOT NULL,
            note TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          try {
            await db.execute("ALTER TABLE $_tableName ADD COLUMN type TEXT NOT NULL DEFAULT 'expense'");
            await db.execute("ALTER TABLE $_tableName ADD COLUMN note TEXT NOT NULL DEFAULT ''");
          } catch (_) {}
        }
      },
    );
  }

  @override
  Future<List<TransactionEntity>> getAllTransactions() async {
    final db = await database;
    if (db == null) {
      return List<TransactionEntity>.from(_fallbackMemoryDb)
        ..sort((a, b) => b.date.compareTo(a.date));
    }

    final maps = await db.query(
      _tableName,
      orderBy: 'date DESC, id DESC',
    );
    return maps.map((m) => TransactionModel.fromMap(m)).toList();
  }

  @override
  Future<TransactionEntity?> getTransactionById(int id) async {
    final db = await database;
    if (db == null) {
      try {
        return _fallbackMemoryDb.firstWhere((element) => element.id == id);
      } catch (_) {
        return null;
      }
    }

    final maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return TransactionModel.fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<int> insertTransaction(TransactionEntity transaction) async {
    final model = TransactionModel.fromEntity(transaction);
    final db = await database;
    if (db == null) {
      final newModel = TransactionModel(
        id: _fallbackIdCounter++,
        amount: model.amount,
        date: model.date,
        merchantName: model.merchantName,
        category: model.category,
        type: model.type,
        receiptImagePath: model.receiptImagePath,
        note: model.note,
      );
      _fallbackMemoryDb.add(newModel);
      return newModel.id!;
    }

    return await db.insert(_tableName, model.toMap());
  }

  @override
  Future<int> updateTransaction(TransactionEntity transaction) async {
    if (transaction.id == null) return 0;
    final model = TransactionModel.fromEntity(transaction);
    final db = await database;
    if (db == null) {
      final index = _fallbackMemoryDb.indexWhere((m) => m.id == transaction.id);
      if (index != -1) {
        _fallbackMemoryDb[index] = model;
        return 1;
      }
      return 0;
    }

    return await db.update(
      _tableName,
      model.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  @override
  Future<int> deleteTransaction(int id) async {
    final db = await database;
    if (db == null) {
      final initialCount = _fallbackMemoryDb.length;
      _fallbackMemoryDb.removeWhere((element) => element.id == id);
      return initialCount - _fallbackMemoryDb.length;
    }

    return await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> clearAllTransactions() async {
    final db = await database;
    if (db == null) {
      _fallbackMemoryDb.clear();
      return;
    }
    await db.delete(_tableName);
  }

  @override
  Future<Map<ExpenseCategory, double>> getSpendingByCategory({TransactionType type = TransactionType.expense}) async {
    final transactions = await getAllTransactions();
    final Map<ExpenseCategory, double> result = {
      for (var cat in ExpenseCategory.values) cat: 0.0,
    };

    for (final tx in transactions) {
      if (tx.type == type) {
        result[tx.category] = (result[tx.category] ?? 0.0) + tx.amount;
      }
    }
    return result;
  }

  @override
  Future<Map<String, double>> getWeeklySpending({TransactionType type = TransactionType.expense}) async {
    final transactions = await getAllTransactions();
    final now = DateTime.now();
    final Map<String, double> result = {};
    final daysOfWeek = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    for (int i = 6; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      final dayLabel = daysOfWeek[d.weekday - 1];
      result[dayLabel] = 0.0;
    }

    for (final tx in transactions) {
      if (tx.type == type) {
        final diff = now.difference(tx.date).inDays;
        if (diff >= 0 && diff < 7) {
          final dayLabel = daysOfWeek[tx.date.weekday - 1];
          result[dayLabel] = (result[dayLabel] ?? 0.0) + tx.amount;
        }
      }
    }
    return result;
  }

  @override
  Future<List<TransactionEntity>> getTransactionsByDate(DateTime date) async {
    final transactions = await getAllTransactions();
    return transactions.where((tx) =>
      tx.date.year == date.year &&
      tx.date.month == date.month &&
      tx.date.day == date.day
    ).toList();
  }
}
