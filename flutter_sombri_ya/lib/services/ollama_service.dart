import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/ollama_config.dart';

class ChatMessageDto {
  final String role;
  final String content;
  ChatMessageDto({required this.role, required this.content});
  Map<String, String> toMap() => {"role": role, "content": content};
}

class OllamaService {
  final String ollamaBaseUrl;
  final String model;

  const OllamaService({
    String? ollamaBaseUrl,
    String? model,
  }) : ollamaBaseUrl = ollamaBaseUrl ?? OllamaConfig.ollamaBaseUrl,
        model         = model ?? OllamaConfig.model;

  factory OllamaService.fromConfig() => const OllamaService();

  Stream<String> streamChat({
    required List<ChatMessageDto> history,
    bool stream = false,
    Duration timeout = const Duration(seconds: 60),
  }) async* {
    final uri = Uri.parse('$ollamaBaseUrl/api/chat');
    final payload = {
      "model": model,
      "stream": stream,
      "messages": history.map((m) => m.toMap()).toList(),
    };

    if (!stream) {
      final r = await http.post(uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload)).timeout(timeout);
      if (r.statusCode != 200) {
        throw Exception('Error ${r.statusCode}: ${r.body}');
      }
      final data = jsonDecode(r.body);
      final content = (data['message']?['content'] ?? '').toString();
      if (content.isNotEmpty) yield content;
      return;
    }

    final req = http.Request('POST', uri)
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode(payload);

    final client = http.Client();
    http.StreamedResponse resp;
    try {
      resp = await client.send(req).timeout(timeout);
      if (resp.statusCode != 200) {
        final body = await resp.stream.bytesToString();
        throw Exception('Error ${resp.statusCode}: $body');
      }

      final lines = resp.stream.transform(utf8.decoder).transform(const LineSplitter());
      await for (final line in lines) {
        if (line.trim().isEmpty) continue;
        final Map<String, dynamic> data = jsonDecode(line);
        if (data['message'] != null) {
          final piece = (data['message']['content'] ?? '').toString();
          if (piece.isNotEmpty) yield piece;
        }
        if (data['done'] == true) break;
      }
    } finally {
      client.close();
    }
  }
}