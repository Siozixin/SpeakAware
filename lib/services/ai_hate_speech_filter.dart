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
          category: 'none',
          shouldCensor: false,
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
        category: 'general', // Default category for OpenAI fallback
        shouldCensor: false, // Always show suggestions instead of censoring
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

Analyze the following text and provide a JSON response.

Text: "$message"

IMPORTANT: The "reason" field should contain ONLY a brief, simple explanation in plain English. Do NOT include JSON syntax, field names, or technical details in the reason field. Examples of good reasons: "Contains racial slurs", "Uses offensive language about women", "Threatens violence", "Contains profanity".
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
    // Define hate speech patterns with their respectful transformations
    final Map<String, String> hateTransformations = {
      r'\b(stupid|dumb|idiot|moron|retard)\b': 'I think we see this differently',
      r'\b(hate|suck|worst|terrible|awful)\b': 'I\'m not a fan of this',
      r'\b(kill|die|death|murder)\b': 'I strongly disagree with this approach',
      r'\b(fuck|shit|damn|hell|ass|bitch)\b': 'Let\'s use more respectful language',
      r'\b(loser|failure|pathetic|worthless)\b': 'I think we can do better',
      r'\b(shut up|shutup)\b': 'Let\'s pause and listen',
    };

    // Define meaningless emojis for short hate speech
    final Map<String, String> meaninglessEmojis = {
      r'\b(stupid|dumb|idiot|moron|retard)\b': '🌟',
      r'\b(hate|suck|worst|terrible|awful)\b': '✨',
      r'\b(kill|die|death|murder)\b': '💫',
      r'\b(fuck|shit|damn|hell|ass|bitch)\b': '⭐',
      r'\b(loser|failure|pathetic|worthless)\b': '🌙',
      r'\b(shut up|shutup)\b': '☀️',
    };

    String transformedText = message;
    bool hasHate = false;
    String severity = 'none';
    String category = 'none';
    bool shouldCensor = false;

    // Check if this should be censored (short hate speech - 3 words or less)
    final wordCount = message.trim().split(' ').where((word) => word.isNotEmpty).length;
    shouldCensor = wordCount <= 3;

    // Apply transformations based on whether to censor or suggest
    if (shouldCensor) {
      // Use meaningless emojis for short hate speech
      for (final entry in meaninglessEmojis.entries) {
        final pattern = RegExp(entry.key, caseSensitive: false);
        if (pattern.hasMatch(transformedText)) {
          hasHate = true;
          transformedText = '🌟 censored';
          
          // Update severity and category
          if (entry.key.contains(r'\b(kill|die|death|murder|fuck|bitch)\b')) {
            severity = 'high';
            category = entry.key.contains('bitch') ? 'misogynist' : 'threatening';
          } else if (entry.key.contains(r'\b(stupid|dumb|idiot|shit|damn)\b')) {
            severity = 'medium';
            category = 'general';
          } else if (severity == 'none') {
            severity = 'low';
            category = 'general';
          }
        }
      }
    } else {
      // Use respectful transformations for long hate speech
      for (final entry in hateTransformations.entries) {
        final pattern = RegExp(entry.key, caseSensitive: false);
        if (pattern.hasMatch(transformedText)) {
          hasHate = true;
          transformedText = transformedText.replaceAll(pattern, entry.value);
          
          // Update severity and category
          if (entry.key.contains(r'\b(kill|die|death|murder|fuck|bitch)\b')) {
            severity = 'high';
            category = entry.key.contains('bitch') ? 'misogynist' : 'threatening';
          } else if (entry.key.contains(r'\b(stupid|dumb|idiot|shit|damn)\b')) {
            severity = 'medium';
            category = 'general';
          } else if (severity == 'none') {
            severity = 'low';
            category = 'general';
          }
        }
      }
    }

    // Generate suggestions for long hate speech
    List<String> suggestions = [];
    if (!shouldCensor) {
      suggestions = [
        _fallbackFilterText(message),
        _fallbackFilterText(message),
        _fallbackFilterText(message),
      ];
    }

    if (hasHate) {
      return FilterResult(
        originalText: message,
        filteredText: transformedText,
        suggestions: shouldCensor ? [] : suggestions,
        hasHate: true,
        severity: severity,
        category: category,
        shouldCensor: shouldCensor,
      );
    }

    return FilterResult(
      originalText: message,
      filteredText: message,
      suggestions: [],
      hasHate: false,
      severity: 'none',
      category: 'none',
      shouldCensor: false,
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
  static const String _googleApiKey = 'YOUR_API_KEY';
  static const String _apiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';
  // static const String _apiUrl =
  //     'https://language.googleapis.com/v1/documents:analyzeSentiment';

  static Future<FilterResult> analyzeWithGoogle(String message) async {
    try {
      // Determine if this is short hate speech (should be censored) or long text (should get suggestions)
      final wordCount = message.trim().split(' ').where((word) => word.isNotEmpty).length;
      final isShortHateSpeech = wordCount <= 3 && _containsShortHateWords(message);
      
      // Compose a single prompt for Gemini
      final prompt = '''
Analyze the following message for hate speech, cyberbullying, or inappropriate content that would be harmful for teenagers.

Message: "$message"

If the message contains any insults, negative language, or words like "stupid", "dumb", "idiot", "hate", "kill", "shut up", "loser", "retard", "suck", "worst", "awful", "bitch", "moron", "pathetic", "worthless", or similar, set "hasHate" to "YES". Flag hate speech even if the words are misspelled, abbreviated, or used in slang. Consider context, intent, and severity.

Categorize the hate speech into one of these categories:
- "racist" - racial slurs, ethnic discrimination
- "misogynist" - sexist language, gender discrimination  
- "homophobic" - anti-LGBTQ+ language
- "ableist" - discrimination against disabilities
- "religious" - religious discrimination
- "general" - general insults, cyberbullying
- "threatening" - threats of violence
- "profanity" - excessive profanity

Severity should be:
- "low" for mild negativity, rudeness, or sarcasm
- "medium" for offensive language, personal attacks, or repeated negativity
- "high" for severe hate speech, threats, slurs, or extreme content

CRITICAL: The message has ${wordCount} words. 
- If ${wordCount} <= 3 (short message): Set "shouldCensor" to true and "censoredText" to "🌟 censored". Do NOT generate suggestions.
- If ${wordCount} > 3 (long message): Set "shouldCensor" to false and generate 3 precise alternatives with different tones.

For long messages only (>3 words), generate 3 precise alternatives that change the speaking technique to non-harmful while keeping the EXACT same context and meaning. Each suggestion should have a different tone:
1. First suggestion: Friendly and approachable tone
2. Second suggestion: Supportive and understanding tone  
3. Third suggestion: Light and humorous tone

IMPORTANT: For long messages with hate speech (>3 words), you MUST generate exactly 3 suggestions. Do not skip suggestions for long messages.

Examples of PRECISE REPLACEMENTS (same context, different speaking technique):
- "Stop being so busy body" → "Could you give me some space?"
- "You are so stupid" → "I think we see this differently"
- "I hate you" → "I'm frustrated with you"
- "Shut up loser" → "Let's pause and listen"
- "You're a dum idiot" → "I think we can talk better"
- "Go kill yourself" → "I hope you're okay"
- "You're the worst" → "This isn't working well"
- "What a bitch" → "That's not very kind"
- "You're pathetic" → "I think we can do better"
- "Stop being annoying" → "Could you be quieter?"
- "You're useless" → "I think we need different help"
- "Get lost" → "Could you step back?"

The replacements should:
1. Keep the EXACT same context and meaning
2. Change only the harmful speaking technique to a respectful one
3. Use the same sentence structure when possible
4. Maintain the same intent but with kinder words

Respond in this JSON format:
{
  "hasHate": "YES or NO",
  "suggestions": ["precise replacement 1", "precise replacement 2", "precise replacement 3"],
  "severity": "low, medium, or high",
  "category": "racist, misogynist, homophobic, ableist, religious, general, threatening, profanity, or none",
  "shouldCensor": true or false,
  "censoredText": "🌟 censored (only if shouldCensor is true)",
  "reason": "A brief, simple explanation in plain English of why this text is inappropriate (e.g., 'Contains racial slurs' or 'Uses offensive language about women'). Keep it short and clear."
}
If there is no hate speech, suggestions should be an empty array, severity should be "none", category should be "none", and shouldCensor should be false.
If it's short hate speech (≤3 words), shouldCensor should be true, censoredText should be "🌟 censored", and suggestions should be an empty array.
If it's long hate speech (>3 words), shouldCensor should be false, censoredText should be empty, and suggestions should have exactly 3 alternatives.

IMPORTANT: The "reason" field should contain ONLY a brief, simple explanation in plain English. Do NOT include JSON syntax, field names, or technical details in the reason field. Examples of good reasons: "Contains racial slurs", "Uses offensive language about women", "Threatens violence", "Contains profanity".
''';

      final response = await http.post(
        Uri.parse('$_apiUrl?key=$_googleApiKey'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ]
        }),
      );

      print('Gemini API status: ${response.statusCode}');
      print('Gemini API body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final text = candidates[0]['content']['parts'][0]['text'] as String;
          print('Gemini raw response: ${text}');
          // Try to extract the JSON from the response
          final jsonStart = text.indexOf('{');
          final jsonEnd = text.lastIndexOf('}');
          if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
            final jsonString = text.substring(jsonStart, jsonEnd + 1);
            print('Extracted JSON string: ${jsonString}');
            
            try {
              final result = json.decode(jsonString);
              
              // Check for presence of hasHate to determine response format
              if (result.containsKey('hasHate')) {
                final hasHate = result['hasHate']?.toString().toLowerCase() == 'yes';
                final suggestions = (result['suggestions'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
                final category = (result['category'] ?? 'general').toString();
                final severity = (result['severity'] ?? 'low').toString();
                final shouldCensor = (result['shouldCensor'] ?? false) as bool;
                final censoredText = (result['censoredText'] ?? '').toString();
                
                // Extract reason field - handle cases where it might contain JSON
                String reason = (result['reason'] ?? '').toString();
                
                // If reason contains JSON, try to extract just the reason value
                if (reason.contains('{') && reason.contains('}')) {
                  try {
                    final reasonJson = json.decode(reason);
                    reason = (reasonJson['reason'] ?? '').toString();
                  } catch (e) {
                    // If parsing fails, clean the reason field
                    reason = _cleanReasonField(reason);
                  }
                } else {
                  // Clean up any remaining artifacts
                  reason = _cleanReasonField(reason);
                }
                
                print('AI Response - hasHate: $hasHate, shouldCensor: $shouldCensor, suggestions: $suggestions, censoredText: $censoredText, reason: $reason');
                
                return FilterResult(
                  originalText: message,
                  hasHate: hasHate,
                  suggestions: suggestions,
                  filteredText: censoredText,
                  severity: severity,
                  category: category,
                  shouldCensor: shouldCensor,
                  reason: reason,
                );
              }
            } catch (e) {
              print('Error parsing JSON response: $e');
            }
          }
        }
      }
      // If anything fails, fallback
      return FilterResult(
        originalText: message,
        filteredText: message,
        suggestions: [],
        hasHate: false,
        severity: 'none',
        category: 'none',
        shouldCensor: false,
      );
    } catch (e) {
      print('Gemini AI Error: ${e}');
      return AIHateSpeechFilter._fallbackFilter(message);
    }
  }

  /// Helper method to detect short hate speech patterns
  static bool _containsShortHateWords(String message) {
    final shortHatePatterns = [
      r'\b(stupid|dumb|idiot|moron|retard)\b',
      r'\b(hate|suck|worst|terrible|awful)\b',
      r'\b(kill|die|death|murder)\b',
      r'\b(fuck|shit|damn|hell|ass|bitch)\b',
      r'\b(loser|failure|pathetic|worthless)\b',
      r'\b(shut up|shutup)\b',
    ];
    
    for (final pattern in shortHatePatterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(message)) {
        return true;
      }
    }
    return false;
  }

  /// FIXED - Transform hateful messages into respectful versions
  static String _simpleFilter(String message) {
    final Map<String, String> transformations = {
      r'\b(hate|stupid|dumb|kill|die)\b': 'I think we can find a better way to express this',
      r'\b(fuck|shit|damn|hell)\b': 'Let\'s use more respectful language',
      r'\b(idiot|moron|loser)\b': 'I think we see this differently',
    };

    // For short messages (3 words or less), use meaningless emojis
    final wordCount = message.trim().split(' ').where((word) => word.isNotEmpty).length;
    if (wordCount <= 3) {
      return '🌟 censored';
    }

    // For long messages, use respectful transformations
    String transformed = message;
    for (final entry in transformations.entries) {
      transformed = transformed.replaceAll(
          RegExp(entry.key, caseSensitive: false), entry.value);
    }

    return transformed;
  }

  static Future<String> generateChatReply({required String userName, required String userMessage}) async {
    final prompt = '''
You are $userName in a group chat with teenagers. Reply to the following message in a friendly, age-appropriate, and context-aware way. Keep it short and natural.
If the message is in another language, reply in that language as much as possible, as a real friend would. Do not translate or explain the message unless specifically asked. Just reply naturally as a friend would.

Message from user: "$userMessage"
''';
    final response = await http.post(
      Uri.parse('$_apiUrl?key=$_googleApiKey'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ]
      }),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final candidates = data['candidates'] as List?;
      if (candidates != null && candidates.isNotEmpty) {
        final text = candidates[0]['content']['parts'][0]['text'] as String;
        // Strip quotes from the response
        return text.trim().replaceAll(RegExp(r'^"|"$'), '');
      }
    }
    return "That's interesting!";
  }

  static Future<String> generatePoliteAlternative(String message, {String? tone}) async {
    String toneInstruction = '';
    if (tone != null) {
      switch (tone.toLowerCase()) {
        case 'friendly':
          toneInstruction = 'Use a friendly and approachable tone.';
          break;
        case 'supportive':
          toneInstruction = 'Use a supportive and understanding tone.';
          break;
        case 'humorous':
          toneInstruction = 'Use a light and humorous tone.';
          break;
        default:
          toneInstruction = 'Use a different tone than previous suggestions.';
      }
    } else {
      toneInstruction = 'Use a different tone than previous suggestions.';
    }

    final prompt = '''
The following message contains hate speech or inappropriate language:
"$message"

Generate a single, precise alternative that changes the speaking technique to non-harmful while keeping the EXACT same context and meaning. This should be a replacement, not a response to the hate speech.

Examples of PRECISE REPLACEMENTS (same context, different speaking technique):
- "Stop being so busy body" → "Could you give me some space?"
- "You are so stupid" → "I think we see this differently"
- "I hate you" → "I'm frustrated with you"
- "Shut up loser" → "Let's pause and listen"
- "You're a dum idiot" → "I think we can talk better"
- "Go kill yourself" → "I hope you're okay"
- "You're the worst" → "This isn't working well"
- "What a bitch" → "That's not very kind"
- "You're pathetic" → "I think we can do better"
- "Stop being annoying" → "Could you be quieter?"
- "You're useless" → "I think we need different help"
- "Get lost" → "Could you step back?"

The replacement should:
1. Keep the EXACT same context and meaning
2. Change only the harmful speaking technique to a respectful one
3. Use the same sentence structure when possible
4. Maintain the same intent but with kinder words
5. Be a direct replacement, not a response

TONE INSTRUCTION: $toneInstruction

Only return the replacement message, nothing else.
''';
    final response = await http.post(
      Uri.parse('$_apiUrl?key=$_googleApiKey'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ]
      }),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final candidates = data['candidates'] as List?;
      if (candidates != null && candidates.isNotEmpty) {
        final text = candidates[0]['content']['parts'][0]['text'] as String;
        return text.trim();
      }
    }
    return "Let's try to express that more respectfully.";
  }

  /// Helper method to clean the reason field by removing JSON artifacts
  static String _cleanReasonField(String reason) {
    if (reason.isEmpty) return '';
    
    print('Raw reason before cleaning: "$reason"');
    
    // Remove common JSON artifacts and technical details
    String cleaned = reason;
    
    // Handle case where AI returns entire JSON wrapped in markdown code blocks
    if (cleaned.contains('```json')) {
      // Extract content between ```json and ```
      final codeBlockMatch = RegExp(r'```json\s*\n(.*?)\n\s*```', dotAll: true).firstMatch(cleaned);
      if (codeBlockMatch != null) {
        cleaned = codeBlockMatch.group(1) ?? '';
      }
    }
    
    // Remove the entire JSON structure if it's wrapped in it
    if (cleaned.contains('{') && cleaned.contains('}')) {
      // Try to extract just the reason value from JSON
      final reasonMatch = RegExp(r'"reason"\s*:\s*"([^"]*)"').firstMatch(cleaned);
      if (reasonMatch != null) {
        cleaned = reasonMatch.group(1) ?? '';
      } else {
        // If no reason field found, remove everything between braces
        cleaned = cleaned.replaceAll(RegExp(r'\{[^}]*\}'), '');
      }
    }
    
    // Remove any remaining JSON field names and values
    cleaned = cleaned.replaceAll(RegExp(r'"hasHate"\s*:\s*"yes"'), '');
    cleaned = cleaned.replaceAll(RegExp(r'"hasHate"\s*:\s*"no"'), '');
    cleaned = cleaned.replaceAll(RegExp(r'"suggestions"\s*:\s*\[.*?\]'), '');
    cleaned = cleaned.replaceAll(RegExp(r'"severity"\s*:\s*"[^"]*"'), '');
    cleaned = cleaned.replaceAll(RegExp(r'"category"\s*:\s*"[^"]*"'), '');
    cleaned = cleaned.replaceAll(RegExp(r'"shouldCensor"\s*:\s*(true|false)'), '');
    cleaned = cleaned.replaceAll(RegExp(r'"censoredText"\s*:\s*"[^"]*"'), '');
    
    // Remove any remaining JSON syntax
    cleaned = cleaned.replaceAll(RegExp(r'[{}"]'), '');
    cleaned = cleaned.replaceAll(RegExp(r',\s*$'), '');
    cleaned = cleaned.replaceAll(RegExp(r'^\s*,\s*'), '');
    
    // Clean up extra whitespace and punctuation
    cleaned = cleaned.trim();
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');
    
    // If the cleaned result is empty or just contains technical terms, provide a fallback
    if (cleaned.isEmpty || 
        cleaned.toLowerCase().contains('json') || 
        cleaned.toLowerCase().contains('hasHate') ||
        cleaned.toLowerCase().contains('suggestions') ||
        cleaned.toLowerCase().contains('severity') ||
        cleaned.toLowerCase().contains('category')) {
      return 'Contains inappropriate content';
    }
    
    print('Cleaned reason: "$cleaned"');
    return cleaned;
  }

  static Future<String> generateCounselorResponse(String userMessage) async {
    final prompt = '''
You are an empathetic and supportive AI counselor for teenagers. 
Your role is to listen, validate feelings, and offer gentle guidance. 
Do not give medical advice. Keep responses short, kind, and encouraging.

User's message: "$userMessage"

Example Responses:
- "It sounds like that was a really difficult experience. It's okay to feel hurt/angry/sad."
- "Thank you for sharing that with me. It takes courage to open up."
- "I'm here to listen. What's on your mind?"
- "Remember to be kind to yourself. You deserve to feel safe and respected."

Generate a single, supportive response to the user's message.
''';
    final response = await http.post(
      Uri.parse('$_apiUrl?key=$_googleApiKey'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ]
      }),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final candidates = data['candidates'] as List?;
      if (candidates != null && candidates.isNotEmpty) {
        final text = candidates[0]['content']['parts'][0]['text'] as String;
        return text.trim().replaceAll(RegExp(r'^"|"$'), '');
      }
    }
    return "I'm here for you. Tell me more about what's going on.";
  }
}
