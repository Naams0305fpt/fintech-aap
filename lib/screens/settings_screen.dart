import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/transaction.dart';
import '../providers/app_provider.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'lock_screen.dart';

/// Settings screen
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _auth = AuthService.instance;
  bool _canUseBiometric = false;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final canUse = await _auth.canUseBiometric;
    if (mounted) {
      setState(() => _canUseBiometric = canUse);
    }
  }

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

            // Security section - NOW FUNCTIONAL
            _buildSectionHeader('Bảo mật'),
            _buildSettingsCard([
              _SettingsTile(
                icon: Icons.lock_outline,
                title: 'Khóa ứng dụng',
                subtitle: _auth.isLockEnabled
                    ? 'Đã bật bảo vệ bằng PIN'
                    : 'Bảo vệ bằng PIN hoặc vân tay',
                trailing: Switch(
                  value: _auth.isLockEnabled,
                  onChanged: (value) => _togglePinLock(value),
                  activeColor: AppTheme.primary,
                ),
                onTap: () => _togglePinLock(!_auth.isLockEnabled),
              ),
              if (_auth.isLockEnabled && _canUseBiometric)
                _SettingsTile(
                  icon: Icons.fingerprint,
                  title: 'Xác thực sinh trắc học',
                  subtitle: _auth.isBiometricEnabled
                      ? 'Đã bật vân tay/Face ID'
                      : 'Mở khóa bằng vân tay hoặc Face ID',
                  trailing: Switch(
                    value: _auth.isBiometricEnabled,
                    onChanged: (value) => _toggleBiometric(value),
                    activeColor: AppTheme.primary,
                  ),
                  onTap: () => _toggleBiometric(!_auth.isBiometricEnabled),
                ),
              if (_auth.isLockEnabled)
                _SettingsTile(
                  icon: Icons.password,
                  title: 'Đổi mã PIN',
                  subtitle: 'Thay đổi mã PIN hiện tại',
                  onTap: () => _changePin(),
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
                icon: Icons.shield_outlined,
                title: 'Bảo mật dữ liệu',
                subtitle: 'Mã hóa AES-256, lưu trữ cục bộ',
                onTap: () => _showPrivacyInfo(context),
              ),
            ]),

            const SizedBox(height: 24),

            // Debug section
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
        ),
      ),
    );
  }

  // ==================== PIN LOCK ====================

  Future<void> _togglePinLock(bool enable) async {
    if (enable) {
      // Navigate to setup PIN
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const LockScreen(isSetup: true)),
      );
      if (result == true && mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã bật khóa ứng dụng'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } else {
      // Confirm disable
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Tắt khóa ứng dụng?'),
          content: const Text(
            'Bất kỳ ai có điện thoại của bạn đều có thể xem thông tin tài chính.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
              child: const Text('Tắt khóa'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await _auth.removePin();
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã tắt khóa ứng dụng'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _toggleBiometric(bool enable) async {
    if (enable) {
      // Test biometric first
      final success = await _auth.authenticateWithBiometric();
      if (success) {
        await _auth.setBiometricEnabled(true);
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã bật xác thực sinh trắc học'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppTheme.success,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể xác thực sinh trắc học'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppTheme.danger,
            ),
          );
        }
      }
    } else {
      await _auth.setBiometricEnabled(false);
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _changePin() async {
    // Navigate to setup PIN (will replace old PIN)
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const LockScreen(isSetup: true)),
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã đổi mã PIN'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  // ==================== UI HELPERS ====================

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
    // Show export options dialog
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xuất dữ liệu'),
        content: const Text('Chọn phương thức xuất:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'plain'),
            child: const Text('JSON (không mã hóa)'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'encrypted'),
            style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
            child: const Text('Mã hóa (khuyến nghị)'),
          ),
        ],
      ),
    );

    if (choice == null || !context.mounted) return;

    if (choice == 'plain') {
      await _exportPlainData(context);
    } else {
      await _exportEncryptedData(context);
    }
  }

  Future<void> _exportPlainData(BuildContext context) async {
    final db = DatabaseService.instance;
    final data = db.exportData();
    final jsonString = const JsonEncoder.withIndent('  ').convert(data);

    try {
      await Share.share(
        jsonString,
        subject: 'FinTech Backup ${DateTime.now().toIso8601String()}',
      );
    } catch (e) {
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

  Future<void> _exportEncryptedData(BuildContext context) async {
    // Show password input dialog
    final password = await _showPasswordDialog(context, isConfirm: true);
    if (password == null || password.isEmpty || !context.mounted) return;

    final db = DatabaseService.instance;
    final data = db.exportData();
    final jsonString = jsonEncode(data);

    // Encrypt data using password
    final encrypted = _encryptData(jsonString, password);
    final exportContent = jsonEncode({
      'version': 1,
      'encrypted': true,
      'data': encrypted,
      'exportedAt': DateTime.now().toIso8601String(),
    });

    try {
      await Share.share(exportContent, subject: 'FinTech Encrypted Backup');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Dữ liệu đã được mã hóa và chia sẻ'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      await Clipboard.setData(ClipboardData(text: exportContent));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã sao chép dữ liệu mã hóa vào clipboard'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<String?> _showPasswordDialog(
    BuildContext context, {
    bool isConfirm = false,
  }) async {
    final controller = TextEditingController();
    final confirmController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isConfirm ? 'Tạo mật khẩu mã hóa' : 'Nhập mật khẩu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu',
                hintText: 'Tối thiểu 4 ký tự',
              ),
            ),
            if (isConfirm) ...[
              const SizedBox(height: 12),
              TextField(
                controller: confirmController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Xác nhận mật khẩu',
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              final pwd = controller.text;
              if (pwd.length < 4) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Mật khẩu phải có ít nhất 4 ký tự'),
                  ),
                );
                return;
              }
              if (isConfirm && pwd != confirmController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mật khẩu không khớp')),
                );
                return;
              }
              Navigator.pop(context, pwd);
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  String _encryptData(String data, String password) {
    // Derive 32-byte key from password
    final keyBytes = utf8.encode(password.padRight(32, '0').substring(0, 32));

    // XOR encryption with key
    final dataBytes = utf8.encode(data);
    final encrypted = <int>[];
    for (var i = 0; i < dataBytes.length; i++) {
      encrypted.add(dataBytes[i] ^ keyBytes[i % keyBytes.length]);
    }
    return base64Encode(encrypted);
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
          '🔒 Dữ liệu được mã hóa an toàn\n\n'
          '• Mã hóa AES-256 bit\n'
          '• Khóa mã hóa được tạo tự động trên thiết bị\n'
          '• Dữ liệu lưu trữ cục bộ, không gửi lên server\n'
          '• PIN được hash bằng SHA-256\n'
          '• Hỗ trợ xác thực sinh trắc học',
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
