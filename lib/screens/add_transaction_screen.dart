import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/transaction.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'package:uuid/uuid.dart';

/// Screen for adding a new transaction
class AddTransactionScreen extends StatefulWidget {
  final bool isIncome;

  const AddTransactionScreen({super.key, this.isIncome = false});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  late bool _isIncome;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String? _selectedCategoryId;
  String? _selectedAccountId;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _isIncome = widget.isIncome;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final categories = _isIncome
        ? provider.incomeCategories
        : provider.expenseCategories;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isIncome ? 'Thêm thu' : 'Thêm chi'),
        actions: [
          TextButton(onPressed: _saveTransaction, child: const Text('Lưu')),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Transaction Type Toggle
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _TypeButton(
                      label: 'Chi tiêu',
                      isSelected: !_isIncome,
                      color: AppTheme.danger,
                      onTap: () => setState(() => _isIncome = false),
                    ),
                  ),
                  Expanded(
                    child: _TypeButton(
                      label: 'Thu nhập',
                      isSelected: _isIncome,
                      color: AppTheme.success,
                      onTap: () => setState(() => _isIncome = true),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Amount Input
            const Text(
              'Số tiền',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                suffixText: '₫',
                suffixStyle: TextStyle(
                  color: _isIncome ? AppTheme.success : AppTheme.danger,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Category Selection
            const Text(
              'Danh mục',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.map<Widget>((category) {
                final isSelected = _selectedCategoryId == category.id;
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedCategoryId = category.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Color(category.colorValue).withAlpha(76)
                          : AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border.all(
                              color: Color(category.colorValue),
                              width: 2,
                            )
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          category.icon,
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          category.name,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Date Selection
            const Text('Ngày', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _selectDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      DateFormatter.getRelativeDate(_selectedDate),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Spacer(),
                    Text(
                      DateFormatter.formatDate(_selectedDate),
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Note
            const Text(
              'Ghi chú',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                hintText: 'Thêm ghi chú (tùy chọn)',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isIncome
                      ? AppTheme.success
                      : AppTheme.danger,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  _isIncome ? 'Thêm thu nhập' : 'Thêm chi tiêu',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  void _saveTransaction() {
    final amountText = _amountController.text
        .replaceAll('.', '')
        .replaceAll(',', '');
    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số tiền hợp lệ')),
      );
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng chọn danh mục')));
      return;
    }

    final transaction = Transaction(
      id: const Uuid().v4(),
      amount: amount,
      type: _isIncome ? TransactionType.income : TransactionType.expense,
      categoryId: _selectedCategoryId!,
      accountId: _selectedAccountId ?? 'default',
      note: _noteController.text.trim().isNotEmpty
          ? _noteController.text.trim()
          : null,
      date: _selectedDate,
      isConfirmed: true,
      source: TransactionSource.manual,
    );

    context.read<AppProvider>().addTransaction(transaction);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isIncome ? 'Đã thêm thu nhập' : 'Đã thêm chi tiêu'),
        backgroundColor: _isIncome ? AppTheme.success : AppTheme.danger,
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
