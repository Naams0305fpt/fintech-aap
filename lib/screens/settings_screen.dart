import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/transaction.dart';
import '../providers/app_provider.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';

/// Settings screen
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Cài đặt',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),

            // Account section
            _buildSectionHeader('Tài khoản'),
            _buildSettingsCard([
              _SettingsTile(
                icon: Icons.account_balance_wallet,
                title: 'Quản lý tài khoản',
                subtitle: 'Thêm, sửa, xóa tài khoản ngân hàng',
                onTap: () => _showComingSoon(context),
              ),
              _SettingsTile(
                icon: Icons.category,
                title: 'Quản lý danh mục',
                subtitle: 'Tùy chỉnh danh mục thu chi',
                onTap: () => _showComingSoon(context),
              ),
            ]),

            // Notifications section
            _buildSectionHeader('Thông báo'),
            _buildSettingsCard([
              _SettingsTile(
                icon: Icons.notifications_active,
                title: 'Thông báo ngân hàng',
                subtitle: 'Tự động ghi nhận giao dịch từ SMS/Push',
                trailing: Switch(
                  value: false,
                  onChanged: (value) => _showComingSoon(context),
                  activeColor: AppTheme.primary,
                ),
                onTap: () => _showNotificationPermission(context),
              ),
              _SettingsTile(
                icon: Icons.account_balance,
                title: 'Ngân hàng được hỗ trợ',
                subtitle: 'Agribank, TPBank',
                onTap: () => _showSupportedBanks(context),
              ),
            ]),

            // Security section
            _buildSectionHeader('Bảo mật'),
            _buildSettingsCard([
              _SettingsTile(
                icon: Icons.lock_outline,
                title: 'Khóa ứng dụng',
                subtitle: 'Bảo vệ bằng PIN hoặc vân tay',
                trailing: Switch(
                  value: false,
                  onChanged: (value) => _showComingSoon(context),
                  activeColor: AppTheme.primary,
                ),
                onTap: () => _showComingSoon(context),
              ),
              _SettingsTile(
                icon: Icons.fingerprint,
                title: 'Xác thực sinh trắc học',
                subtitle: 'Mở khóa bằng vân tay hoặc Face ID',
                onTap: () => _showComingSoon(context),
              ),
            ]),

            // Data section
            _buildSectionHeader('Dữ liệu'),
            _buildSettingsCard([
              _SettingsTile(
                icon: Icons.file_download,
                title: 'Xuất dữ liệu',
                subtitle: 'Sao lưu dữ liệu ra file JSON',
                onTap: () => _exportData(context),
              ),
              _SettingsTile(
                icon: Icons.file_upload,
                title: 'Nhập dữ liệu',
                subtitle: 'Khôi phục từ file sao lưu',
                onTap: () => _showComingSoon(context),
              ),
              _SettingsTile(
                icon: Icons.delete_forever,
                title: 'Xóa tất cả dữ liệu',
                subtitle: 'Xóa toàn bộ giao dịch và tài khoản',
                titleColor: AppTheme.danger,
                onTap: () => _confirmClearData(context),
              ),
            ]),

            // About section
            _buildSectionHeader('Thông tin'),
            _buildSettingsCard([
              _SettingsTile(
                icon: Icons.info_outline,
                title: 'Phiên bản',
                subtitle: '1.0.0 (MVP)',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.code,
                title: 'Nhà phát triển',
                subtitle: 'FinTech Team',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Chính sách bảo mật',
                subtitle: 'Dữ liệu được lưu trữ cục bộ',
                onTap: () => _showPrivacyInfo(context),
              ),
            ]),

            const SizedBox(height: 24),

            // Debug section (only in debug mode)
            if (true) ...[
              _buildSectionHeader('Debug'),
              _buildSettingsCard([
                _SettingsTile(
                  icon: Icons.bug_report,
                  title: 'Thêm dữ liệu mẫu',
                  subtitle: 'Tạo giao dịch giả để test',
                  onTap: () => _addSampleData(context),
                ),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.textMuted,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: children.map((child) {
          final index = children.indexOf(child);
          return Column(
            children: [
              child,
              if (index < children.length - 1)
                Divider(height: 1, indent: 56, color: AppTheme.surface),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tính năng đang được phát triển'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showNotificationPermission(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quyền thông báo'),
        content: const Text(
          'Để tự động ghi nhận giao dịch, ứng dụng cần quyền đọc thông báo.\n\n'
          'Bật quyền này trong Cài đặt > Ứng dụng > FinTech > Thông báo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  void _showSupportedBanks(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ngân hàng được hỗ trợ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBankItem('🏦', 'Agribank', 'SMS thông báo giao dịch'),
            const SizedBox(height: 12),
            _buildBankItem('🏦', 'TPBank', 'Push notification'),
            const Divider(height: 24),
            Text(
              'Thêm ngân hàng khác sẽ được cập nhật trong các phiên bản sau.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildBankItem(String icon, String name, String description) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(
                description,
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _exportData(BuildContext context) async {
    final db = DatabaseService.instance;
    final data = db.exportData();
    final jsonString = const JsonEncoder.withIndent('  ').convert(data);

    try {
      await Share.share(
        jsonString,
        subject: 'FinTech Backup ${DateTime.now().toIso8601String()}',
      );
    } catch (e) {
      // Fallback: copy to clipboard
      await Clipboard.setData(ClipboardData(text: jsonString));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã sao chép dữ liệu vào clipboard'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _confirmClearData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tất cả dữ liệu?'),
        content: const Text(
          'Hành động này không thể hoàn tác.\n'
          'Tất cả giao dịch, tài khoản và cài đặt sẽ bị xóa vĩnh viễn.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            child: const Text('Xóa tất cả'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final db = DatabaseService.instance;
      await db.clearAllData();
      await context.read<AppProvider>().refresh();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xóa tất cả dữ liệu'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showPrivacyInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bảo mật dữ liệu'),
        content: const Text(
          '🔒 Dữ liệu hoàn toàn cục bộ\n\n'
          '• Tất cả dữ liệu được lưu trên thiết bị của bạn\n'
          '• Không gửi dữ liệu lên server\n'
          '• Không chia sẻ với bên thứ ba\n'
          '• Bạn có toàn quyền kiểm soát dữ liệu\n\n'
          'Để bảo vệ tốt hơn, hãy bật khóa ứng dụng.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  Future<void> _addSampleData(BuildContext context) async {
    final provider = context.read<AppProvider>();
    final now = DateTime.now();

    // Sample transactions for testing
    final sampleTransactions = [
      {
        'amount': 15000000.0,
        'isIncome': true,
        'categoryId': 'income_salary',
        'note': 'Lương tháng ${now.month}',
      },
      {
        'amount': 2000000.0,
        'isIncome': true,
        'categoryId': 'income_bonus',
        'note': 'Thưởng KPI',
      },
      {
        'amount': 150000.0,
        'isIncome': false,
        'categoryId': 'expense_food',
        'note': 'Ăn trưa',
      },
      {
        'amount': 200000.0,
        'isIncome': false,
        'categoryId': 'expense_food',
        'note': 'Đi ăn tối với bạn',
      },
      {
        'amount': 50000.0,
        'isIncome': false,
        'categoryId': 'expense_transport',
        'note': 'Grab đi làm',
      },
      {
        'amount': 1500000.0,
        'isIncome': false,
        'categoryId': 'expense_shopping',
        'note': 'Quần áo',
      },
      {
        'amount': 500000.0,
        'isIncome': false,
        'categoryId': 'expense_entertainment',
        'note': 'Xem phim + popcorn',
      },
      {
        'amount': 2000000.0,
        'isIncome': false,
        'categoryId': 'expense_bills',
        'note': 'Tiền điện + nước',
      },
      {
        'amount': 300000.0,
        'isIncome': false,
        'categoryId': 'expense_health',
        'note': 'Thuốc cảm',
      },
      {
        'amount': 800000.0,
        'isIncome': false,
        'categoryId': 'expense_education',
        'note': 'Sách tiếng Anh',
      },
    ];

    for (var i = 0; i < sampleTransactions.length; i++) {
      final data = sampleTransactions[i];
      final transaction = Transaction(
        id: 'sample_${DateTime.now().millisecondsSinceEpoch}_$i',
        amount: data['amount'] as double,
        type: (data['isIncome'] as bool)
            ? TransactionType.income
            : TransactionType.expense,
        categoryId: data['categoryId'] as String,
        accountId: 'default',
        note: data['note'] as String,
        date: now.subtract(Duration(days: i)),
        isConfirmed: true,
        source: TransactionSource.manual,
      );
      await provider.addTransaction(transaction);
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã thêm ${sampleTransactions.length} giao dịch mẫu'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }
}

/// Settings tile widget
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback onTap;
  final Color? titleColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    required this.onTap,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: titleColor ?? AppTheme.primary, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w500, color: titleColor),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
      ),
      trailing:
          trailing ??
          const Icon(Icons.chevron_right, color: AppTheme.textMuted),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
