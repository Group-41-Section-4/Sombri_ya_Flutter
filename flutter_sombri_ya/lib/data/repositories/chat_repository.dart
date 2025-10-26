import '../../services/ollama_service.dart';
import '../models/chat_message.dart';

abstract class IChatRepository {
  Stream<String> streamCompletion({required List<ChatMessage> history, bool stream});
}

class ChatRepository implements IChatRepository {
  final OllamaService service;
  ChatRepository({required this.service});

  @override
  Stream<String> streamCompletion({required List<ChatMessage> history, bool stream = true}) {
    final dto = history.map((m) => ChatMessageDto(role: m.role, content: m.content)).toList();
    return service.streamChat(history: dto, stream: stream);
  }
}
