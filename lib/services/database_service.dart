import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction.dart';
import '../models/account.dart';
import '../models/category.dart';

/// Encrypted Hive database service for secure data persistence
class DatabaseService {
  static DatabaseService? _instance;
  static DatabaseService get instance => _instance ??= DatabaseService._();

  DatabaseService._();

  // Hive boxes
  late Box<String> _transactionsBox;
  late Box<String> _accountsBox;
  late Box<String> _categoriesBox;
  late Box<String> _settingsBox;

  bool _initialized = false;

  /// Initialize database with encryption
  Future<void> init() async {
    if (_initialized) return;

    await Hive.initFlutter();

    // Generate or retrieve encryption key
    final encryptionKey = await _getOrCreateEncryptionKey();
    final cipher = HiveAesCipher(encryptionKey);

    // Open encrypted boxes
    _transactionsBox = await Hive.openBox<String>(
      'transactions_v1',
      encryptionCipher: cipher,
    );
    _accountsBox = await Hive.openBox<String>(
      'accounts_v1',
      encryptionCipher: cipher,
    );
    _categoriesBox = await Hive.openBox<String>(
      'categories_v1',
      encryptionCipher: cipher,
    );
    _settingsBox = await Hive.openBox<String>(
      'settings_v1',
      encryptionCipher: cipher,
    );

    // Init default categories if empty
    if (_categoriesBox.isEmpty) {
      await _initDefaultCategories();
    }

    // Init default account if empty
    if (_accountsBox.isEmpty) {
      await _initDefaultAccount();
    }

    _initialized = true;
  }

  /// Get or create encryption key
  Future<List<int>> _getOrCreateEncryptionKey() async {
    // Use a separate unencrypted box to store the key
    final keyBox = await Hive.openBox<String>('encryption_key');

    const keyName = 'hive_key';
    if (keyBox.containsKey(keyName)) {
      final storedKey = keyBox.get(keyName)!;
      return base64Decode(storedKey);
    }

    // Generate new key
    final key = Hive.generateSecureKey();
    await keyBox.put(keyName, base64Encode(key));
    return key;
  }

  /// Initialize default categories
  Future<void> _initDefaultCategories() async {
    for (final category in TransactionCategory.allDefaultCategories) {
      await addCategory(category);
    }
  }

  /// Initialize default account
  Future<void> _initDefaultAccount() async {
    final defaultAccount = Account(
      id: 'default',
      name: 'Tiền mặt',
      type: AccountType.cash,
      balance: 0,
      icon: '💵',
    );
    await addAccount(defaultAccount);
  }

  // ==================== TRANSACTIONS ====================

  /// Get all transactions
  List<Transaction> getAllTransactions() {
    final transactions = _transactionsBox.values
        .map((json) => Transaction.fromJson(jsonDecode(json)))
        .toList();
    transactions.sort((a, b) => b.date.compareTo(a.date));
    return transactions;
  }

  /// Get transactions for a specific month
  List<Transaction> getTransactionsForMonth(int year, int month) {
    return getAllTransactions().where((t) {
      return t.date.year == year && t.date.month == month;
    }).toList();
  }

  /// Get unconfirmed transactions
  List<Transaction> getUnconfirmedTransactions() {
    return getAllTransactions().where((t) => !t.isConfirmed).toList();
  }

  /// Add transaction
  Future<void> addTransaction(Transaction transaction) async {
    await _transactionsBox.put(
      transaction.id,
      jsonEncode(transaction.toJson()),
    );
    await _updateAccountBalance(transaction.accountId);
  }

  /// Update transaction
  Future<void> updateTransaction(Transaction transaction) async {
    await _transactionsBox.put(
      transaction.id,
      jsonEncode(transaction.toJson()),
    );
    await _updateAccountBalance(transaction.accountId);
  }

  /// Delete transaction
  Future<void> deleteTransaction(String id) async {
    final transaction = getAllTransactions().firstWhere(
      (t) => t.id == id,
      orElse: () => throw Exception('Transaction not found'),
    );
    final accountId = transaction.accountId;
    await _transactionsBox.delete(id);
    await _updateAccountBalance(accountId);
  }

  /// Clear all transactions
  Future<void> clearAllTransactions() async {
    await _transactionsBox.clear();
    // Reset account balances
    for (final account in getAllAccounts()) {
      account.balance = 0;
      await updateAccount(account);
    }
  }

  /// Update account balance based on transactions
  Future<void> _updateAccountBalance(String accountId) async {
    final account = getAccount(accountId);
    if (account == null) return;

    final transactions = getAllTransactions()
        .where((t) => t.accountId == accountId && t.isConfirmed)
        .toList();

    double balance = 0;
    for (final t in transactions) {
      balance += t.signedAmount;
    }

    account.balance = balance;
    await updateAccount(account);
  }

  // ==================== ACCOUNTS ====================

  /// Get all accounts
  List<Account> getAllAccounts() {
    return _accountsBox.values
        .map((json) => Account.fromJson(jsonDecode(json)))
        .toList();
  }

  /// Get account by ID
  Account? getAccount(String id) {
    final json = _accountsBox.get(id);
    if (json == null) return null;
    return Account.fromJson(jsonDecode(json));
  }

  /// Add account
  Future<void> addAccount(Account account) async {
    await _accountsBox.put(account.id, jsonEncode(account.toJson()));
  }

  /// Update account
  Future<void> updateAccount(Account account) async {
    await _accountsBox.put(account.id, jsonEncode(account.toJson()));
  }

  /// Delete account
  Future<void> deleteAccount(String id) async {
    await _accountsBox.delete(id);
  }

  /// Get total balance across all transactions
  double getTotalBalance() {
    final transactions = getAllTransactions().where((t) => t.isConfirmed);
    return transactions.fold(0.0, (sum, t) => sum + t.signedAmount);
  }

  // ==================== CATEGORIES ====================

  /// Get all categories
  List<TransactionCategory> getAllCategories() {
    return _categoriesBox.values
        .map((json) => TransactionCategory.fromJson(jsonDecode(json)))
        .toList();
  }

  /// Get category by ID
  TransactionCategory? getCategory(String id) {
    final json = _categoriesBox.get(id);
    if (json == null) return null;
    return TransactionCategory.fromJson(jsonDecode(json));
  }

  /// Add category
  Future<void> addCategory(TransactionCategory category) async {
    await _categoriesBox.put(category.id, jsonEncode(category.toJson()));
  }

  /// Update category
  Future<void> updateCategory(TransactionCategory category) async {
    await _categoriesBox.put(category.id, jsonEncode(category.toJson()));
  }

  /// Delete category
  Future<void> deleteCategory(String id) async {
    await _categoriesBox.delete(id);
  }

  // ==================== STATISTICS ====================

  /// Get monthly income
  double getMonthlyIncome(int year, int month) {
    return getTransactionsForMonth(year, month)
        .where((t) => t.isIncome && t.isConfirmed)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Get monthly expense
  double getMonthlyExpense(int year, int month) {
    return getTransactionsForMonth(year, month)
        .where((t) => t.isExpense && t.isConfirmed)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Get expense breakdown by category
  Map<String, double> getExpenseByCategory(int year, int month) {
    final transactions = getTransactionsForMonth(
      year,
      month,
    ).where((t) => t.isExpense && t.isConfirmed);

    final result = <String, double>{};
    for (final t in transactions) {
      result[t.categoryId] = (result[t.categoryId] ?? 0) + t.amount;
    }
    return result;
  }

  // ==================== DATA MANAGEMENT ====================

  /// Export all data as JSON map
  Map<String, dynamic> exportData() {
    return {
      'transactions': getAllTransactions().map((t) => t.toJson()).toList(),
      'accounts': getAllAccounts().map((a) => a.toJson()).toList(),
      'categories': getAllCategories().map((c) => c.toJson()).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
    };
  }

  /// Clear all data (transactions, accounts, but keep categories)
  Future<void> clearAllData() async {
    await _transactionsBox.clear();
    await _accountsBox.clear();
    // Keep categories but re-initialize defaults
    await _categoriesBox.clear();
    await _initDefaultCategories();
  }

  // ==================== SETTINGS ====================

  /// Get setting value
  String? getSetting(String key) {
    return _settingsBox.get(key);
  }

  /// Set setting value
  Future<void> setSetting(String key, String value) async {
    await _settingsBox.put(key, value);
  }

  /// Delete setting
  Future<void> deleteSetting(String key) async {
    await _settingsBox.delete(key);
  }

  // ==================== SECURITY ====================

  /// Check if PIN is set
  bool get hasPinLock => _settingsBox.containsKey('pin_hash');

  /// Get PIN hash
  String? get pinHash => _settingsBox.get('pin_hash');

  /// Set PIN
  Future<void> setPin(String pinHash) async {
    await _settingsBox.put('pin_hash', pinHash);
  }

  /// Remove PIN
  Future<void> removePin() async {
    await _settingsBox.delete('pin_hash');
  }

  /// Check if biometric is enabled
  bool get biometricEnabled => _settingsBox.get('biometric_enabled') == 'true';

  /// Set biometric status
  Future<void> setBiometricEnabled(bool enabled) async {
    await _settingsBox.put('biometric_enabled', enabled.toString());
  }
}
