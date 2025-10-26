import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/chat_message.dart';
import '../../presentation/blocs/chat/chat_bloc.dart';
import '../../presentation/blocs/chat/chat_event.dart';
import '../../presentation/blocs/chat/chat_state.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _controller = TextEditingController();
  final _scrollCtrl = ScrollController();
  final bool streamMode = true;


  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send(BuildContext context) {
    final bloc = context.read<ChatBloc>();
    if (bloc.state.isStreaming) return;
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    FocusScope.of(context).unfocus();
    bloc.add(ChatUserSent(text, stream: streamMode));
    _controller.clear();
    _scrollToEnd();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sombri-IA'),
        actions: [
          IconButton(
            tooltip: 'Limpiar',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => context.read<ChatBloc>().add(const ChatCleared()),
          ),

        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocConsumer<ChatBloc, ChatState>(
              listenWhen: (p, c) =>
              p.history.length != c.history.length ||
                  p.streamingBuffer != c.streamingBuffer,
              listener: (_, __) => _scrollToEnd(),
              builder: (context, state) {
                final items = [
                  ...state.history,
                  if (state.streamingBuffer.isNotEmpty)
                    const ChatMessage(role: 'assistant', content: ''),
                ];

                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final isLastStreaming =
                        state.streamingBuffer.isNotEmpty && i == items.length - 1;
                    final m = isLastStreaming
                        ? const ChatMessage(role: 'assistant', content: '')
                        : items[i];

                    final content = isLastStreaming
                        ? state.streamingBuffer
                        : m.content;

                    final isUser = m.role == 'user';
                    return Align(
                      alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(12),
                        constraints: const BoxConstraints(maxWidth: 600),
                        decoration: BoxDecoration(
                          color: isUser
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(content),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: BlocBuilder<ChatBloc, ChatState>(
                buildWhen: (p, c) => p.isStreaming != c.isStreaming,
                builder: (context, state) {
                  final disabled = state.isStreaming;
                  return Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          minLines: 1,
                          maxLines: 4,
                          enabled: !disabled,
                          onSubmitted: (_) => _send(context),
                          decoration: InputDecoration(
                            hintText: disabled
                                ? 'Generando…'
                                : 'Escribe tu mensaje…',
                            border: const OutlineInputBorder(),
                            suffixIcon: disabled
                                ? const Padding(
                              padding: EdgeInsets.all(10),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      disabled
                          ? IconButton(
                        tooltip: 'Detener',
                        onPressed: () => context
                            .read<ChatBloc>()
                            .add(const ChatStopRequested()),
                        icon: const Icon(Icons.stop_circle_outlined),
                      )
                          : ElevatedButton.icon(
                        onPressed: () => _send(context),
                        icon: const Icon(Icons.send),
                        label: const Text('Enviar'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
