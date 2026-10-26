import 'package:flutter/material.dart';
import '../models/vault_transaction.dart';
import '../utils/database_helper.dart';
import 'package:uuid/uuid.dart';
import 'activity_log_provider.dart';

class VaultProvider with ChangeNotifier {
  List<VaultTransaction> _transactions = [];
  final DatabaseHelper _dbHelper = DatabaseHelper();
  ActivityLogProvider? logProvider;

  List<VaultTransaction> get transactions => [..._transactions];

  double get totalBalance {
    double balance = 0;
    for (var tx in _transactions) {
      if (tx.type == TransactionType.deposit) {
        balance += tx.amount;
      } else {
        balance -= tx.amount;
      }
    }
    return balance;
  }

  VaultProvider({this.logProvider}) {
    loadTransactions();
  }

  void update(ActivityLogProvider? logs) {
    logProvider = logs;
  }

  Future<void> loadTransactions() async {
    _transactions = await _dbHelper.getTransactions();
    notifyListeners();
  }

  Future<void> addTransaction(
    String title,
    double amount,
    TransactionType type, {
    String? description,
  }) async {
    final transaction = VaultTransaction(
      id: const Uuid().v4(),
      title: title,
      amount: amount,
      date: DateTime.now(),
      type: type,
      description: description,
    );

    await _dbHelper.insertTransaction(transaction);
    _transactions.insert(0, transaction);

    // سجل النشاط
    logProvider?.logAction(
      action:
          type == TransactionType.deposit ? 'إيداع في الخزنة' : 'سحب من الخزنة',
      details: 'عملية: $title بقيمة $amount',
      category: 'vault',
    );

    notifyListeners();
  }
}
