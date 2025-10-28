import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/station_repository.dart';
import '../../data/repositories/tag_repository.dart';
import '../../data/models/station_model.dart';
import '../../services/nfc_service.dart';

import '../../presentation/blocs/nfc_register/nfc_register_bloc.dart';
import '../../presentation/blocs/nfc_register/nfc_register_event.dart';
import '../../presentation/blocs/nfc_register/nfc_register_state.dart';

class RegisterNfcStationPage extends StatelessWidget {
  final String authToken;
  const RegisterNfcStationPage({super.key, required this.authToken});

  static const String baseUrl =
      "https://sombri-ya-back-4def07fa1804.herokuapp.com";

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NfcRegisterBloc(
        stationRepo: StationRepository(),
        tagRepo: TagRepository(baseUrl: baseUrl, authToken: authToken),
        nfc: NfcService(),
      )..add(const LoadStationsRequested(lat: 4.6030837, lng: -74.0651307)),
      child: const _RegisterView(),
    );
  }
}

class _RegisterView extends StatefulWidget {
  const _RegisterView();

  @override
  State<_RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<_RegisterView> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF6FBFF),
      appBar: AppBar(
        title: const Text("Registrar NFC de estación"),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      body: BlocConsumer<NfcRegisterBloc, NfcRegisterState>(
        listenWhen: (prev, curr) =>
        prev.status != curr.status || prev.message != curr.message,
        listener: (context, state) async {
          if (state.status == NfcRegisterStatus.needsAssignment &&
              state.stations.isNotEmpty &&
              state.lastUid != null) {
            final bloc = context.read<NfcRegisterBloc>();
            final selected = await _showAssignDialog(
              context: context,
              stations: state.stations,
            );
            if (selected != null) {
              bloc.add(AssignRequested(uid: state.lastUid!, stationId: selected.id));
            }
          }

          if (state.status == NfcRegisterStatus.assignedOk) {
            _showSnack(context, state.message, Colors.green);
          } else if (state.status == NfcRegisterStatus.error) {
            _showSnack(context, state.message, Colors.orange);
          }
        },
        builder: (context, state) {
          final bloc = context.read<NfcRegisterBloc>();

          final title = state.isScanning ? "Ready to scan" : "Acerca tu tarjeta NFC";
          final subtitle = state.message;

          return LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: Card(
                              elevation: 8,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _StatusChip(status: state.status),
                                    const SizedBox(height: 20),
                                    Container(
                                      width: 120,
                                      height: 120,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xFFE9F8FB),
                                      ),
                                      child: const Center(
                                        child: Icon(Icons.nfc, size: 64),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      title,
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      subtitle,
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: state.isScanning
                                            ? null
                                            : () => bloc.add(const ScanRequested()),
                                        icon: const Icon(Icons.nfc),
                                        label: Text(
                                          state.isScanning
                                              ? "Escaneando..."
                                              : "Escanear NFC",
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: scheme.primary,
                                          foregroundColor: scheme.onPrimary,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                            horizontal: 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                        ),
                                      ),
                                    ),

                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton.icon(
                                onPressed: () => bloc.add(const RefreshStationsRequested()),
                                icon: const Icon(Icons.refresh),
                                label: const Text("Recargar estaciones"),
                              ),
                              const SizedBox(width: 12),
                              if (state.status == NfcRegisterStatus.loadingStations)
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              else
                                Opacity(
                                  opacity: 0.7,
                                  child: Text(
                                    "(${state.stations.length})",
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<Station?> _showAssignDialog({
    required BuildContext context,
    required List<Station> stations,
  }) async {
    Station? tempSelected;
    return showDialog<Station>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text("Asociar NFC a estación"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Selecciona la estación correspondiente:"),
              const SizedBox(height: 12),
              DropdownButton<Station>(
                isExpanded: true,
                value: tempSelected,
                hint: const Text("Selecciona una estación"),
                onChanged: (st) => setModalState(() => tempSelected = st),
                items: stations
                    .map((s) => DropdownMenuItem(
                  value: s,
                  child: Text(s.placeName),
                ))
                    .toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: tempSelected == null
                  ? null
                  : () => Navigator.pop(context, tempSelected),
              child: const Text("Asignar"),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnack(BuildContext ctx, String msg, Color color) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final NfcRegisterStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    late final Color bg;
    late final String label;

    switch (status) {
      case NfcRegisterStatus.scanning:
        bg = const Color(0xFFEAF6FF);
        label = "Escaneando";
        break;
      case NfcRegisterStatus.associatedKnown:
        bg = const Color(0xFFE8F5E9);
        label = "Tag reconocido";
        break;
      case NfcRegisterStatus.needsAssignment:
        bg = const Color(0xFFFFF8E1);
        label = "Asignación requerida";
        break;
      case NfcRegisterStatus.assigning:
        bg = const Color(0xFFFFF3E0);
        label = "Asignando…";
        break;
      case NfcRegisterStatus.assignedOk:
        bg = const Color(0xFFE8F5E9);
        label = "Asignado";
        break;
      case NfcRegisterStatus.loadingStations:
        bg = const Color(0xFFEAF6FF);
        label = "Cargando estaciones…";
        break;
      case NfcRegisterStatus.error:
        bg = const Color(0xFFFFEBEE);
        label = "Error";
        break;
      case NfcRegisterStatus.stationsLoaded:
      case NfcRegisterStatus.idle:
      default:
        bg = const Color(0xFFF1F1F1);
        label = "Listo";
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
