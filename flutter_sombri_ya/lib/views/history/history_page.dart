import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../presentation/blocs/history/history_bloc.dart';
import '../../presentation/blocs/history/history_event.dart';
import '../../presentation/blocs/history/history_state.dart';
import '../../../data/models/rental_model.dart';
import '../../../data/repositories/history_repository.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final storage = const FlutterSecureStorage();
  String? _userId;

  late final HistoryBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = HistoryBloc(repository: HistoryRepository());
    _initAndLoad();
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  Future<void> _initAndLoad() async {
    final userId = await storage.read(key: 'user_id');
    if (!mounted) return;
    setState(() => _userId = userId);

    if (userId != null && userId.isNotEmpty) {
      _bloc.add(LoadHistory(userId));
    }
  }

  String _formatDuration(int? minutes) {
    if (minutes == null) return 'Duración: N/A';
    if (minutes < 60) return 'Duración: $minutes minutos';
    if (minutes == 60) return 'Duración: 1 hora';
    final hours = minutes / 60.0;
    return 'Duración: ${hours.toStringAsFixed(1)} horas';
  }

  Widget _historyTile(Rental item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFB1E6F3),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2)),
        ],
      ),
      child: ListTile(
        leading: const Icon(Icons.umbrella, color: Colors.black54),
        title: Text(
          DateFormat('d \'de\' MMMM, yyyy', 'es_ES').format(item.startTime),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(_formatDuration(item.durationMinutes)),
        trailing: Text(
          DateFormat('hh:mm a').format(item.startTime),
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Color(0xFF90E0EF),
          foregroundColor: Colors.black,
          centerTitle: true,
          title: Text(
            "Historial",
            style: GoogleFonts.cormorantGaramond(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        backgroundColor: const Color(0xFFFFFDFD),
        body: RefreshIndicator(
          onRefresh: () async {
            if (_userId != null && _userId!.isNotEmpty) {
              _bloc.add(RefreshHistory(_userId!));
            }
          },
          child: BlocBuilder<HistoryBloc, HistoryState>(
            builder: (context, state) {
              if (_userId == null || _userId!.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is HistoryInitial || state is HistoryLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is HistoryError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red[700]),
                    ),
                  ),
                );
              }
              if (state is HistoryEmpty) {
                return const Center(
                  child: Text('No tienes alquileres en tu historial.'),
                );
              }
              if (state is HistoryLoaded) {
                final history = state.rentals;
                return ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: history.length,
                  itemBuilder: (_, i) => _historyTile(history[i]),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}
