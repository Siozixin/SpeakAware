// File: lib/services/ai_hate_speech_filter.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/filter_result.dart';
import 'secure_config_service.dart';

class AIHateSpeechFilter {
  static const String _openaiApiUrl =
      'https://api.openai.com/v1/chat/completions';

  // Get API key from secure storage
  static Future<String?> _getApiKey() async {
    return await SecureConfigService.getOpenAIKey();
  }

  /// Analyzes message for hate speech and generates suggestions
  static Future<FilterResult> analyzeMessage(String message) async {
    try {
      // First, check if the message contains hate speech
      final isHateful = await _detectHateSpeech(message);

      if (!isHateful) {
        return FilterResult(
          originalText: message,
          filteredText: message,
          suggestions: [],
          hasHate: false,
          severity: 'none',
        );
      }

      // If hateful, generate polite alternatives
      final suggestions = await _generatePoliteSuggestions(message);
      final severity = await _assessSeverity(message);

      // Create a filtered version (completely replace hate speech with emojis)
      final filteredText = await _createFilteredVersion(message);

      return FilterResult(
        originalText: message,
        filteredText: filteredText,
        suggestions: suggestions,
        hasHate: true,
        severity: severity,
      );
    } catch (e) {
      print('AI Analysis Error: $e');
      // Fallback to basic filtering if AI fails
      return _fallbackFilter(message);
    }
  }

  /// Detects if message contains hate speech using AI
  static Future<bool> _detectHateSpeech(String message) async {
    final prompt = '''
Analyze the following message for hate speech, cyberbullying, or inappropriate content that would be harmful for teenagers:

Message: "$message"

Respond with only "YES" if it contains hate speech/inappropriate content, or "NO" if it's acceptable.
Consider context, intent, and severity. Be appropriate for teen chat environments.
''';

    final response = await _callOpenAI(prompt, maxTokens: 10);
    return response.trim().toUpperCase().contains('YES');
  }

  /// Generates polite alternative suggestions
  static Future<List<String>> _generatePoliteSuggestions(String message) async {
    final prompt = '''
The user wrote: "$message"

This message contains inappropriate language for a teen chat app. Generate 3 polite, kind alternatives that express the same sentiment but in a respectful way. Make them natural and age-appropriate for teenagers.

Format as a simple list:
1. [suggestion 1]
2. [suggestion 2] 
3. [suggestion 3]
''';

    final response = await _callOpenAI(prompt, maxTokens: 150);

    // Parse the numbered list
    final suggestions = <String>[];
    final lines = response.split('\n');

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith(RegExp(r'[0-9]+\.'))) {
        final suggestion = trimmed.replaceFirst(RegExp(r'[0-9]+\.\s*'), '');
        if (suggestion.isNotEmpty) {
          suggestions.add(suggestion);
        }
      }
    }

    return suggestions.isNotEmpty
        ? suggestions
        : ['How about saying that more kindly?'];
  }

  /// Assesses the severity of hate speech
  static Future<String> _assessSeverity(String message) async {
    final prompt = '''
Rate the severity of inappropriate content in this message: "$message"

Respond with only one word:
- "low" for mild negativity or rudeness
- "medium" for offensive language or personal attacks  
- "high" for severe hate speech, threats, or extreme content
''';

    final response = await _callOpenAI(prompt, maxTokens: 10);
    final severity = response.trim().toLowerCase();

    if (['low', 'medium', 'high'].contains(severity)) {
      return severity;
    }
    return 'medium'; // default
  }

  /// Creates a filtered version of the message - COMPLETELY replaces hate speech
  static Future<String> _createFilteredVersion(String message) async {
    final prompt = '''
Replace ALL inappropriate words and phrases in this message with appropriate emojis, while keeping the message structure readable. Do NOT show any of the original inappropriate words.

Original: "$message"

Rules:
- Replace hate speech/insults with 🤔
- Replace profanity with 🤐  
- Replace threats/violence with ⚠️
- Replace negative emotions with 😔
- Replace mild negativity with 💭
- Keep appropriate words unchanged

Return only the fully filtered version with emojis replacing ALL inappropriate content.
''';

    final response = await _callOpenAI(prompt, maxTokens: 100);
    final filtered = response.trim();
    
    // Ensure we have a valid response, otherwise use fallback
    if (filtered.isNotEmpty && !filtered.toLowerCase().contains('original')) {
      return filtered;
    } else {
      return _fallbackFilterText(message);
    }
  }

  /// Makes API call to OpenAI
  static Future<String> _callOpenAI(String prompt,
      {int maxTokens = 150}) async {
    final apiKey = await _getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('OpenAI API key not configured');
    }

    final headers = {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    };

    final body = json.encode({
      'model': 'gpt-3.5-turbo', // or 'gpt-4' for better results
      'messages': [
        {
          'role': 'system',
          'content':
              'You are a helpful assistant that promotes kind and respectful communication among teenagers. You completely replace inappropriate content with emojis.'
        },
        {'role': 'user', 'content': prompt}
      ],
      'max_tokens': maxTokens,
      'temperature': 0.3, // Lower temperature for consistent results
    });

    final response = await http.post(
      Uri.parse(_openaiApiUrl),
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['choices'][0]['message']['content'] ?? '';
    } else {
      throw Exception('OpenAI API Error: ${response.statusCode} - ${response.body}');
    }
  }

  /// Fallback filter if AI is unavailable - FIXED VERSION
  static FilterResult _fallbackFilter(String message) {
    // Define hate speech patterns with their emoji replacements
    final Map<String, String> hatePatterns = {
      r'\b(stupid|dumb|idiot|moron|retard|hate|suck|worst|terrible|awful|kill|die|death|murder|fuck|shit|damn|hell|ass|bitch|loser|failure|pathetic|worthless|shut up|shutup)\b': '😊',
    };

    String filteredText = message;
    bool hasHate = false;

    // Apply all patterns to completely replace hate speech
    for (final entry in hatePatterns.entries) {
      final pattern = RegExp(entry.key, caseSensitive: false);
      if (pattern.hasMatch(filteredText)) {
        hasHate = true;
        filteredText = filteredText.replaceAll(pattern, entry.value);
      }
    }

    if (hasHate) {
      return FilterResult(
        originalText: message,
        filteredText: filteredText, // Hate speech completely replaced with emojis
        suggestions: [generatePositiveSuggestion()],
        hasHate: true,
        severity: _determineSeverity(message),
      );
    }

    return FilterResult(
      originalText: message,
      filteredText: message,
      suggestions: [],
      hasHate: false,
      severity: 'none',
    );
  }

  /// Helper method for fallback text filtering
  static String _fallbackFilterText(String message) {
    final Map<String, String> hatePatterns = {
      r'\b(stupid|dumb|idiot|moron|retard)\b': '🤔',
      r'\b(hate|suck|worst|terrible|awful)\b': '💭',
      r'\b(kill|die|death|murder)\b': '⚠️',
      r'\b(fuck|shit|damn|hell|ass|bitch)\b': '🤐',
      r'\b(loser|failure|pathetic|worthless)\b': '😔',
      r'\b(shut up|shutup)\b': '🤫',
    };

    String filteredText = message;
    for (final entry in hatePatterns.entries) {
      final pattern = RegExp(entry.key, caseSensitive: false);
      filteredText = filteredText.replaceAll(pattern, entry.value);
    }

    return filteredText.isNotEmpty ? filteredText : '💭 [filtered message]';
  }

  /// Determine severity for fallback
  static String _determineSeverity(String message) {
    final lowerMessage = message.toLowerCase();
    
    if (RegExp(r'\b(kill|die|death|murder|fuck|bitch)\b').hasMatch(lowerMessage)) {
      return 'high';
    } else if (RegExp(r'\b(stupid|dumb|idiot|hate|shit|damn)\b').hasMatch(lowerMessage)) {
      return 'medium';
    } else if (RegExp(r'\b(suck|worst|terrible|shut up)\b').hasMatch(lowerMessage)) {
      return 'low';
    }
    
    return 'none';
  }

  /// Generate a random positive suggestion (fallback)
  static String generatePositiveSuggestion() {
    final suggestions = [
      'How about expressing that more kindly?',
      'Consider sharing your thoughts respectfully',
      'Maybe try a more positive approach?',
      'Let\'s keep the conversation friendly!',
      'Could you rephrase that more nicely?',
      'Try expressing your feelings in a kinder way',
      'How about we discuss this more respectfully?',
      'Let\'s find a better way to say that',
    ];

    return suggestions[
        (DateTime.now().millisecondsSinceEpoch % suggestions.length)];
  }
}

// Alternative service for Google Cloud Natural Language - FIXED VERSION
class GoogleAIHateSpeechFilter {
  static const String _googleApiKey = 'YOUR_GOOGLE_API_KEY';
  static const String _apiUrl =
      'https://language.googleapis.com/v1/documents:analyzeSentiment';

  static Future<FilterResult> analyzeWithGoogle(String message) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl?key=$_googleApiKey'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'document': {
            'type': 'PLAIN_TEXT',
            'content': message,
          },
          'encodingType': 'UTF8',
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final sentiment = data['documentSentiment'];
        final score = sentiment['score'] as double;
        final magnitude = sentiment['magnitude'] as double;

        // Determine if message is negative/hateful based on sentiment
        final isHateful = score < -0.5 && magnitude > 0.5;

        if (isHateful) {
          return FilterResult(
            originalText: message,
            filteredText: _simpleFilter(message), // Completely filtered version
            suggestions: ['Try expressing this more positively'],
            hasHate: true,
            severity: magnitude > 1.0 ? 'high' : 'medium',
          );
        }
      }

      return FilterResult(
        originalText: message,
        filteredText: message,
        suggestions: [],
        hasHate: false,
        severity: 'none',
      );
    } catch (e) {
      print('Google AI Error: $e');
      return AIHateSpeechFilter._fallbackFilter(message);
    }
  }

  /// FIXED - Complete filtering with emojis
  static String _simpleFilter(String message) {
    final Map<String, String> patterns = {
      r'\b(hate|stupid|dumb|kill|die)\b': '💭',
      r'\b(fuck|shit|damn|hell)\b': '🤐',
      r'\b(idiot|moron|loser)\b': '🤔',
    };

    String filtered = message;
    for (final entry in patterns.entries) {
      filtered = filtered.replaceAll(
          RegExp(entry.key, caseSensitive: false), entry.value);
    }

    return filtered;
  }
}
