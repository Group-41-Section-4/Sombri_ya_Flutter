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
import '../../../core/connectivity/connectivity_service.dart';
import '../../presentation/blocs/connectivity/connectivity_cubit.dart';

import 'rental_detail_page.dart';

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

  Widget _historyTile(BuildContext context, Rental item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFB1E6F3),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(2, 2),
          ),
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
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RentalDetailPage(rentalId: item.id),
            ),
          );
        },
      ),
    );
  }

  Widget _offlineCat(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF90E0EF),
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 300,
              height: 300,
              child: Image.asset(
                'assets/images/gato.jpeg',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '¡Miau! Parece que perdimos la conexión...',
              style: GoogleFonts.robotoSlab(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Esperando a que vuelva el internet para mostrar el historial.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityCubit, ConnectivityStatus>(
      builder: (context, connectivityStatus) {
        final isOffline = connectivityStatus != ConnectivityStatus.online;

        if (isOffline) {
          return _offlineCat(context);
        }

        return BlocProvider.value(
          value: _bloc,
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: const Color(0xFF90E0EF),
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
                      itemBuilder: (context, i) =>
                          _historyTile(context, history[i]),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
