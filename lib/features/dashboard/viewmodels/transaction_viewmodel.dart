import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/transaction_service.dart';
import '../../../models/transaction.dart';

enum TransactionStatus { initial, loading, loaded, error }

class TransactionState {
  final List<Transaction> transactions;
  final TransactionStatus status;
  final String? errorMessage;

  const TransactionState({
    this.transactions = const [],
    this.status = TransactionStatus.initial,
    this.errorMessage,
  });

  TransactionState copyWith({
    List<Transaction>? transactions,
    TransactionStatus? status,
    String? errorMessage,
  }) {
    return TransactionState(
      transactions: transactions ?? this.transactions,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  double get totalBalance => transactions.fold(
      0, (sum, tx) => tx.isIncome ? sum + tx.amount : sum - tx.amount);

  double get totalIncome => transactions
      .where((tx) => tx.isIncome)
      .fold(0, (sum, tx) => sum + tx.amount);

  double get totalExpenses => transactions
      .where((tx) => !tx.isIncome)
      .fold(0, (sum, tx) => sum + tx.amount);

  List<Transaction> get recentTransactions {
    final sorted = List<Transaction>.from(transactions)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(10).toList();
  }

  Map<String, double> get expensesByCategory {
    final map = <String, double>{};
    for (final tx in transactions.where((tx) => !tx.isIncome)) {
      map[tx.category] = (map[tx.category] ?? 0) + tx.amount;
    }
    return map;
  }
}

class TransactionViewModel extends StateNotifier<TransactionState> {
  final TransactionService _service;
  final String userId;

  TransactionViewModel(this._service, this.userId)
      : super(const TransactionState()) {
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    state = state.copyWith(status: TransactionStatus.loading);
    try {
      final data = await _service.getTransactions(userId);
      final transactions = data.map((map) => Transaction(
            id: map['id'],
            title: map['title'],
            amount: (map['amount'] as num).toDouble(),
            isIncome: map['isIncome'] == 1,
            date: DateTime.parse(map['date']),
            category: map['category'],
          )).toList();
      state = state.copyWith(
        transactions: transactions,
        status: TransactionStatus.loaded,
      );
    } catch (e) {
      state = state.copyWith(
        status: TransactionStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> addTransaction({
    required String title,
    required double amount,
    required bool isIncome,
    required DateTime date,
    required String category,
  }) async {
    final tx = Transaction(
      id: const Uuid().v4(),
      title: title,
      amount: amount,
      isIncome: isIncome,
      date: date,
      category: category,
    );
    await _service.addTransaction({
      'id': tx.id,
      'userId': userId,
      'title': tx.title,
      'amount': tx.amount,
      'isIncome': tx.isIncome ? 1 : 0,
      'date': tx.date.toIso8601String(),
      'category': tx.category,
    });
    state = state.copyWith(
      transactions: [...state.transactions, tx],
    );
  }

  Future<void> deleteTransaction(String id) async {
    await _service.deleteTransaction(id);
    state = state.copyWith(
      transactions: state.transactions.where((tx) => tx.id != id).toList(),
    );
  }

  Future<void> updateTransaction(Transaction tx) async {
    await _service.updateTransaction({
      'id': tx.id,
      'userId': userId,
      'title': tx.title,
      'amount': tx.amount,
      'isIncome': tx.isIncome ? 1 : 0,
      'date': tx.date.toIso8601String(),
      'category': tx.category,
    });
    state = state.copyWith(
      transactions: state.transactions
          .map((t) => t.id == tx.id ? tx : t)
          .toList(),
    );
  }
}

final transactionServiceProvider =
    Provider<TransactionService>((ref) => TransactionService());

final transactionViewModelProvider = StateNotifierProvider.family<
    TransactionViewModel, TransactionState, String>((ref, userId) {
  return TransactionViewModel(
    ref.watch(transactionServiceProvider),
    userId,
  );
});