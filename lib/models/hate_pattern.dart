class HatePattern {
  final RegExp pattern;
  final String replacement;
  final String suggestion;
  final String severity;
  final String category;

  HatePattern({
    required this.pattern,
    required this.replacement,
    required this.suggestion,
    required this.severity,
    required this.category,
  });
}

class HateSpeechIncident {
  final String originalText;
  final String category;
  final String severity;
  final DateTime timestamp;
  final String? transformedText;
  final List<String> suggestions;
  final String? reason;

  HateSpeechIncident({
    required this.originalText,
    required this.category,
    required this.severity,
    required this.timestamp,
    this.transformedText,
    this.suggestions = const [],
    this.reason,
  });

  factory HateSpeechIncident.fromJson(Map<String, dynamic> json) {
    return HateSpeechIncident(
      originalText: json['originalText'] ?? '',
      category: json['category'] ?? 'general',
      severity: json['severity'] ?? 'unknown',
      timestamp: DateTime.parse(json['timestamp']),
      transformedText: json['transformedText'],
      suggestions: List<String>.from(json['suggestions'] ?? []),
      reason: json['reason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'originalText': originalText,
      'category': category,
      'severity': severity,
      'timestamp': timestamp.toIso8601String(),
      'transformedText': transformedText,
      'suggestions': suggestions,
      'reason': reason,
    };
  }
}
