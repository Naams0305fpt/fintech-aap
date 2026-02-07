/// Transaction types
enum TransactionType { income, expense }

/// Transaction source
enum TransactionSource { manual, notification }

/// Transaction model
class Transaction {
  String id;
  double amount;
  TransactionType type;
  String categoryId;
  String accountId;
  String? note;
  DateTime date;
  bool isConfirmed;
  TransactionSource source;
  String? rawNotification;
  DateTime createdAt;

  Transaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.accountId,
    this.note,
    required this.date,
    this.isConfirmed = true,
    this.source = TransactionSource.manual,
    this.rawNotification,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Check if income
  bool get isIncome => type == TransactionType.income;

  /// Check if expense
  bool get isExpense => type == TransactionType.expense;

  /// Get signed amount (positive for income, negative for expense)
  double get signedAmount => isIncome ? amount : -amount;

  /// Copy with new values
  Transaction copyWith({
    String? id,
    double? amount,
    TransactionType? type,
    String? categoryId,
    String? accountId,
    String? note,
    DateTime? date,
    bool? isConfirmed,
    TransactionSource? source,
    String? rawNotification,
  }) {
    return Transaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      note: note ?? this.note,
      date: date ?? this.date,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      source: source ?? this.source,
      rawNotification: rawNotification ?? this.rawNotification,
      createdAt: createdAt,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'type': type.index,
    'categoryId': categoryId,
    'accountId': accountId,
    'note': note,
    'date': date.toIso8601String(),
    'isConfirmed': isConfirmed,
    'source': source.index,
    'rawNotification': rawNotification,
    'createdAt': createdAt.toIso8601String(),
  };

  /// Create from JSON
  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
    id: json['id'],
    amount: json['amount'].toDouble(),
    type: TransactionType.values[json['type']],
    categoryId: json['categoryId'],
    accountId: json['accountId'],
    note: json['note'],
    date: DateTime.parse(json['date']),
    isConfirmed: json['isConfirmed'] ?? true,
    source: TransactionSource.values[json['source'] ?? 0],
    rawNotification: json['rawNotification'],
    createdAt: DateTime.parse(json['createdAt']),
  );
}
