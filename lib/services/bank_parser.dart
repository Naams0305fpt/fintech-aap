/// Bank notification parser for Agribank and TPBank
class BankNotificationParser {
  /// Parse TPBank notification
  /// Format:
  /// (TPBank): 07/02/26;15:03
  /// TK: xxxx2010205
  /// PS:+4.000VND
  /// SD KHA DUNG: 7.003VND
  /// ND: PHAM HUYNH SUM chuyen tien
  /// SO GD: 570CTMB260380195
  static ParsedNotification? parseTPBank(String text) {
    try {
      // Check if TPBank notification
      if (!text.contains('TPBank') && !text.contains('(TPBank)')) {
        return null;
      }

      // Parse amount (PS: +/- amount)
      final amountRegex = RegExp(
        r'PS:\s*([+-]?[\d.,]+)\s*VND',
        caseSensitive: false,
      );
      final amountMatch = amountRegex.firstMatch(text);
      if (amountMatch == null) return null;

      String amountStr = amountMatch
          .group(1)!
          .replaceAll('.', '')
          .replaceAll(',', '');
      double amount = double.tryParse(amountStr) ?? 0;
      bool isIncome =
          amountStr.startsWith('+') ||
          (!amountStr.startsWith('-') && amount > 0);
      amount = amount.abs();

      // Parse balance (SD KHA DUNG)
      double? balance;
      final balanceRegex = RegExp(
        r'SD KHA DUNG:\s*([\d.,]+)\s*VND',
        caseSensitive: false,
      );
      final balanceMatch = balanceRegex.firstMatch(text);
      if (balanceMatch != null) {
        balance = double.tryParse(
          balanceMatch.group(1)!.replaceAll('.', '').replaceAll(',', ''),
        );
      }

      // Parse account number
      String? accountNumber;
      final accountRegex = RegExp(r'TK:\s*(\w+)', caseSensitive: false);
      final accountMatch = accountRegex.firstMatch(text);
      if (accountMatch != null) {
        accountNumber = accountMatch.group(1);
      }

      // Parse description (ND)
      String? description;
      final descRegex = RegExp(
        r'ND:\s*(.+?)(?:\n|SO GD|$)',
        caseSensitive: false,
      );
      final descMatch = descRegex.firstMatch(text);
      if (descMatch != null) {
        description = descMatch.group(1)?.trim();
      }

      // Parse date/time
      DateTime? dateTime;
      final dateRegex = RegExp(
        r'\(TPBank\):\s*(\d{2}/\d{2}/\d{2});(\d{2}:\d{2})',
      );
      final dateMatch = dateRegex.firstMatch(text);
      if (dateMatch != null) {
        final datePart = dateMatch.group(1)!;
        final timePart = dateMatch.group(2)!;
        final parts = datePart.split('/');
        if (parts.length == 3) {
          final day = int.tryParse(parts[0]) ?? 1;
          final month = int.tryParse(parts[1]) ?? 1;
          final year = 2000 + (int.tryParse(parts[2]) ?? 26);
          final timeParts = timePart.split(':');
          final hour = int.tryParse(timeParts[0]) ?? 0;
          final minute = int.tryParse(timeParts[1]) ?? 0;
          dateTime = DateTime(year, month, day, hour, minute);
        }
      }

      return ParsedNotification(
        bankName: 'TPBank',
        amount: amount,
        isIncome: isIncome,
        balance: balance,
        accountNumber: accountNumber,
        description: description,
        dateTime: dateTime ?? DateTime.now(),
        rawText: text,
      );
    } catch (e) {
      return null;
    }
  }

  /// Parse Agribank notification
  /// Format:
  /// Agribank: 14:28 07/02/2026 Tài khoản 4603205191514: -22,000VND.
  /// Nội dung giao dịch: Vietcombank:1054381512:PHAM HUYNH SUM chuyen tien.
  /// Số dư cuối: 1,680,462VND
  static ParsedNotification? parseAgribank(String text) {
    try {
      // Check if Agribank notification
      if (!text.contains('Agribank')) {
        return null;
      }

      // Parse amount
      final amountRegex = RegExp(
        r':\s*([+-]?[\d.,]+)\s*VND\.?',
        caseSensitive: false,
      );
      final amountMatch = amountRegex.firstMatch(text);
      if (amountMatch == null) return null;

      String amountStr = amountMatch
          .group(1)!
          .replaceAll('.', '')
          .replaceAll(',', '');
      double amount = double.tryParse(amountStr) ?? 0;
      bool isIncome =
          amountStr.startsWith('+') ||
          (!amountStr.startsWith('-') && amount > 0);
      amount = amount.abs();

      // Parse balance (Số dư cuối)
      double? balance;
      final balanceRegex = RegExp(
        r'Số dư cuối:\s*([\d.,]+)\s*VND',
        caseSensitive: false,
      );
      final balanceMatch = balanceRegex.firstMatch(text);
      if (balanceMatch != null) {
        balance = double.tryParse(
          balanceMatch.group(1)!.replaceAll('.', '').replaceAll(',', ''),
        );
      }

      // Parse account number
      String? accountNumber;
      final accountRegex = RegExp(r'Tài khoản\s*(\d+)', caseSensitive: false);
      final accountMatch = accountRegex.firstMatch(text);
      if (accountMatch != null) {
        accountNumber = accountMatch.group(1);
      }

      // Parse description (Nội dung giao dịch)
      String? description;
      final descRegex = RegExp(
        r'Nội dung giao dịch:\s*(.+?)(?:\.|Số dư|$)',
        caseSensitive: false,
      );
      final descMatch = descRegex.firstMatch(text);
      if (descMatch != null) {
        description = descMatch.group(1)?.trim();
      }

      // Parse date/time
      DateTime? dateTime;
      final dateRegex = RegExp(r'(\d{2}:\d{2})\s+(\d{2}/\d{2}/\d{4})');
      final dateMatch = dateRegex.firstMatch(text);
      if (dateMatch != null) {
        final timePart = dateMatch.group(1)!;
        final datePart = dateMatch.group(2)!;
        final dateParts = datePart.split('/');
        if (dateParts.length == 3) {
          final day = int.tryParse(dateParts[0]) ?? 1;
          final month = int.tryParse(dateParts[1]) ?? 1;
          final year = int.tryParse(dateParts[2]) ?? 2026;
          final timeParts = timePart.split(':');
          final hour = int.tryParse(timeParts[0]) ?? 0;
          final minute = int.tryParse(timeParts[1]) ?? 0;
          dateTime = DateTime(year, month, day, hour, minute);
        }
      }

      return ParsedNotification(
        bankName: 'Agribank',
        amount: amount,
        isIncome: isIncome,
        balance: balance,
        accountNumber: accountNumber,
        description: description,
        dateTime: dateTime ?? DateTime.now(),
        rawText: text,
      );
    } catch (e) {
      return null;
    }
  }

  /// Parse any bank notification
  static ParsedNotification? parse(String text) {
    // Try TPBank first
    var result = parseTPBank(text);
    if (result != null) return result;

    // Try Agribank
    result = parseAgribank(text);
    if (result != null) return result;

    return null;
  }
}

/// Parsed notification result
class ParsedNotification {
  final String bankName;
  final double amount;
  final bool isIncome;
  final double? balance;
  final String? accountNumber;
  final String? description;
  final DateTime dateTime;
  final String rawText;

  ParsedNotification({
    required this.bankName,
    required this.amount,
    required this.isIncome,
    this.balance,
    this.accountNumber,
    this.description,
    required this.dateTime,
    required this.rawText,
  });

  @override
  String toString() {
    return 'ParsedNotification(bank: $bankName, amount: ${isIncome ? '+' : '-'}$amount, balance: $balance)';
  }
}
