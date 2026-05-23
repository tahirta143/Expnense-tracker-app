import 'package:genkit/genkit.dart';
import 'package:genkit_google_genai/genkit_google_genai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/expense.dart';

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  late Genkit _genkit;
  bool _initialized = false;
  
  // Simple chat memory
  final List<Map<String, String>> _chatHistory = [];

  Future<void> init() async {
    if (_initialized) return;

    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      print('AI Service Error: GEMINI_API_KEY not found in .env file');
      return;
    }
    
    final cleanKey = apiKey.trim();

    _genkit = Genkit(
      plugins: [
        googleAI(apiKey: cleanKey),
      ],
    );
    _initialized = true;
    print('AI Service: Initialized');
  }

  Future<String> getFinancialInsights(List<Expense> expenses) async {
    if (!_initialized) {
      await init();
      if (!_initialized) return 'AI not initialized. Please add GEMINI_API_KEY to .env file.';
    }

    try {
      final expenseSummary = expenses.map((e) => 
        '${e.date.toIso8601String().split('T')[0]}: ${e.isIncome ? 'Income' : 'Expense'} of Rs ${e.amount} in ${e.category} (${e.title})'
      ).join('\n');

      final prompt = '''
      Analyze these transactions:
      $expenseSummary
      
      Provide 3 actionable tips for saving money.
      Format: Simple bullet points.
      Tone: Concise.
      ''';

      final response = await _genkit.generate(
        model: googleAI.gemini('gemini-2.5-flash'),
        prompt: prompt,
      );

      return response.text ?? 'Could not generate insights.';
    } catch (e) {
      print('AI Service Error Log: $e');
      return _handleError(e);
    }
  }

  Future<String> askAI(List<Expense> expenses, String question) async {
    if (!_initialized) {
      await init();
      if (!_initialized) return 'AI not initialized.';
    }

    try {
      final now = DateTime.now();
      final totalIncome = expenses.where((e) => e.isIncome).fold(0.0, (sum, e) => sum + e.amount);
      final totalExpense = expenses.where((e) => !e.isIncome).fold(0.0, (sum, e) => sum + e.amount);
      
      final expenseSummary = expenses.map((e) => 
        '${e.date.toIso8601String().split('T')[0]}: ${e.isIncome ? 'Income' : 'Expense'} of Rs ${e.amount} in ${e.category} (${e.title})'
      ).join('\n');

      // Add user message to history
      _chatHistory.add({'role': 'user', 'content': question});

      final historyText = _chatHistory.map((m) => '${m['role']}: ${m['content']}').join('\n');

      final prompt = '''
      You are a professional financial assistant. 
      Today's date is ${now.toIso8601String().split('T')[0]}.
      
      The user is tracking their expenses in an app.
      SUMMARY DATA:
      - Total Income: Rs $totalIncome
      - Total Expenses: Rs $totalExpense
      - Current Balance: Rs ${totalIncome - totalExpense}
      
      TRANSACTION DATA:
      $expenseSummary
      
      CHAT HISTORY:
      $historyText
      
      INSTRUCTIONS:
      Please answer the question accurately based on the provided data. 
      If asked for reports (daily, monthly, yearly), summarize the data from the transactions provided.
      You have access to all transaction history, so you can provide insights on spending trends over time.
      Be concise, helpful, and professional.
      ''';

      final response = await _genkit.generate(
        model: googleAI.gemini('gemini-2.5-flash'),
        prompt: prompt,
      );

      final answer = response.text ?? 'I could not find an answer to that.';
      
      // Add AI response to history
      _chatHistory.add({'role': 'assistant', 'content': answer});
      
      // Limit history to last 10 exchanges
      if (_chatHistory.length > 20) {
        _chatHistory.removeRange(0, 2);
      }

      return answer;
    } catch (e) {
      print('AI Service Error Log: $e');
      return _handleError(e);
    }
  }

  void clearHistory() {
    _chatHistory.clear();
  }

  String _handleError(Object e) {
    String errorMsg = e.toString();
    if (errorMsg.contains('NOT_FOUND')) {
      return 'AI Error: Model not found. Check API configuration.';
    } else if (errorMsg.contains('API_KEY_INVALID')) {
      return 'AI Error: Invalid API Key.';
    } else if (errorMsg.contains('PERMISSION_DENIED')) {
      return 'AI Error: Access denied.';
    }
    return 'AI Error: Something went wrong. Please try again.';
  }
}
