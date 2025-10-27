import 'dart:async';
import 'package:bloc/bloc.dart';
import '../../../data/models/chat_message.dart';
import '../../../data/repositories/chat_repository.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final IChatRepository repo;
  StreamSubscription<String>? _sub;

  ChatBloc({required this.repo}) : super(const ChatState()) {
    on<ChatUserSent>(_onUserSent);
    on<ChatChunkArrived>(_onChunk);
    on<ChatStreamEnded>(_onEnded);
    on<ChatStopRequested>(_onStop);
    on<ChatCleared>(_onClear);
  }

  Future<void> _onUserSent(ChatUserSent e, Emitter<ChatState> emit) async {
    await _sub?.cancel();

    final newHistory = List<ChatMessage>.from(state.history)
      ..add(ChatMessage(role: 'user', content: e.text));

    emit(state.copyWith(
      history: newHistory,
      streamingBuffer: '',
      isStreaming: e.stream,
      error: null,
    ));

    _sub = repo.streamCompletion(history: newHistory, stream: e.stream).listen(
          (chunk) => add(ChatChunkArrived(chunk)),
      onError: (err) => emit(state.copyWith(isStreaming: false, error: 'Error: $err')),
      onDone: () => add(const ChatStreamEnded()),
      cancelOnError: true,
    );
  }

  void _onChunk(ChatChunkArrived e, Emitter<ChatState> emit) {
    emit(state.copyWith(streamingBuffer: state.streamingBuffer + e.chunk));
  }

  void _onEnded(ChatStreamEnded e, Emitter<ChatState> emit) {
    final text = state.streamingBuffer;
    if (text.isNotEmpty) {
      final newHistory = List<ChatMessage>.from(state.history)
        ..add(ChatMessage(role: 'assistant', content: text));
      emit(state.copyWith(history: newHistory, streamingBuffer: '', isStreaming: false));
    } else {
      emit(state.copyWith(isStreaming: false));
    }
  }

  Future<void> _onStop(ChatStopRequested e, Emitter<ChatState> emit) async {
    await _sub?.cancel();
    emit(state.copyWith(isStreaming: false));
  }

  void _onClear(ChatCleared e, Emitter<ChatState> emit) {
    emit(const ChatState());
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
