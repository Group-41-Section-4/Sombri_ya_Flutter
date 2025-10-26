import 'package:equatable/equatable.dart';
import '../../../data/models/chat_message.dart';

class ChatState extends Equatable {
  final List<ChatMessage> history;
  final String streamingBuffer;
  final bool isStreaming;
  final String? error;
  final bool streamMode;

  const ChatState({
    this.history = const [],
    this.streamingBuffer = '',
    this.isStreaming = false,
    this.error,
    this.streamMode = true,
  });

  ChatState copyWith({
    List<ChatMessage>? history,
    String? streamingBuffer,
    bool? isStreaming,
    String? error,
    bool? streamMode,
  }) => ChatState(
    history: history ?? this.history,
    streamingBuffer: streamingBuffer ?? this.streamingBuffer,
    isStreaming: isStreaming ?? this.isStreaming,
    error: error,
    streamMode: streamMode ?? this.streamMode,
  );

  @override
  List<Object?> get props => [history, streamingBuffer, isStreaming, error, streamMode];
}
