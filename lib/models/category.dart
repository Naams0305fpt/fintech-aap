import 'package:flutter/material.dart';

/// Category type
enum CategoryType { income, expense }

/// Transaction Category model
class TransactionCategory {
  String id;
  String name;
  CategoryType type;
  String icon;
  int colorValue;
  bool isDefault;
  DateTime createdAt;

  TransactionCategory({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.colorValue,
    this.isDefault = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Check if income category
  bool get isIncome => type == CategoryType.income;

  /// Check if expense category
  bool get isExpense => type == CategoryType.expense;

  /// Get color
  Color get color => Color(colorValue);

  /// Get default income categories
  static List<TransactionCategory> get defaultIncomeCategories => [
    TransactionCategory(
      id: 'income_salary',
      name: 'Lương',
      type: CategoryType.income,
      icon: '💵',
      colorValue: 0xFF10B981,
      isDefault: true,
    ),
    TransactionCategory(
      id: 'income_bonus',
      name: 'Thưởng',
      type: CategoryType.income,
      icon: '🎁',
      colorValue: 0xFF34D399,
      isDefault: true,
    ),
    TransactionCategory(
      id: 'income_investment',
      name: 'Đầu tư',
      type: CategoryType.income,
      icon: '📈',
      colorValue: 0xFF059669,
      isDefault: true,
    ),
    TransactionCategory(
      id: 'income_other',
      name: 'Thu khác',
      type: CategoryType.income,
      icon: '💰',
      colorValue: 0xFF6EE7B7,
      isDefault: true,
    ),
  ];

  /// Get default expense categories
  static List<TransactionCategory> get defaultExpenseCategories => [
    TransactionCategory(
      id: 'expense_food',
      name: 'Ăn uống',
      type: CategoryType.expense,
      icon: '🍜',
      colorValue: 0xFFEF4444,
      isDefault: true,
    ),
    TransactionCategory(
      id: 'expense_transport',
      name: 'Di chuyển',
      type: CategoryType.expense,
      icon: '🚗',
      colorValue: 0xFFF59E0B,
      isDefault: true,
    ),
    TransactionCategory(
      id: 'expense_shopping',
      name: 'Mua sắm',
      type: CategoryType.expense,
      icon: '🛒',
      colorValue: 0xFFEC4899,
      isDefault: true,
    ),
    TransactionCategory(
      id: 'expense_entertainment',
      name: 'Giải trí',
      type: CategoryType.expense,
      icon: '🎮',
      colorValue: 0xFF8B5CF6,
      isDefault: true,
    ),
    TransactionCategory(
      id: 'expense_bills',
      name: 'Hóa đơn',
      type: CategoryType.expense,
      icon: '📄',
      colorValue: 0xFF3B82F6,
      isDefault: true,
    ),
    TransactionCategory(
      id: 'expense_health',
      name: 'Sức khỏe',
      type: CategoryType.expense,
      icon: '🏥',
      colorValue: 0xFF14B8A6,
      isDefault: true,
    ),
    TransactionCategory(
      id: 'expense_education',
      name: 'Giáo dục',
      type: CategoryType.expense,
      icon: '📚',
      colorValue: 0xFF6366F1,
      isDefault: true,
    ),
    TransactionCategory(
      id: 'expense_other',
      name: 'Chi khác',
      type: CategoryType.expense,
      icon: '📦',
      colorValue: 0xFF64748B,
      isDefault: true,
    ),
  ];

  /// Get all default categories
  static List<TransactionCategory> get allDefaultCategories => [
    ...defaultIncomeCategories,
    ...defaultExpenseCategories,
  ];

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.index,
    'icon': icon,
    'colorValue': colorValue,
    'isDefault': isDefault,
    'createdAt': createdAt.toIso8601String(),
  };

  /// Create from JSON
  factory TransactionCategory.fromJson(Map<String, dynamic> json) =>
      TransactionCategory(
        id: json['id'],
        name: json['name'],
        type: CategoryType.values[json['type']],
        icon: json['icon'],
        colorValue: json['colorValue'],
        isDefault: json['isDefault'] ?? false,
        createdAt: DateTime.parse(json['createdAt']),
      );
}
