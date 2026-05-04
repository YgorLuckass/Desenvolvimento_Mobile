// lib/viewmodels/transaction_viewmodel.dart

import 'package:flutter/material.dart';
import '../models/transaction_model.dart';

class TransactionViewModel extends ChangeNotifier {
  final List<TransactionModel> _transactions = [];

  TransactionViewModel() {
    _loadSampleData();
  }

  List<TransactionModel> get transactions =>
      List.unmodifiable(_transactions)
        ..sort((a, b) => b.date.compareTo(a.date));

  List<TransactionModel> get recentTransactions =>
      transactions.take(5).toList();

  double get totalIncome => _transactions
      .where((t) => t.isIncome)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get totalExpense => _transactions
      .where((t) => !t.isIncome)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get balance => totalIncome - totalExpense;

  Map<String, double> get expenseByCategory {
    final map = <String, double>{};
    for (final t in _transactions.where((t) => !t.isIncome)) {
      map[t.category] = (map[t.category] ?? 0) + t.amount;
    }
    return map;
  }

  Map<String, double> get monthlyExpenses {
    final map = <String, double>{};
    for (final t in _transactions.where((t) => !t.isIncome)) {
      final key = '${t.date.month}/${t.date.year}';
      map[key] = (map[key] ?? 0) + t.amount;
    }
    return map;
  }

  double get savingsRate {
    if (totalIncome == 0) return 0;
    return (balance / totalIncome) * 100;
  }

  void addTransaction(TransactionModel transaction) {
    _transactions.add(transaction);
    notifyListeners();
  }

  void removeTransaction(String id) {
    _transactions.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  void _loadSampleData() {
    final now = DateTime.now();
    final samples = [
      TransactionModel(
        id: '1',
        title: 'Salário',
        amount: 5000.00,
        type: TransactionType.income,
        date: DateTime(now.year, now.month, 5),
        category: 'Trabalho',
      ),
      TransactionModel(
        id: '2',
        title: 'Aluguel',
        amount: 1200.00,
        type: TransactionType.expense,
        date: DateTime(now.year, now.month, 10),
        category: 'Moradia',
      ),
      TransactionModel(
        id: '3',
        title: 'Supermercado',
        amount: 480.50,
        type: TransactionType.expense,
        date: DateTime(now.year, now.month, 12),
        category: 'Alimentação',
      ),
      TransactionModel(
        id: '4',
        title: 'Freelance',
        amount: 800.00,
        type: TransactionType.income,
        date: DateTime(now.year, now.month, 15),
        category: 'Trabalho',
      ),
      TransactionModel(
        id: '5',
        title: 'Conta de Luz',
        amount: 95.30,
        type: TransactionType.expense,
        date: DateTime(now.year, now.month, 18),
        category: 'Serviços',
      ),
      TransactionModel(
        id: '6',
        title: 'Academia',
        amount: 89.90,
        type: TransactionType.expense,
        date: DateTime(now.year, now.month, 20),
        category: 'Saúde',
      ),
      TransactionModel(
        id: '7',
        title: 'Restaurante',
        amount: 120.00,
        type: TransactionType.expense,
        date: DateTime(now.year, now.month, 22),
        category: 'Alimentação',
      ),
      TransactionModel(
        id: '8',
        title: 'Internet',
        amount: 99.90,
        type: TransactionType.expense,
        date: DateTime(now.year, now.month, 25),
        category: 'Serviços',
      ),
    ];
    _transactions.addAll(samples);
  }
}
