import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/transaction.dart';
import '../utils/formatters.dart';

/// AI Service for financial insights using Gemini
class AIService {
  static AIService? _instance;
  static AIService get instance => _instance ??= AIService._();

  AIService._();

  GenerativeModel? _model;
  bool _initialized = false;

  /// Get API key from environment
  String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  /// Initialize AI service
  Future<void> init() async {
    if (_initialized || _apiKey.isEmpty) return;

    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 1024,
      ),
    );
    _initialized = true;
  }

  /// Check if AI is configured
  bool get isConfigured => _apiKey.isNotEmpty;

  /// Analyze spending and provide insights
  Future<String> analyzeSpending({
    required List<Transaction> transactions,
    required double totalIncome,
    required double totalExpense,
    required Map<String, double> expenseByCategory,
    required Map<String, String> categoryNames,
  }) async {
    if (!isConfigured) {
      return _getDefaultInsights(
        totalIncome,
        totalExpense,
        expenseByCategory,
        categoryNames,
      );
    }

    await init();

    final prompt = _buildSpendingPrompt(
      transactions: transactions,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      expenseByCategory: expenseByCategory,
      categoryNames: categoryNames,
    );

    try {
      final response = await _model!.generateContent([Content.text(prompt)]);
      return response.text ?? 'Không thể phân tích dữ liệu.';
    } catch (e) {
      return 'Lỗi kết nối AI: $e';
    }
  }

  /// Build spending analysis prompt
  String _buildSpendingPrompt({
    required List<Transaction> transactions,
    required double totalIncome,
    required double totalExpense,
    required Map<String, double> expenseByCategory,
    required Map<String, String> categoryNames,
  }) {
    final buffer = StringBuffer();
    buffer.writeln(
      'Bạn là một cố vấn tài chính cá nhân thông minh cho người Việt Nam.',
    );
    buffer.writeln(
      'Hãy phân tích chi tiêu của tôi và đưa ra lời khuyên hữu ích.',
    );
    buffer.writeln('Trả lời bằng tiếng Việt, ngắn gọn, dễ hiểu.');
    buffer.writeln();
    buffer.writeln('=== DỮ LIỆU THÁNG NÀY ===');
    buffer.writeln('Thu nhập: ${CurrencyFormatter.formatVND(totalIncome)}');
    buffer.writeln('Chi tiêu: ${CurrencyFormatter.formatVND(totalExpense)}');
    buffer.writeln(
      'Còn dư: ${CurrencyFormatter.formatVND(totalIncome - totalExpense)}',
    );
    buffer.writeln(
      'Tỷ lệ tiết kiệm: ${totalIncome > 0 ? ((totalIncome - totalExpense) / totalIncome * 100).toStringAsFixed(1) : 0}%',
    );
    buffer.writeln();
    buffer.writeln('=== CHI TIÊU THEO DANH MỤC ===');

    final sortedExpenses = expenseByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in sortedExpenses) {
      final name = categoryNames[entry.key] ?? entry.key;
      final percent = totalExpense > 0
          ? (entry.value / totalExpense * 100).toStringAsFixed(1)
          : '0';
      buffer.writeln(
        '- $name: ${CurrencyFormatter.formatVND(entry.value)} ($percent%)',
      );
    }

    buffer.writeln();
    buffer.writeln('=== YÊU CẦU ===');
    buffer.writeln('1. Đánh giá tổng quan tình hình tài chính (1-2 câu)');
    buffer.writeln('2. Chỉ ra 2-3 điểm cần lưu ý hoặc cải thiện');
    buffer.writeln('3. Đưa ra 2-3 gợi ý tiết kiệm cụ thể, thực tế');
    buffer.writeln('4. Một lời động viên ngắn gọn');
    buffer.writeln();
    buffer.writeln('Format: Dùng emoji phù hợp, chia đoạn rõ ràng.');

    return buffer.toString();
  }

  /// Get default insights when AI is not configured
  String _getDefaultInsights(
    double totalIncome,
    double totalExpense,
    Map<String, double> expenseByCategory,
    Map<String, String> categoryNames,
  ) {
    final buffer = StringBuffer();
    final balance = totalIncome - totalExpense;
    final savingsRate = totalIncome > 0 ? (balance / totalIncome * 100) : 0;

    // Overview
    buffer.writeln('📊 **Tổng quan tháng này**\n');

    if (savingsRate >= 30) {
      buffer.writeln(
        '🎉 Tuyệt vời! Bạn đang tiết kiệm ${savingsRate.toStringAsFixed(0)}% thu nhập.',
      );
    } else if (savingsRate >= 10) {
      buffer.writeln(
        '👍 Khá tốt! Bạn tiết kiệm được ${savingsRate.toStringAsFixed(0)}% thu nhập.',
      );
    } else if (savingsRate > 0) {
      buffer.writeln(
        '⚠️ Cần cải thiện! Chỉ tiết kiệm ${savingsRate.toStringAsFixed(0)}% thu nhập.',
      );
    } else {
      buffer.writeln('🚨 Cảnh báo! Chi tiêu vượt thu nhập.');
    }

    buffer.writeln();

    // Top spending
    if (expenseByCategory.isNotEmpty) {
      final sorted = expenseByCategory.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      buffer.writeln('💰 **Chi tiêu nhiều nhất:**');
      for (var i = 0; i < sorted.length && i < 3; i++) {
        final name = categoryNames[sorted[i].key] ?? sorted[i].key;
        buffer.writeln(
          '${i + 1}. $name: ${CurrencyFormatter.formatCompact(sorted[i].value)}',
        );
      }
      buffer.writeln();
    }

    // Tips
    buffer.writeln('💡 **Gợi ý:**');
    if (savingsRate < 20) {
      buffer.writeln('• Cố gắng tiết kiệm ít nhất 20% thu nhập');
    }
    buffer.writeln('• Theo dõi chi tiêu hàng ngày');
    buffer.writeln('• Đặt mục tiêu tiết kiệm cụ thể');

    buffer.writeln(
      '\n---\n*Thêm Gemini API key để nhận tư vấn AI chi tiết hơn!*',
    );

    return buffer.toString();
  }

  /// Chat with AI about finances
  Future<String> chat(
    String message, {
    List<Transaction>? recentTransactions,
    double? monthlyIncome,
    double? monthlyExpense,
  }) async {
    if (!isConfigured) {
      return 'Vui lòng cấu hình Gemini API key trong Settings để sử dụng AI chat.';
    }

    await init();

    final context = StringBuffer();
    context.writeln(
      'Bạn là cố vấn tài chính AI cho app FinTech. Trả lời bằng tiếng Việt, ngắn gọn.',
    );

    if (monthlyIncome != null && monthlyExpense != null) {
      context.writeln(
        'Context: Thu nhập tháng: ${CurrencyFormatter.formatVND(monthlyIncome)}, Chi tiêu: ${CurrencyFormatter.formatVND(monthlyExpense)}',
      );
    }

    context.writeln('\nCâu hỏi của người dùng: $message');

    try {
      final response = await _model!.generateContent([
        Content.text(context.toString()),
      ]);
      return response.text ?? 'Không thể xử lý câu hỏi.';
    } catch (e) {
      return 'Lỗi: $e';
    }
  }
}
