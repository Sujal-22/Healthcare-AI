enum MessageRole { user, assistant }

class SourceDocument {
  final String content;
  final String source;

  SourceDocument({required this.content, required this.source});

  factory SourceDocument.fromJson(Map<String, dynamic> json) {
    return SourceDocument(
      content: json['content'] ?? '',
      source: json['source'] ?? 'unknown',
    );
  }
}

class ChatMessage {
  final String id;
  final String content;
  final MessageRole role;
  final DateTime timestamp;
  final List<SourceDocument> sources;
  final bool isLoading;

  ChatMessage({
    required this.id,
    required this.content,
    required this.role,
    required this.timestamp,
    this.sources = const [],
    this.isLoading = false,
  });

  bool get isUser => role == MessageRole.user;
  bool get isAssistant => role == MessageRole.assistant;

  ChatMessage copyWith({
    String? content,
    bool? isLoading,
    List<SourceDocument>? sources,
  }) {
    return ChatMessage(
      id: id,
      content: content ?? this.content,
      role: role,
      timestamp: timestamp,
      sources: sources ?? this.sources,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
