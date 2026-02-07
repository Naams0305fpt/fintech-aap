/// Account types
enum AccountType { bank, cash, eWallet, other }

/// Supported banks
enum BankName { agribank, tpbank, none }

/// Account model
class Account {
  String id;
  String name;
  AccountType type;
  double balance;
  BankName? bankName;
  String? accountNumber;
  String icon;
  DateTime createdAt;

  Account({
    required this.id,
    required this.name,
    required this.type,
    this.balance = 0,
    this.bankName,
    this.accountNumber,
    this.icon = '💰',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Check if this is a bank account
  bool get isBank => type == AccountType.bank;

  /// Get bank display name
  String get bankDisplayName {
    switch (bankName) {
      case BankName.agribank:
        return 'Agribank';
      case BankName.tpbank:
        return 'TPBank';
      default:
        return '';
    }
  }

  /// Copy with new values
  Account copyWith({
    String? id,
    String? name,
    AccountType? type,
    double? balance,
    BankName? bankName,
    String? accountNumber,
    String? icon,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      icon: icon ?? this.icon,
      createdAt: createdAt,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.index,
    'balance': balance,
    'bankName': bankName?.index,
    'accountNumber': accountNumber,
    'icon': icon,
    'createdAt': createdAt.toIso8601String(),
  };

  /// Create from JSON
  factory Account.fromJson(Map<String, dynamic> json) => Account(
    id: json['id'],
    name: json['name'],
    type: AccountType.values[json['type']],
    balance: json['balance']?.toDouble() ?? 0,
    bankName: json['bankName'] != null
        ? BankName.values[json['bankName']]
        : null,
    accountNumber: json['accountNumber'],
    icon: json['icon'] ?? '💰',
    createdAt: DateTime.parse(json['createdAt']),
  );
}
