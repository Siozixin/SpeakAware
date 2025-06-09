class HatePattern {
  final RegExp pattern;
  final String replacement;
  final String suggestion;
  final String severity;

  HatePattern({
    required this.pattern,
    required this.replacement,
    required this.suggestion,
    required this.severity,
  });
}
