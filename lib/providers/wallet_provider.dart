import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/wallet.dart';
import '../models/expense.dart';

class WalletProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<Wallet> _wallets = [];
  List<Wallet> get wallets => _wallets;

  WalletProvider() {
    loadWallets();
  }

  Future<void> loadWallets() async {
    _wallets = await _dbHelper.getAllWallets();
    notifyListeners();
  }

  Future<void> addWallet(Wallet wallet) async {
    await _dbHelper.insertWallet(wallet);
    await loadWallets();
  }

  Future<void> updateWallet(Wallet wallet) async {
    await _dbHelper.updateWallet(wallet);
    await loadWallets();
  }

  Future<void> deleteWallet(int id) async {
    await _dbHelper.deleteWallet(id);
    await loadWallets();
  }

  Future<void> performTransfer({
    required int fromWalletId,
    required int toWalletId,
    required double amount,
    required DateTime date,
    String? notes,
  }) async {
    // Create a special expense entry for transfer
    final transferExpense = Expense(
      title: 'Transfer',
      amount: amount,
      category: 'Transfer',
      date: date,
      notes: notes,
      icon: '🔄',
      walletId: fromWalletId,
      toWalletId: toWalletId,
    );

    await _dbHelper.insertExpense(transferExpense);
    
    // Update balances
    await _dbHelper.updateWalletBalance(fromWalletId, amount, isAddition: false);
    await _dbHelper.updateWalletBalance(toWalletId, amount, isAddition: true);
    
    await loadWallets();
  }

  double get totalBalance {
    double total = 0;
    for (var wallet in _wallets) {
      total += wallet.balance;
    }
    return total;
  }
}
