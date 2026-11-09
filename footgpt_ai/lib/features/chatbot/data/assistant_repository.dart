import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_paths.dart';
import 'assistant_models.dart';

const defaultSuggestions = [
  'Compare two wingers using verified season stats',
  'How does a 4-3-3 press work?',
  'Explain a stored FootGPT prediction',
  'What do we know about a team\'s recent form?',
];

class AssistantRepository {
  AssistantRepository(this._client);

  final ApiClient _client;

  Future<List<AssistantMessage>> history({int? conversationId}) async {
    if (!_client.hasBaseUrl) return [];
    final token = await _client.tokens.readAccess();
    if (token == null || token.isEmpty) {
      throw const ApiException('Sign in to use FootGPT Chat.', statusCode: 401);
    }
    final response = await _client.get<Map<String, dynamic>>(
      ApiPaths.assistantMessages,
      queryParameters: {
        'conversation': ?conversationId,
      },
    );
    final results = (response.data?['results'] as List?) ?? const [];
    final messages = results.map((row) {
      final map = row as Map<String, dynamic>;
      return AssistantMessage(
        id: map['id'] as int?,
        text: '${map['message'] ?? ''}',
        isUser: map['role'] == 'user',
      );
    }).toList();
    return messages.reversed.toList();
  }

  Future<List<String>> suggestions() async {
    if (!_client.hasBaseUrl) return defaultSuggestions;
    try {
      final response = await _client.get<Map<String, dynamic>>(
        ApiPaths.assistantSuggestions,
      );
      final results = (response.data?['results'] as List?) ?? const [];
      if (results.isEmpty) return defaultSuggestions;
      return results.map((item) => '$item').toList();
    } on ApiException {
      return defaultSuggestions;
    }
  }

  Future<ChatReply> send({
    required String message,
    int? conversationId,
  }) async {
    if (!_client.hasBaseUrl) {
      throw const ApiException('API is not configured.');
    }
    final token = await _client.tokens.readAccess();
    if (token == null || token.isEmpty) {
      throw const ApiException('Sign in to use FootGPT Chat.', statusCode: 401);
    }
    final response = await _client.post<Map<String, dynamic>>(
      ApiPaths.assistantChat,
      data: {
        'message': message,
        'conversation_id': ?conversationId,
      },
      receiveTimeout: const Duration(seconds: 60),
    );
    final data = response.data ?? {};
    final assistant = data['assistant'] as Map<String, dynamic>? ?? {};
    final suggestions =
        (data['suggestions'] as List?)?.map((item) => '$item').toList() ??
        defaultSuggestions;
    return ChatReply(
      conversationId: data['conversation_id'] as int? ?? conversationId,
      assistant: AssistantMessage(
        id: assistant['id'] as int?,
        text: '${assistant['message'] ?? ''}',
        isUser: false,
      ),
      suggestions: suggestions,
    );
  }
}

final assistantRepositoryProvider = Provider<AssistantRepository>((ref) {
  return AssistantRepository(ref.watch(apiClientProvider));
});
