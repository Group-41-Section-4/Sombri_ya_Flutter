import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../data/repositories/history_repository.dart';
import '../../../data/repositories/report_repository.dart';
import '../../core/connectivity/connectivity_service.dart';
import '../../presentation/blocs/rental_detail/rental_detail_bloc.dart';
import '../../presentation/blocs/rental_detail/rental_detail_event.dart';
import '../../presentation/blocs/rental_detail/rental_detail_state.dart';
import '../../../data/models/rental_format_model.dart';
import '../../presentation/blocs/connectivity/connectivity_cubit.dart';
import '../../../data/models/rental_export_row.dart';

class RentalDetailPage extends StatelessWidget {
  final String rentalId;

  const RentalDetailPage({
    super.key,
    required this.rentalId,
  });

  String _formatDuration(int? minutes) {
    if (minutes == null) return 'Duración total: N/A';
    if (minutes < 60) return 'Duración total: $minutes minutos';
    if (minutes == 60) return 'Duración total: 1 hora';
    final hours = minutes / 60.0;
    return 'Duración total: ${hours.toStringAsFixed(1)} horas';
  }

  Widget _offlineView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.wifi_off, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Sin conexión a internet',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'No pudimos cargar los detalles de esta renta. '
                  'Conéctate de nuevo e inténtalo otra vez.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final historyRepo = HistoryRepository();
    final reportRepo = RepositoryProvider.of<ReportRepository>(context);

    return BlocProvider(
      create: (_) => RentalDetailBloc(
        historyRepository: historyRepo,
        reportRepository: reportRepo,
      )..add(LoadRentalDetail(rentalId)),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF90E0EF),
          foregroundColor: Colors.black,
          centerTitle: true,
          title: Text(
            'Detalles',
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
        body: BlocBuilder<ConnectivityCubit, ConnectivityStatus>(
          builder: (context, connectivityStatus) {
            final isOffline = connectivityStatus != ConnectivityStatus.online;

            return BlocBuilder<RentalDetailBloc, RentalDetailState>(
              builder: (context, state) {
                if (isOffline && state is! RentalDetailLoaded) {
                  return _offlineView();
                }

                if (state is RentalDetailLoading ||
                    state is RentalDetailInitial) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is RentalDetailError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                }

                if (state is RentalDetailLoaded) {

                  final RentalExportRow rental = state.rental;
                  final List<RentalFormat> formats = state.formats;
                  final RentalFormat? report =
                  formats.isNotEmpty ? formats.first : null;

                  final DateTime start = rental.startTime ?? DateTime.now();
                  final DateTime end = rental.endTime ??
                      start.add(
                        Duration(minutes: rental.durationMinutes ?? 0),
                      );

                  return Column(
                    children: [
                      if (isOffline)
                        Container(
                          width: double.infinity,
                          color: Colors.amber[200],
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.wifi_off, size: 16),
                              SizedBox(width: 8),
                              Text(
                                'Estás sin conexión. No se puede actualizar.',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: () async {
                            if (isOffline) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Sin conexión. No se puede actualizar.',
                                  ),
                                ),
                              );
                              return;
                            }
                            context
                                .read<RentalDetailBloc>()
                                .add(RefreshRentalDetail(rental.id));
                          },
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Center(
                                    child: Column(
                                      children: [
                                        Text(
                                          DateFormat(
                                            'MMMM d, yyyy',
                                            'es_ES',
                                          ).format(start),
                                          style: GoogleFonts.roboto(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatDuration(
                                            rental.durationMinutes,
                                          ),
                                          style: const TextStyle(
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'INICIO',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            DateFormat('hh:mm a').format(start),
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                        children: [
                                          const Text(
                                            'FIN',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            DateFormat('hh:mm a').format(end),
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),


                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: const Icon(
                                      Icons.location_on,
                                      color: Colors.blue,
                                    ),
                                    title: const Text(
                                      'Punto de inicio',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      rental.startStationName ??
                                          'Estación de inicio',
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: const Icon(
                                      Icons.location_on,
                                      color: Colors.red,
                                    ),
                                    title: const Text(
                                      'Punto final',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      rental.endStationName ??
                                          'Estación final',
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE3F7FF),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.info_outline,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            report != null
                                                ? 'Reporte enviado. Está siendo revisado.'
                                                : 'Aún no has enviado un reporte para esta renta.',
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5F5F5),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Resumen del Reporte',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        if (report == null)
                                          const Text(
                                            'No se ha registrado ningún reporte para esta renta.',
                                            style: TextStyle(
                                              color: Colors.grey,
                                            ),
                                          )
                                        else ...[
                                          if (report.imageBase64 != null &&
                                              report.imageBase64!.isNotEmpty)
                                            ...[
                                              SizedBox(
                                                height: 80,
                                                width: 80,
                                                child: ClipRRect(
                                                  borderRadius:
                                                  BorderRadius.circular(12),
                                                  child: Image.memory(
                                                    base64Decode(
                                                      report.imageBase64!,
                                                    ),
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                            ],
                                          Row(
                                            children: [
                                              const Text('Calificación: '),
                                              for (int i = 1; i <= 5; i++)
                                                Icon(
                                                  i <= (report.rating)
                                                      ? Icons.star
                                                      : Icons.star_border,
                                                  size: 18,
                                                  color: Colors.amber,
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          const Text(
                                            'Comentarios:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            report.description ??
                                                'No se registraron comentarios.',
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }

                return const SizedBox.shrink();
              },
            );
          },
        ),
      ),
    );
  }
}
