import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // Para formatear fechas y horas
import 'service_adapters/rentals_service.dart';
import 'models/rental_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final RentalsService _rentalsService = RentalsService();
  Future<List<Rental>>? _historyFuture;
  String? token;
  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _initPage();
  }

  Future<void> _initPage() async{

    final storedToken = await storage.read(key: "user_id");
    if(storedToken == null) return;

    setState(() {
      token = storedToken;
      _loadHistory(token);
    });
  }


  void _loadHistory(token) {
    setState(() {
      _historyFuture = _rentalsService.getCompletedRentals(
      token,
      );
    });
  }




  String _formatDuration(int? minutes) {
    if (minutes == null) return 'Duración: N/A';
    if (minutes < 60) return 'Duración: $minutes minutos';
    if (minutes == 60) return 'Duración: 1 hora';

    final hours = minutes / 60;
    return 'Duración: ${hours.toStringAsFixed(1)} horas';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF90E0EF),
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
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Rental>>(
              future: _historyFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        'Error al cargar el historial.\nPor favor, inténtalo de nuevo más tarde.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                  );
                }
                final history = snapshot.data ?? [];

                if (history.isEmpty) {
                  return const Center(
                    child: Text('No tienes alquileres en tu historial.'),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final item = history[index];
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
                        leading: const Icon(
                          Icons.umbrella,
                          color: Colors.black54,
                        ),
                        title: Text(
                          DateFormat(
                            'd \'de\' MMMM, yyyy',
                            'es_ES',
                          ).format(item.startTime),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(_formatDuration(item.durationMinutes)),
                        trailing: Text(
                          DateFormat('hh:mm a').format(item.startTime),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
