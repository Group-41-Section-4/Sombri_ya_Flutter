import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../presentation/blocs/help/help_bloc.dart';
import '../../presentation/blocs/help/help_event.dart';
import '../../presentation/blocs/help/help_state.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HelpBloc()..add(HelpStarted()),
      child: Scaffold(
        backgroundColor: const Color(0xFFE9F9FF),
        appBar: AppBar(
          title: const Text('Ayuda'),
          backgroundColor: const Color(0xFF00B4D8),
          elevation: 0,
        ),
        body: BlocBuilder<HelpBloc, HelpState>(
          builder: (context, state) {
            if (state.isLoading && state.faqs.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (state.offlineMode)
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        state.fromCache
                            ? 'Estás viendo la última versión guardada de la ayuda (sin conexión).'
                            : 'Sin conexión. Algunas funciones podrían no estar disponibles.',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  if (state.error != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(state.error!),
                    ),

                  _SectionCard(
                    title: 'Preguntas frecuentes',
                    child: Column(
                      children: state.faqs
                          .map(
                            (f) => ListTile(
                              title: Text(
                                f.question,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(f.answer),
                            ),
                          )
                          .toList(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  _SectionCard(
                    title: 'Tutoriales',
                    child: Column(
                      children: state.tutorials
                          .map(
                            (t) => ListTile(
                              title: Text(t.title),
                              trailing: const Icon(Icons.play_circle_outline),
                              onTap: () {
                                // TODO: abrir video / paso a paso
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  _SectionCard(
                    title: 'Contáctanos',
                    child: Column(
                      children: const [
                        ListTile(
                          leading: Icon(Icons.mail_outline),
                          title: Text('ayuda@sombriya.com'),
                        ),
                        ListTile(
                          leading: Icon(Icons.chat_bubble_outline),
                          title: Text('Sombri-YA'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (state.isLoading)
                    const Center(child: CircularProgressIndicator()),

                  if (!state.isLoading)
                    TextButton.icon(
                      onPressed: () {
                        context.read<HelpBloc>().add(HelpRefreshed());
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Actualizar'),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
