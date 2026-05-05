import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';

class FinanceViewModel extends ChangeNotifier {
  List<Transaction> _transactions = [];
  String? _loggedInUser;
  bool _isLoading = true;

  List<Transaction> get transactions => List.unmodifiable(_transactions);
  String? get loggedInUser => _loggedInUser;
  bool get isLoading => _isLoading;

  double get totalBalance => _transactions.fold(
        0, (sum, tx) => tx.isIncome ? sum + tx.amount : sum - tx.amount);

  double get totalIncome => _transactions
      .where((tx) => tx.isIncome)
      .fold(0, (sum, tx) => sum + tx.amount);

  double get totalExpenses => _transactions
      .where((tx) => !tx.isIncome)
      .fold(0, (sum, tx) => sum + tx.amount);

  List<Transaction> get recentTransactions {
    final sorted = List<Transaction>.from(_transactions)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(10).toList();
  }

  Map<String, double> get expensesByCategory {
    final map = <String, double>{};
    for (final tx in _transactions.where((tx) => !tx.isIncome)) {
      map[tx.category] = (map[tx.category] ?? 0) + tx.amount;
    }
    return map;
  }

  FinanceViewModel() {
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _loggedInUser = prefs.getString('loggedInUser');
    final txJson = prefs.getString('transactions');
    if (txJson != null) {
      final List decoded = jsonDecode(txJson);
      _transactions = decoded.map((e) => Transaction.fromJson(e)).toList();
    } else {
      _seedDemoData();
    }
    _isLoading = false;
    notifyListeners();
  }

  void _seedDemoData() {
    final now = DateTime.now();
    _transactions = [
      Transaction(id: const Uuid().v4(), title: 'Salário', amount: 5000,
          isIncome: true, date: DateTime(now.year, now.month, 1), category: 'Salário'),
      Transaction(id: const Uuid().v4(), title: 'Supermercado', amount: 320,
          isIncome: false, date: DateTime(now.year, now.month, 3), category: 'Alimentação'),
      Transaction(id: const Uuid().v4(), title: 'Aluguel', amount: 1200,
          isIncome: false, date: DateTime(now.year, now.month, 5), category: 'Moradia'),
      Transaction(id: const Uuid().v4(), title: 'Freelance', amount: 800,
          isIncome: true, date: DateTime(now.year, now.month, 10), category: 'Freelance'),
      Transaction(id: const Uuid().v4(), title: 'Combustível', amount: 200,
          isIncome: false, date: DateTime(now.year, now.month, 7), category: 'Transporte'),
      Transaction(id: const Uuid().v4(), title: 'Cinema', amount: 80,
          isIncome: false, date: DateTime(now.year, now.month, 12), category: 'Lazer'),
    ];
  }

  Future<void> _saveTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('transactions',
        jsonEncode(_transactions.map((tx) => tx.toJson()).toList()));
  }

  Future<void> addTransaction(Transaction tx) async {
    _transactions.add(tx);
    await _saveTransactions();
    notifyListeners();
  }

  Future<void> deleteTransaction(String id) async {
    _transactions.removeWhere((tx) => tx.id == id);
    await _saveTransactions();
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final users = jsonDecode(prefs.getString('users') ?? '{}') as Map;
    if (users.containsKey(email) && users[email] == password) {
      _loggedInUser = email;
      await prefs.setString('loggedInUser', email);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> register(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final users = jsonDecode(prefs.getString('users') ?? '{}') as Map<String, dynamic>;
    if (users.containsKey(email)) return false;
    users[email] = password;
    await prefs.setString('users', jsonEncode(users));
    _loggedInUser = email;
    await prefs.setString('loggedInUser', email);
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('loggedInUser');
    _loggedInUser = null;
    notifyListeners();
  }
}