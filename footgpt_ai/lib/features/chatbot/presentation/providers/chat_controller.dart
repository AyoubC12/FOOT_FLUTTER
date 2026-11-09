import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/assistant_models.dart';
import '../../data/assistant_repository.dart';

class ChatState {
  const ChatState({
    this.messages = const [],
    this.suggestions = defaultSuggestions,
    this.conversationId,
    this.sending = false,
    this.loadingHistory = true,
    this.needsAuth = false,
    this.error,
  });

  final List<AssistantMessage> messages;
  final List<String> suggestions;
  final int? conversationId;
  final bool sending;
  final bool loadingHistory;
  final bool needsAuth;
  final String? error;

  ChatState copyWith({
    List<AssistantMessage>? messages,
    List<String>? suggestions,
    int? conversationId,
    bool? sending,
    bool? loadingHistory,
    bool? needsAuth,
    String? error,
    bool clearError = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      suggestions: suggestions ?? this.suggestions,
      conversationId: conversationId ?? this.conversationId,
      sending: sending ?? this.sending,
      loadingHistory: loadingHistory ?? this.loadingHistory,
      needsAuth: needsAuth ?? this.needsAuth,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class ChatController extends Notifier<ChatState> {
  bool _started = false;

  @override
  ChatState build() {
    if (!_started) {
      _started = true;
      Future<void>.microtask(load);
    }
    return const ChatState();
  }

  AssistantRepository get _repo => ref.read(assistantRepositoryProvider);

  Future<void> load() async {
    state = state.copyWith(loadingHistory: true, clearError: true);
    try {
      final history = await _repo.history();
      final suggestions = await _repo.suggestions();
      state = state.copyWith(
        messages: history.isEmpty
            ? const [
                AssistantMessage(
                  text:
                      'I’m FootGPT. Ask about tactics, verified stats, or a stored prediction.',
                  isUser: false,
                ),
              ]
            : history,
        suggestions: suggestions,
        loadingHistory: false,
        needsAuth: false,
      );
    } on ApiException catch (error) {
      state = state.copyWith(
        loadingHistory: false,
        needsAuth: error.isUnauthorized,
        error: error.isUnauthorized ? null : error.message,
        messages: const [
          AssistantMessage(
            text:
                'I’m FootGPT. Sign in to keep a conversation and use verified football data.',
            isUser: false,
          ),
        ],
      );
    }
  }

  Future<void> send(String raw) async {
    final text = raw.trim();
    if (text.isEmpty || state.sending) return;
    if (state.needsAuth) {
      state = state.copyWith(error: 'Sign in to use FootGPT Chat.');
      return;
    }
    state = state.copyWith(
      sending: true,
      clearError: true,
      messages: [
        ...state.messages,
        AssistantMessage(text: text, isUser: true),
      ],
    );
    try {
      final reply = await _repo.send(
        message: text,
        conversationId: state.conversationId,
      );
      state = state.copyWith(
        sending: false,
        conversationId: reply.conversationId,
        suggestions: reply.suggestions,
        messages: [...state.messages, reply.assistant],
      );
    } on ApiException catch (error) {
      state = state.copyWith(
        sending: false,
        needsAuth: error.isUnauthorized,
        error: error.message,
        messages: [
          ...state.messages,
          AssistantMessage(text: error.message, isUser: false, failed: true),
        ],
      );
    }
  }
}

final chatControllerProvider = NotifierProvider<ChatController, ChatState>(
  ChatController.new,
);
