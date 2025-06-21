class FilterResult {
  final bool hasHate;
  final String filteredText;
  final List<String> suggestions;
  final bool shouldCensor;
  final String originalText;
  final String category;
  final String severity;
  final String? reason;

  FilterResult({
    this.hasHate = false,
    this.filteredText = '',
    this.suggestions = const [],
    this.shouldCensor = false,
    required this.originalText,
    this.category = 'none',
    this.severity = 'none',
    this.reason,
  });
}