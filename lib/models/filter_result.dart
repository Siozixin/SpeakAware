class FilterResult {
  final String originalText;
  final String filteredText;
  final List<String> suggestions;
  final bool hasHate;
  final String severity;

  FilterResult({
    required this.originalText,
    required this.filteredText,
    required this.suggestions,
    required this.hasHate,
    required this.severity,
  });
}