import '../models/transaction.dart';
import '../models/account.dart';
import '../models/category.dart';

/// Simple in-memory database service for MVP
/// TODO: Replace with Hive or SQLite for persistence
class DatabaseService {
  static DatabaseService? _instance;
  static DatabaseService get instance => _instance ??= DatabaseService._();

  DatabaseService._();

  // In-memory storage
  final List<Transaction> _transactions = [];
  final List<Account> _accounts = [];
  late List<TransactionCategory> _categories;

  bool _initialized = false;

  /// Initialize database
  Future<void> init() async {
    if (_initialized) return;

    // Initialize default categories
    _categories = TransactionCategory.allDefaultCategories;

    _initialized = true;
  }

  // ==================== TRANSACTIONS ====================

  /// Get all transactions
  List<Transaction> getAllTransactions() {
    return List.from(_transactions)..sort((a, b) => b.date.compareTo(a.date));
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
    _transactions.add(transaction);
    // Update account balance
    await _updateAccountBalance(transaction.accountId);
  }

  /// Update transaction
  Future<void> updateTransaction(Transaction transaction) async {
    final index = _transactions.indexWhere((t) => t.id == transaction.id);
    if (index != -1) {
      _transactions[index] = transaction;
      await _updateAccountBalance(transaction.accountId);
    }
  }

  /// Delete transaction
  Future<void> deleteTransaction(String id) async {
    final transaction = _transactions.firstWhere(
      (t) => t.id == id,
      orElse: () => throw Exception('Transaction not found'),
    );
    final accountId = transaction.accountId;
    _transactions.removeWhere((t) => t.id == id);
    await _updateAccountBalance(accountId);
  }

  /// Update account balance based on transactions
  Future<void> _updateAccountBalance(String accountId) async {
    final account = _accounts.where((a) => a.id == accountId).firstOrNull;
    if (account == null) return;

    final transactions = getAllTransactions()
        .where((t) => t.accountId == accountId && t.isConfirmed)
        .toList();

    double balance = 0;
    for (final t in transactions) {
      balance += t.signedAmount;
    }

    account.balance = balance;
  }

  // ==================== ACCOUNTS ====================

  /// Get all accounts
  List<Account> getAllAccounts() {
    return List.from(_accounts);
  }

  /// Get account by ID
  Account? getAccount(String id) {
    return _accounts.where((a) => a.id == id).firstOrNull;
  }

  /// Add account
  Future<void> addAccount(Account account) async {
    _accounts.add(account);
  }

  /// Update account
  Future<void> updateAccount(Account account) async {
    final index = _accounts.indexWhere((a) => a.id == account.id);
    if (index != -1) {
      _accounts[index] = account;
    }
  }

  /// Delete account
  Future<void> deleteAccount(String id) async {
    _accounts.removeWhere((a) => a.id == id);
    _transactions.removeWhere((t) => t.accountId == id);
  }

  /// Get total balance across all confirmed transactions
  double getTotalBalance() {
    // Calculate directly from transactions since accounts may not exist
    return _transactions
        .where((t) => t.isConfirmed)
        .fold(0.0, (sum, t) => sum + t.signedAmount);
  }

  // ==================== CATEGORIES ====================

  /// Get all categories
  List<TransactionCategory> getAllCategories() {
    return List.from(_categories);
  }

  /// Get income categories
  List<TransactionCategory> getIncomeCategories() {
    return _categories.where((c) => c.isIncome).toList();
  }

  /// Get expense categories
  List<TransactionCategory> getExpenseCategories() {
    return _categories.where((c) => c.isExpense).toList();
  }

  /// Get category by ID
  TransactionCategory? getCategory(String id) {
    return _categories.where((c) => c.id == id).firstOrNull;
  }

  /// Add category
  Future<void> addCategory(TransactionCategory category) async {
    _categories.add(category);
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

  /// Get expense by category for a month
  Map<String, double> getExpenseByCategory(int year, int month) {
    final transactions = getTransactionsForMonth(
      year,
      month,
    ).where((t) => t.isExpense && t.isConfirmed);

    final Map<String, double> result = {};
    for (final t in transactions) {
      result[t.categoryId] = (result[t.categoryId] ?? 0) + t.amount;
    }
    return result;
  }

  // ==================== BACKUP/RESTORE ====================

  /// Export all data as JSON
  Map<String, dynamic> exportData() {
    return {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'transactions': _transactions.map((t) => t.toJson()).toList(),
      'accounts': _accounts.map((a) => a.toJson()).toList(),
      'categories': _categories
          .where((c) => !c.isDefault)
          .map((c) => c.toJson())
          .toList(),
    };
  }

  /// Import data from JSON
  Future<void> importData(Map<String, dynamic> data) async {
    _transactions.clear();
    _accounts.clear();
    _categories = TransactionCategory.allDefaultCategories;

    if (data['transactions'] != null) {
      for (final json in data['transactions']) {
        _transactions.add(Transaction.fromJson(json));
      }
    }

    if (data['accounts'] != null) {
      for (final json in data['accounts']) {
        _accounts.add(Account.fromJson(json));
      }
    }

    if (data['categories'] != null) {
      for (final json in data['categories']) {
        _categories.add(TransactionCategory.fromJson(json));
      }
    }
  }

  /// Clear all data
  Future<void> clearAllData() async {
    _transactions.clear();
    _accounts.clear();
    _categories = TransactionCategory.allDefaultCategories;
  }
}
