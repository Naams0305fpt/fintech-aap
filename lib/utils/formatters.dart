import 'package:intl/intl.dart';

/// Currency and number formatting utilities for Vietnamese VND
class CurrencyFormatter {
  static final _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  // Used for compact format internally
  // ignore: unused_field
  static final _compactFormat = NumberFormat.compact(locale: 'vi_VN');

  /// Format amount as VND currency
  /// Example: 1500000 -> "1.500.000 ₫"
  static String formatVND(double amount) {
    return _currencyFormat.format(amount);
  }

  /// Alias for formatVND
  static String format(double amount) => formatVND(amount);

  /// Format amount with sign
  /// Example: 1500000, income=true -> "+1.500.000 ₫"
  static String formatWithSign(double amount, {required bool isIncome}) {
    final sign = isIncome ? '+' : '-';
    return '$sign${_currencyFormat.format(amount)}';
  }

  /// Format amount compact
  /// Example: 1500000 -> "1,5Tr"
  static String formatCompact(double amount) {
    if (amount >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(1)}Tỷ';
    } else if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}Tr';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }

  /// Parse VND string to double
  /// Example: "1.500.000" -> 1500000.0
  static double? parseVND(String text) {
    final cleaned = text
        .replaceAll('₫', '')
        .replaceAll('.', '')
        .replaceAll(',', '')
        .replaceAll(' ', '')
        .trim();
    return double.tryParse(cleaned);
  }
}

/// Date formatting utilities
class DateFormatter {
  static final _dateFormat = DateFormat('dd/MM/yyyy');
  static final _timeFormat = DateFormat('HH:mm');
  static final _dateTimeFormat = DateFormat('HH:mm dd/MM/yyyy');
  static final _monthYearFormat = DateFormat('MM/yyyy');

  /// Format date
  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }

  /// Format time
  static String formatTime(DateTime date) {
    return _timeFormat.format(date);
  }

  /// Format date and time
  static String formatDateTime(DateTime date) {
    return _dateTimeFormat.format(date);
  }

  /// Format month/year
  static String formatMonthYear(DateTime date) {
    return _monthYearFormat.format(date);
  }

  /// Get relative date string
  static String getRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final difference = today.difference(dateOnly).inDays;

    if (difference == 0) {
      return 'Hôm nay';
    } else if (difference == 1) {
      return 'Hôm qua';
    } else if (difference == -1) {
      return 'Ngày mai';
    } else if (difference > 0 && difference < 7) {
      return '$difference ngày trước';
    } else {
      return formatDate(date);
    }
  }

  /// Get month name in Vietnamese
  static String getMonthName(int month) {
    const months = [
      'Tháng 1',
      'Tháng 2',
      'Tháng 3',
      'Tháng 4',
      'Tháng 5',
      'Tháng 6',
      'Tháng 7',
      'Tháng 8',
      'Tháng 9',
      'Tháng 10',
      'Tháng 11',
      'Tháng 12',
    ];
    return months[month - 1];
  }
}

/// Security formatting utilities for masking sensitive data
class SecurityFormatter {
  /// Mask account number - show only last 4 digits
  /// Example: "1234567890" → "xxxxxx7890"
  static String maskAccountNumber(String? number) {
    if (number == null || number.isEmpty) return '';
    if (number.length <= 4) return number;

    final visiblePart = number.substring(number.length - 4);
    final maskedPart = 'x' * (number.length - 4);
    return maskedPart + visiblePart;
  }

  /// Mask account number with spaces for card format
  /// Example: "1234567890123456" → "xxxx xxxx xxxx 3456"
  static String maskCardNumber(String? number) {
    if (number == null || number.isEmpty) return '';
    final cleaned = number.replaceAll(' ', '').replaceAll('-', '');
    if (cleaned.length <= 4) return cleaned;

    final visiblePart = cleaned.substring(cleaned.length - 4);
    return 'xxxx xxxx xxxx $visiblePart';
  }

  /// Mask phone number - show only last 3 digits
  /// Example: "0912345678" → "xxxxxxx678"
  static String maskPhoneNumber(String? phone) {
    if (phone == null || phone.isEmpty) return '';
    if (phone.length <= 3) return phone;

    final visiblePart = phone.substring(phone.length - 3);
    final maskedPart = 'x' * (phone.length - 3);
    return maskedPart + visiblePart;
  }

  /// Mask text in SMS rawText - mask account numbers and phone numbers
  static String maskSensitiveText(String text) {
    // Mask patterns like account numbers (8+ digits)
    var masked = text.replaceAllMapped(
      RegExp(r'\b(\d{8,16})\b'),
      (match) => maskAccountNumber(match.group(1)),
    );
    return masked;
  }
}
