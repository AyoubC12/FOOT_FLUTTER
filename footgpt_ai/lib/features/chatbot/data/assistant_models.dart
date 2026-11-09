class AssistantMessage {
  const AssistantMessage({
    required this.text,
    required this.isUser,
    this.id,
    this.failed = false,
  });

  final int? id;
  final String text;
  final bool isUser;
  final bool failed;

  AssistantMessage copyWith({String? text, bool? failed}) {
    return AssistantMessage(
      id: id,
      text: text ?? this.text,
      isUser: isUser,
      failed: failed ?? this.failed,
    );
  }
}

class ChatReply {
  const ChatReply({
    required this.conversationId,
    required this.assistant,
    required this.suggestions,
  });

  final int? conversationId;
  final AssistantMessage assistant;
  final List<String> suggestions;
}
