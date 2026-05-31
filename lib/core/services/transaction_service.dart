import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../database/database_helper.dart';

class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<bool> _isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  Future<void> addTransaction(Map<String, dynamic> tx) async {
    // Sempre salva local primeiro
    await _db.insertTransaction({...tx, 'syncedToCloud': 0});

    // Tenta sincronizar com Firestore
    if (await _isOnline()) {
      try {
        await _firestore
            .collection('transactions')
            .doc(tx['id'])
            .set({
          ...tx,
          'date': tx['date'],
          'createdAt': FieldValue.serverTimestamp(),
        });
        await _db.updateTransaction({...tx, 'syncedToCloud': 1});
      } catch (e) {
        // Fica salvo local, sincroniza depois
      }
    }
  }

  Future<List<Map<String, dynamic>>> getTransactions(String userId) async {
    // Sempre busca do SQLite local primeiro (mais rápido)
    final localTx = await _db.getTransactionsByUser(userId);

    // Se online, sincroniza do Firestore em background
    if (await _isOnline()) {
      _syncFromFirestore(userId);
    }

    return localTx;
  }

  Future<void> _syncFromFirestore(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        await _db.insertTransaction({
          'id': doc.id,
          'userId': data['userId'],
          'title': data['title'],
          'amount': (data['amount'] as num).toDouble(),
          'isIncome': data['isIncome'] ? 1 : 0,
          'date': data['date'],
          'category': data['category'],
          'syncedToCloud': 1,
        });
      }
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> deleteTransaction(String id) async {
    await _db.deleteTransaction(id);
    if (await _isOnline()) {
      try {
        await _firestore.collection('transactions').doc(id).delete();
      } catch (e) {
        // Será removido na próxima sync
      }
    }
  }

  Future<void> updateTransaction(Map<String, dynamic> tx) async {
    await _db.updateTransaction({...tx, 'syncedToCloud': 0});
    if (await _isOnline()) {
      try {
        await _firestore.collection('transactions').doc(tx['id']).update(tx);
        await _db.updateTransaction({...tx, 'syncedToCloud': 1});
      } catch (e) {
        // Fica salvo local
      }
    }
  }
}