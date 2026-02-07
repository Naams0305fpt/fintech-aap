import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/ai_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// AI Insights Screen
class AIInsightsScreen extends StatefulWidget {
  const AIInsightsScreen({super.key});

  @override
  State<AIInsightsScreen> createState() => _AIInsightsScreenState();
}

class _AIInsightsScreenState extends State<AIInsightsScreen> {
  final _chatController = TextEditingController();
  final _scrollController = ScrollController();

  String _insights = '';
  bool _loadingInsights = true;
  final List<_ChatMessage> _chatMessages = [];
  bool _sendingMessage = false;

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  @override
  void dispose() {
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInsights() async {
    setState(() => _loadingInsights = true);

    final provider = context.read<AppProvider>();
    final aiService = AIService.instance;

    // Build category names map
    final categoryNames = <String, String>{};
    for (final cat in provider.categories) {
      categoryNames[cat.id] = cat.name;
    }

    final insights = await aiService.analyzeSpending(
      transactions: provider.monthlyTransactions,
      totalIncome: provider.monthlyIncome,
      totalExpense: provider.monthlyExpense,
      expenseByCategory: provider.expenseByCategory,
      categoryNames: categoryNames,
    );

    if (mounted) {
      setState(() {
        _insights = insights;
        _loadingInsights = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty || _sendingMessage) return;

    setState(() {
      _chatMessages.add(_ChatMessage(text: text, isUser: true));
      _sendingMessage = true;
    });
    _chatController.clear();

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    final provider = context.read<AppProvider>();
    final response = await AIService.instance.chat(
      text,
      monthlyIncome: provider.monthlyIncome,
      monthlyExpense: provider.monthlyExpense,
    );

    if (mounted) {
      setState(() {
        _chatMessages.add(_ChatMessage(text: response, isUser: false));
        _sendingMessage = false;
      });

      // Scroll to bottom after response
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Text('🤖', style: TextStyle(fontSize: 24)),
            SizedBox(width: 8),
            Text('AI Tư vấn'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInsights,
            tooltip: 'Phân tích lại',
          ),
        ],
      ),
      body: Column(
        children: [
          // Insights section
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Monthly summary card
                  Consumer<AppProvider>(
                    builder: (context, provider, _) =>
                        _buildSummaryCard(provider),
                  ),
                  const SizedBox(height: 16),

                  // AI Insights
                  _buildInsightsCard(),
                  const SizedBox(height: 16),

                  // Chat messages
                  if (_chatMessages.isNotEmpty) ...[
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      '💬 Hỏi đáp',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._chatMessages.map(_buildChatBubble),
                    if (_sendingMessage)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'AI đang suy nghĩ...',
                              style: TextStyle(color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                  ],
                  const SizedBox(height: 80), // Space for input
                ],
              ),
            ),
          ),

          // Chat input
          _buildChatInput(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(AppProvider provider) {
    final balance = provider.monthlyBalance;
    final isPositive = balance >= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withAlpha(51),
            AppTheme.primary.withAlpha(26),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormatter.formatMonthYear(provider.selectedMonth),
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Thu nhập', style: TextStyle(fontSize: 12)),
                    Text(
                      CurrencyFormatter.formatCompact(provider.monthlyIncome),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.success,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Chi tiêu', style: TextStyle(fontSize: 12)),
                    Text(
                      CurrencyFormatter.formatCompact(provider.monthlyExpense),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.danger,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Còn dư', style: TextStyle(fontSize: 12)),
                    Text(
                      CurrencyFormatter.formatCompact(balance.abs()),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isPositive ? AppTheme.success : AppTheme.danger,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('✨', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Phân tích AI',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              if (!AIService.instance.isConfigured)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withAlpha(51),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Demo',
                    style: TextStyle(fontSize: 11, color: AppTheme.warning),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loadingInsights)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else
            SelectableText(_insights, style: const TextStyle(height: 1.6)),
        ],
      ),
    );
  }

  Widget _buildChatBubble(_ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha(51),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(child: Text('🤖')),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: message.isUser
                    ? AppTheme.primary
                    : AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: SelectableText(
                message.text,
                style: TextStyle(
                  color: message.isUser ? Colors.white : null,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (message.isUser) const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.surfaceLight)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _chatController,
                decoration: InputDecoration(
                  hintText: 'Hỏi AI về tài chính...',
                  hintStyle: TextStyle(color: AppTheme.textMuted),
                  filled: true,
                  fillColor: AppTheme.surfaceLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;

  _ChatMessage({required this.text, required this.isUser});
}
