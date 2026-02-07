import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../models/account.dart';
import '../models/category.dart';
import '../services/database_service.dart';

/// Main application state provider
class AppProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  // Data
  List<Transaction> _transactions = [];
  List<Account> _accounts = [];
  List<TransactionCategory> _categories = [];

  List<Transaction> get transactions => _transactions;
  List<Account> get accounts => _accounts;
  List<TransactionCategory> get categories => _categories;

  // Filtered categories
  List<TransactionCategory> get incomeCategories =>
      _categories.where((c) => c.isIncome).toList();
  List<TransactionCategory> get expenseCategories =>
      _categories.where((c) => c.isExpense).toList();

  // Selected month for statistics
  DateTime _selectedMonth = DateTime.now();
  DateTime get selectedMonth => _selectedMonth;

  // Monthly stats
  double _monthlyIncome = 0;
  double _monthlyExpense = 0;
  double get monthlyIncome => _monthlyIncome;
  double get monthlyExpense => _monthlyExpense;
  double get monthlyBalance => _monthlyIncome - _monthlyExpense;

  /// Initialize provider
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    await _db.init();
    await _loadData();

    _isLoading = false;
    notifyListeners();
  }

  /// Load data from database
  Future<void> _loadData() async {
    _transactions = _db.getAllTransactions();
    _accounts = _db.getAllAccounts();
    _categories = _db.getAllCategories();
    _calculateMonthlyStats();
  }

  /// Refresh data
  Future<void> refresh() async {
    await _loadData();
    notifyListeners();
  }

  /// Calculate monthly statistics
  void _calculateMonthlyStats() {
    _monthlyIncome = _db.getMonthlyIncome(
      _selectedMonth.year,
      _selectedMonth.month,
    );
    _monthlyExpense = _db.getMonthlyExpense(
      _selectedMonth.year,
      _selectedMonth.month,
    );
  }

  /// Change selected month
  void setSelectedMonth(DateTime month) {
    _selectedMonth = month;
    _calculateMonthlyStats();
    notifyListeners();
  }

  /// Go to previous month
  void previousMonth() {
    setSelectedMonth(DateTime(_selectedMonth.year, _selectedMonth.month - 1));
  }

  /// Go to next month
  void nextMonth() {
    setSelectedMonth(DateTime(_selectedMonth.year, _selectedMonth.month + 1));
  }

  // ==================== TRANSACTIONS ====================

  /// Add transaction
  Future<void> addTransaction(Transaction transaction) async {
    await _db.addTransaction(transaction);
    await refresh();
  }

  /// Update transaction
  Future<void> updateTransaction(Transaction transaction) async {
    await _db.updateTransaction(transaction);
    await refresh();
  }

  /// Delete transaction
  Future<void> deleteTransaction(String id) async {
    await _db.deleteTransaction(id);
    await refresh();
  }

  /// Get transactions for selected month
  List<Transaction> get monthlyTransactions {
    return _db.getTransactionsForMonth(
      _selectedMonth.year,
      _selectedMonth.month,
    );
  }

  /// Get recent transactions (last 5)
  List<Transaction> get recentTransactions {
    final all = _db.getAllTransactions();
    return all.take(5).toList();
  }

  /// Get unconfirmed transactions
  List<Transaction> get unconfirmedTransactions {
    return _db.getUnconfirmedTransactions();
  }

  // ==================== ACCOUNTS ====================

  /// Get total balance across all accounts
  double get totalBalance => _db.getTotalBalance();

  /// Add account
  Future<void> addAccount(Account account) async {
    await _db.addAccount(account);
    await refresh();
  }

  /// Update account
  Future<void> updateAccount(Account account) async {
    await _db.updateAccount(account);
    await refresh();
  }

  /// Delete account
  Future<void> deleteAccount(String id) async {
    await _db.deleteAccount(id);
    await refresh();
  }

  // ==================== CATEGORIES ====================

  /// Get category by ID
  TransactionCategory? getCategory(String id) {
    return _db.getCategory(id);
  }

  /// Add category
  Future<void> addCategory(TransactionCategory category) async {
    await _db.addCategory(category);
    await refresh();
  }

  // ==================== STATISTICS ====================

  /// Get expense breakdown by category for selected month
  Map<String, double> get expenseByCategory {
    return _db.getExpenseByCategory(_selectedMonth.year, _selectedMonth.month);
  }
}
