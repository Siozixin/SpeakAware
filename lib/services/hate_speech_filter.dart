import 'dart:math';
import '../models/hate_pattern.dart';
import '../models/filter_result.dart';

class HateSpeechFilter {
  static final List<HatePattern> _patterns = [
    HatePattern(
      pattern: RegExp(r'\b(stupid|dumb|idiot|moron)\b', caseSensitive: false),
      replacement: '🤔',
      suggestion: 'I disagree with this',
      severity: 'medium',
    ),
    HatePattern(
      pattern: RegExp(r'\b(hate|suck|worst|terrible)\b', caseSensitive: false),
      replacement: '💭',
      suggestion: 'I\'m not a fan of this',
      severity: 'low',
    ),
    HatePattern(
      pattern: RegExp(r'\b(kill|die|death)\b', caseSensitive: false),
      replacement: '⚠️',
      suggestion: 'I strongly disagree',
      severity: 'high',
    ),
    HatePattern(
      pattern: RegExp(r'\b(loser|failure|pathetic)\b', caseSensitive: false),
      replacement: '😔',
      suggestion: 'I think we can do better',
      severity: 'medium',
    ),
    // Additional patterns for more comprehensive filtering
    HatePattern(
      pattern: RegExp(r'\b(fuck|shit|damn|hell|ass)\b', caseSensitive: false),
      replacement: '🤐',
      suggestion: 'Let\'s keep it clean',
      severity: 'medium',
    ),
    HatePattern(
      pattern: RegExp(r'\b(shut up|shutup)\b', caseSensitive: false),
      replacement: '🤫',
      suggestion: 'Let\'s listen to each other',
      severity: 'low',
    ),
  ];

  static FilterResult filterMessage(String message) {
    String filteredText = message;
    List<String> suggestions = [];
    bool hasHate = false;
    String severity = 'none';
    
    // Keep track of matched patterns to avoid duplicate suggestions
    Set<String> addedSuggestions = {};

    for (var pattern in _patterns) {
      if (pattern.pattern.hasMatch(filteredText)) {
        hasHate = true;
        
        // Replace ALL occurrences of hate speech with emoji
        filteredText = filteredText.replaceAll(pattern.pattern, pattern.replacement);
        
        // Add suggestion if not already added
        if (!addedSuggestions.contains(pattern.suggestion)) {
          suggestions.add(pattern.suggestion);
          addedSuggestions.add(pattern.suggestion);
        }
        
        // Update severity (high > medium > low > none)
        if (pattern.severity == 'high') {
          severity = 'high';
        } else if (pattern.severity == 'medium' && severity != 'high') {
          severity = 'medium';
        } else if (pattern.severity == 'low' && severity == 'none') {
          severity = 'low';
        }
      }
    }

    // If hate speech was detected, add a general positive suggestion
    if (hasHate && suggestions.isEmpty) {
      suggestions.add(generatePositiveSuggestion(message));
    }

    return FilterResult(
      originalText: message, // Keep original for logging/analysis purposes
      filteredText: filteredText, // This is what gets displayed - hate speech replaced with emojis
      suggestions: suggestions,
      hasHate: hasHate,
      severity: severity,
    );
  }

  static String generatePositiveSuggestion(String message) {
    final positiveAlternatives = [
      'How about trying: "I have a different perspective on this"',
      'Consider saying: "I see things differently"',
      'Maybe try: "I respectfully disagree"',
      'How about: "Let\'s discuss this calmly"',
      'Consider: "I understand your point, but I think differently"',
      'Try: "I\'d like to share another viewpoint"',
      'How about: "Let\'s keep this conversation positive"',
      'Consider: "I think there\'s a better way to say this"',
    ];
    
    return positiveAlternatives[Random().nextInt(positiveAlternatives.length)];
  }

  // Helper method to check if a message contains hate speech without filtering
  static bool containsHateSpeech(String message) {
    for (var pattern in _patterns) {
      if (pattern.pattern.hasMatch(message)) {
        return true;
      }
    }
    return false;
  }

  // Helper method to get severity without filtering
  static String getSeverity(String message) {
    String severity = 'none';
    
    for (var pattern in _patterns) {
      if (pattern.pattern.hasMatch(message)) {
        if (pattern.severity == 'high') {
          severity = 'high';
        } else if (pattern.severity == 'medium' && severity != 'high') {
          severity = 'medium';
        } else if (pattern.severity == 'low' && severity == 'none') {
          severity = 'low';
        }
      }
    }
    
    return severity;
  }

  // Method to add custom patterns dynamically
  static void addCustomPattern(HatePattern pattern) {
    _patterns.add(pattern);
  }

  // Method to get all current patterns (for admin/debugging)
  static List<HatePattern> getPatterns() {
    return List.unmodifiable(_patterns);
  }
}