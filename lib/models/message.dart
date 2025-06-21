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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'sender': sender,
      'timestamp': timestamp.toIso8601String(),
      'isFiltered': isFiltered,
      'originalText': originalText,
      'suggestion': suggestion,
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      text: json['text'],
      sender: json['sender'],
      timestamp: DateTime.parse(json['timestamp']),
      isFiltered: json['isFiltered'] ?? false,
      originalText: json['originalText'],
      suggestion: json['suggestion'],
    );
  }
}