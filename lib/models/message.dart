class Message {
  final String id;
  final String text;
  final String sender;
  final DateTime timestamp;
  final bool isFiltered;
  final String? originalText;
  final String? suggestion;

  Message({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
    this.isFiltered = false,
    this.originalText,
    this.suggestion,
  });
}