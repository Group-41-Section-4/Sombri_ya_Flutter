import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/models/chat_message.dart';
import '../../presentation/blocs/chat/chat_bloc.dart';
import '../../presentation/blocs/chat/chat_event.dart';
import '../../presentation/blocs/chat/chat_state.dart';

import '../../core/connectivity/connectivity_service.dart';
import '../../presentation/blocs/connectivity/connectivity_cubit.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _controller = TextEditingController();
  final _scrollCtrl = ScrollController();
  final bool streamMode = true;

  final FocusNode _noFocus = FocusNode(canRequestFocus: false);

  bool _retrying = false;

  ConnectivityStatus? _effectiveNet;
  Timer? _offlineGrace;

  @override
  void initState() {
    super.initState();
    _effectiveNet = null;
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollCtrl.dispose();
    _noFocus.dispose();
    _offlineGrace?.cancel();
    _offlineGrace = null;
    super.dispose();
  }

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

  Future<void> _retryConnectivity(BuildContext context) async {
    if (_retrying) return;
    setState(() => _retrying = true);
    try {
      await context.read<ConnectivityCubit>().retry();
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BlocProvider<ConnectivityCubit>(
      create: (_) => ConnectivityCubit(ConnectivityService())..start(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF90E0EF),
          foregroundColor: Colors.black,
          centerTitle: true,
          title: Text(
            'Sombri-IA',
            style: GoogleFonts.cormorantGaramond(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 30,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Limpiar',
              icon: const Icon(Icons.delete_outline),
              onPressed: () =>
                  context.read<ChatBloc>().add(const ChatCleared()),
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
                          state.streamingBuffer.isNotEmpty &&
                          i == items.length - 1;

                      final m = isLastStreaming
                          ? const ChatMessage(role: 'assistant', content: '')
                          : items[i];

                      final content = isLastStreaming
                          ? state.streamingBuffer
                          : m.content;
                      final isUser = m.role == 'user';

                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(12),
                          constraints: const BoxConstraints(maxWidth: 600),
                          decoration: BoxDecoration(
                            color: isUser
                                ? scheme.primaryContainer
                                : scheme.surfaceContainerHighest,
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

                child: BlocListener<ConnectivityCubit, ConnectivityStatus>(
                  listener: (context, net) {
                    if (net == ConnectivityStatus.online) {
                      _offlineGrace?.cancel();
                      _offlineGrace = null;
                      if (_effectiveNet != ConnectivityStatus.online) {
                        setState(
                          () => _effectiveNet = ConnectivityStatus.online,
                        );
                      }
                    } else {
                      _offlineGrace?.cancel();
                      _offlineGrace = Timer(
                        const Duration(milliseconds: 200),
                        () {
                          if (mounted &&
                              _effectiveNet != ConnectivityStatus.offline) {
                            setState(
                              () => _effectiveNet = ConnectivityStatus.offline,
                            );
                          }
                        },
                      );
                    }
                  },

                  child: BlocBuilder<ChatBloc, ChatState>(
                    buildWhen: (p, c) => p.isStreaming != c.isStreaming,
                    builder: (context, chatState) {
                      return Builder(
                        builder: (context) {
                          final isUnknown = _effectiveNet == null;
                          final online =
                              _effectiveNet == ConnectivityStatus.online;
                          final offline =
                              _effectiveNet == ConnectivityStatus.offline;

                          final blocked = chatState.isStreaming || !online;

                          final buttonLabel = isUnknown
                              ? 'Conectando…'
                              : (online ? 'Enviar' : 'Reintentar');

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _controller,
                                      minLines: 1,
                                      maxLines: 4,
                                      readOnly: blocked,
                                      focusNode: blocked ? _noFocus : null,
                                      onTapOutside: (_) =>
                                          FocusScope.of(context).unfocus(),
                                      onSubmitted: (_) => online
                                          ? _send(context)
                                          : _retryConnectivity(context),
                                      decoration: InputDecoration(
                                        hintText: chatState.isStreaming
                                            ? 'Generando…'
                                            : (isUnknown
                                                  ? 'Conectando…'
                                                  : (online
                                                        ? 'Escribe tu mensaje…'
                                                        : 'Sin conexión')),
                                        border: const OutlineInputBorder(),
                                        suffixIcon: chatState.isStreaming
                                            ? const Padding(
                                                padding: EdgeInsets.all(10),
                                                child: SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                ),
                                              )
                                            : null,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  if (chatState.isStreaming)
                                    IconButton(
                                      tooltip: 'Detener',
                                      onPressed: () => context
                                          .read<ChatBloc>()
                                          .add(const ChatStopRequested()),
                                      icon: const Icon(
                                        Icons.stop_circle_outlined,
                                      ),
                                    )
                                  else
                                    ElevatedButton.icon(
                                      onPressed: isUnknown
                                          ? null
                                          : (online
                                                ? () => _send(context)
                                                : () => _retryConnectivity(
                                                    context,
                                                  )),
                                      icon: online
                                          ? const Icon(Icons.send)
                                          : (isUnknown
                                                ? const Icon(Icons.more_horiz)
                                                : (_retrying
                                                      ? const SizedBox(
                                                          width: 18,
                                                          height: 18,
                                                          child:
                                                              CircularProgressIndicator(
                                                                strokeWidth: 2,
                                                              ),
                                                        )
                                                      : const Icon(
                                                          Icons.refresh,
                                                        ))),
                                      label: Text(buttonLabel),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: online
                                            ? const Color(0xFFFAF9F6)
                                            : (isUnknown
                                                  ? Colors.grey[700]
                                                  : Colors.grey[800]),
                                      ),
                                    ),
                                ],
                              ),

                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: offline
                                    ? Padding(
                                        key: const ValueKey('offline'),
                                        padding: const EdgeInsets.only(
                                          top: 8.0,
                                          left: 4,
                                        ),
                                        child: Text(
                                          'Sin conexión a internet. Verifica tu red y toca “Reintentar”.',
                                          style: TextStyle(
                                            color: Colors.red.shade700,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      )
                                    : const SizedBox(
                                        key: ValueKey('ok'),
                                        height: 0,
                                      ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
