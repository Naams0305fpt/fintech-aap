import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/transaction_list_item.dart';

/// Full transactions screen with filtering
class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _searchQuery = '';
  TransactionType? _typeFilter;
  String? _categoryFilter;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final transactions = _filterTransactions(provider);

        return SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Giao dịch',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Month selector
                    _buildMonthSelector(provider),
                  ],
                ),
              ),

              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm giao dịch...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppTheme.surfaceLight,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),

              // Filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _buildFilterChip(
                      label: 'Tất cả',
                      selected: _typeFilter == null,
                      onSelected: (_) => setState(() => _typeFilter = null),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: 'Thu nhập',
                      selected: _typeFilter == TransactionType.income,
                      onSelected: (_) =>
                          setState(() => _typeFilter = TransactionType.income),
                      color: AppTheme.success,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: 'Chi tiêu',
                      selected: _typeFilter == TransactionType.expense,
                      onSelected: (_) =>
                          setState(() => _typeFilter = TransactionType.expense),
                      color: AppTheme.danger,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: 'Chờ xác nhận',
                      selected: _categoryFilter == 'unconfirmed',
                      onSelected: (_) => setState(() {
                        _categoryFilter = _categoryFilter == 'unconfirmed'
                            ? null
                            : 'unconfirmed';
                      }),
                      color: AppTheme.warning,
                    ),
                  ],
                ),
              ),

              // Summary bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem(
                      'Thu',
                      provider.monthlyIncome,
                      AppTheme.success,
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: AppTheme.textMuted.withAlpha(51),
                    ),
                    _buildSummaryItem(
                      'Chi',
                      provider.monthlyExpense,
                      AppTheme.danger,
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: AppTheme.textMuted.withAlpha(51),
                    ),
                    _buildSummaryItem(
                      'Còn lại',
                      provider.monthlyBalance,
                      provider.monthlyBalance >= 0
                          ? AppTheme.success
                          : AppTheme.danger,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Transaction count
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      '${transactions.length} giao dịch',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Transactions list
              Expanded(
                child: transactions.isEmpty
                    ? _buildEmptyState()
                    : _buildTransactionsList(transactions, provider),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMonthSelector(AppProvider provider) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => provider.previousMonth(),
          iconSize: 20,
        ),
        GestureDetector(
          onTap: () => _selectMonth(context, provider),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              DateFormatter.formatMonthYear(provider.selectedMonth),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: provider.selectedMonth.isBefore(DateTime.now())
              ? () => provider.nextMonth()
              : null,
          iconSize: 20,
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required void Function(bool) onSelected,
    Color? color,
  }) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: (color ?? AppTheme.primary).withAlpha(51),
      checkmarkColor: color ?? AppTheme.primary,
      labelStyle: TextStyle(
        color: selected ? (color ?? AppTheme.primary) : AppTheme.textSecondary,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: selected ? (color ?? AppTheme.primary) : Colors.transparent,
      ),
      backgroundColor: AppTheme.surfaceLight,
    );
  }

  Widget _buildSummaryItem(String label, double amount, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          CurrencyFormatter.formatCompact(amount),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: AppTheme.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'Không tìm thấy giao dịch'
                : 'Chưa có giao dịch trong tháng này',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(
    List<Transaction> transactions,
    AppProvider provider,
  ) {
    // Group transactions by date
    final Map<String, List<Transaction>> grouped = {};
    for (final t in transactions) {
      final key = DateFormatter.formatDate(t.date);
      grouped[key] ??= [];
      grouped[key]!.add(t);
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final date = grouped.keys.elementAt(index);
        final items = grouped[date]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                date,
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // Transactions for this date
            ...items.map((transaction) {
              final category = provider.getCategory(transaction.categoryId);
              return Dismissible(
                key: Key(transaction.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: AppTheme.danger,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (_) => _confirmDelete(transaction),
                onDismissed: (_) {
                  provider.deleteTransaction(transaction.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã xóa giao dịch')),
                  );
                },
                child: TransactionListItem(
                  transaction: transaction,
                  category: category,
                  onTap: () => _showTransactionDetails(transaction, category),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  List<Transaction> _filterTransactions(AppProvider provider) {
    var transactions = provider.monthlyTransactions;

    // Filter by type
    if (_typeFilter != null) {
      transactions = transactions.where((t) => t.type == _typeFilter).toList();
    }

    // Filter by unconfirmed
    if (_categoryFilter == 'unconfirmed') {
      transactions = transactions.where((t) => !t.isConfirmed).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      transactions = transactions.where((t) {
        final category = provider.getCategory(t.categoryId);
        final categoryName = category?.name.toLowerCase() ?? '';
        final note = t.note?.toLowerCase() ?? '';
        final amount = CurrencyFormatter.format(t.amount).toLowerCase();
        return categoryName.contains(query) ||
            note.contains(query) ||
            amount.contains(query);
      }).toList();
    }

    return transactions;
  }

  Future<void> _selectMonth(BuildContext context, AppProvider provider) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: provider.selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (selected != null) {
      provider.setSelectedMonth(DateTime(selected.year, selected.month));
    }
  }

  Future<bool> _confirmDelete(Transaction transaction) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Xóa giao dịch?'),
            content: Text(
              'Bạn có chắc muốn xóa giao dịch ${CurrencyFormatter.format(transaction.amount)}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
                child: const Text('Xóa'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showTransactionDetails(
    Transaction transaction,
    TransactionCategory? category,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: category != null
                        ? Color(category.colorValue).withAlpha(51)
                        : AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      category?.icon ?? '💰',
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category?.name ?? 'Không phân loại',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormatter.formatDateTime(transaction.date),
                        style: TextStyle(color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Amount
            Center(
              child: Text(
                CurrencyFormatter.formatWithSign(
                  transaction.amount,
                  isIncome: transaction.isIncome,
                ),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: transaction.isIncome
                      ? AppTheme.success
                      : AppTheme.danger,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Details
            if (transaction.note != null && transaction.note!.isNotEmpty) ...[
              _buildDetailRow('Ghi chú', transaction.note!),
              const SizedBox(height: 12),
            ],
            _buildDetailRow(
              'Nguồn',
              transaction.source == TransactionSource.manual
                  ? 'Nhập tay'
                  : 'Tự động từ thông báo',
            ),
            if (!transaction.isConfirmed) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withAlpha(51),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.warning_amber,
                      color: AppTheme.warning,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Chờ xác nhận',
                      style: TextStyle(
                        color: AppTheme.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Actions
            Row(
              children: [
                if (!transaction.isConfirmed)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        transaction.isConfirmed = true;
                        context.read<AppProvider>().updateTransaction(
                          transaction,
                        );
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Xác nhận'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                if (!transaction.isConfirmed) const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _confirmDelete(transaction).then((confirmed) {
                        if (confirmed) {
                          context.read<AppProvider>().deleteTransaction(
                            transaction.id,
                          );
                        }
                      });
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Xóa'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.danger,
                      side: const BorderSide(color: AppTheme.danger),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: TextStyle(color: AppTheme.textMuted)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
