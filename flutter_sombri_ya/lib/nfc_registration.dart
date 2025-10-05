import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nfc_manager/nfc_manager.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'models/station_model.dart';
import 'service_adapters/stations_service.dart';

String bytesToHex(Uint8List bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':').toUpperCase();

class RegisterNfcStationPage extends StatefulWidget {
  final String authToken;
  const RegisterNfcStationPage({required this.authToken, super.key});

  @override
  State<RegisterNfcStationPage> createState() => _RegisterNfcStationPageState();
}

class _RegisterNfcStationPageState extends State<RegisterNfcStationPage> {
  final StationsService _stationsService = StationsService();

  String _status = "Presiona 'Escanear' y acerca la tarjeta NFC.";
  bool _isScanning = false;

  List<Station> _stations = [];
  Station? _selectedStation;

  static const String baseUrl =
      "https://sombri-ya-back-4def07fa1804.herokuapp.com";

  @override
  void initState() {
    super.initState();
    _loadStations();
  }

  Future<void> _loadStations() async {
    try {
      setState(() => _status = "Cargando lista de estaciones...");

      const dummyLocation = LatLng(4.6030837, -74.0651307);

      final stations = await _stationsService.findNearbyStations(dummyLocation);

      setState(() {
        _stations = stations;
        _status = "Estaciones cargadas correctamente.";
      });
    } catch (e) {
      setState(() => _status = "Error cargando estaciones: $e");
    }
  }

  Future<void> _startScan() async {
    if (!await NfcManager.instance.isAvailable()) {
      setState(() => _status = "NFC no disponible en este dispositivo.");
      return;
    }

    setState(() {
      _isScanning = true;
      _status = "📡 Acerca la tarjeta NFC...";
    });

    await NfcManager.instance.startSession(
      pollingOptions: {NfcPollingOption.iso14443},
      onDiscovered: (NfcTag tag) async {
        try {
          print("📡 Tag detectado: ${tag.data.runtimeType}");

          final tagData = tag.data;
          Uint8List? id;

          if (tagData is Map) {

            if (tagData.containsKey('nfca')) {
              final nfca = tagData['nfca'];
              if (nfca is Map && nfca['identifier'] != null) {
                final raw = nfca['identifier'];
                if (raw is Uint8List) {
                  id = raw;
                } else if (raw is List) {
                  id = Uint8List.fromList(raw.cast<int>());
                }
              }
            }


            if (id == null && tagData.containsKey('mifareclassic')) {
              final mifare = tagData['mifareclassic'];
              if (mifare is Map && mifare['identifier'] != null) {
                final raw = mifare['identifier'];
                if (raw is Uint8List) {
                  id = raw;
                } else if (raw is List) {
                  id = Uint8List.fromList(raw.cast<int>());
                }
              }
            }


            if (id == null) {
              for (final entry in tagData.entries) {
                final value = entry.value;
                if (value is Map && value['identifier'] != null) {
                  final raw = value['identifier'];
                  if (raw is Uint8List) {
                    id = raw;
                    break;
                  } else if (raw is List) {
                    id = Uint8List.fromList(raw.cast<int>());
                    break;
                  }
                }
              }
            }
          }


          if (id == null) {
            _showSnack("⚠️ No se pudo detectar UID del tag", Colors.orange);
            await NfcManager.instance.stopSession();
            return;
          }


          final uid = id.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':').toUpperCase();


          setState(() => _status = "Tag detectado: $uid");


          await Future.delayed(const Duration(milliseconds: 1500));

          await _checkStationAssociation(uid);

          await NfcManager.instance.stopSession();
          setState(() => _isScanning = false);
        } catch (e, st) {
          print("Error leyendo NFC: $e");
          print(st);
          await NfcManager.instance.stopSession();
          setState(() {
            _isScanning = false;
            _status = "Error leyendo NFC: $e";
          });
        }
      },
    );

  }

  Future<void> _checkStationAssociation(String uid) async {
    try {
      final url = Uri.parse("$baseUrl/stations/by-tag/$uid");
      final resp = await http.get(url, headers: {
        'Authorization': 'Bearer ${widget.authToken}',
      });

      if (resp.statusCode == 200) {
        final station = jsonDecode(resp.body);
        setState(() => _status =
        "Este tag pertenece a la estación: ${station['name']}");
      } else if (resp.statusCode == 404) {
        setState(() =>
        _status = "Este tag no está asociado. Selecciona una estación.");
        await _showAssignDialog(uid);
      } else {
        setState(() => _status =
        "Error consultando el tag (${resp.statusCode}): ${resp.body}");
      }
    } catch (e) {
      setState(() => _status = "Error al consultar: $e");
    }
  }

  Future<void> _showAssignDialog(String uid) async {
    if (_stations.isEmpty) {
      setState(() {
        _status = "No hay estaciones disponibles para asociar.";
      });
      return;
    }

    await showDialog(
      context: context,
      builder: (_) {
        Station? tempSelected = _selectedStation;

        return StatefulBuilder(
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
                  onChanged: (station) {
                    setModalState(() {
                      tempSelected = station;
                    });
                  },
                  items: _stations.map((station) {
                    final label = station.placeName ??
                        (station.toString().contains('Instance')
                            ? station.id
                            : station.toString());
                    return DropdownMenuItem(
                      value: station,
                      child: Text(label),
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancelar"),
              ),
              ElevatedButton(
                onPressed: tempSelected == null
                    ? null
                    : () async {
                  Navigator.pop(context);
                  setState(() => _selectedStation = tempSelected);
                  await _assignTagToStation(uid, tempSelected!.id);
                },
                child: const Text("Asignar"),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _assignTagToStation(String uid, String stationId) async {
    try {
      final url = Uri.parse("$baseUrl/stations/$stationId/tags");
      final body = jsonEncode({
        'tag_uid': uid,
        'tag_type': 'NFC-A',
        'meta': {'registered_from': 'app'},
      });


      final resp = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.authToken}',
        },
        body: body,
      );

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        setState(() => _status =
        "✅ Tag asociado correctamente a la estación seleccionada.");
      } else {
        setState(() => _status =
        "Error al asociar (${resp.statusCode}): ${resp.body}");
      }
    } catch (e) {
      setState(() => _status = "Error enviando datos: $e");
    }
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Registrar NFC de estación"),
        backgroundColor: const Color(0xFFFCE55F),
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _status,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isScanning ? null : _startScan,
              icon: const Icon(Icons.nfc),
              label: Text(_isScanning ? "Escaneando..." : "Escanear NFC"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFCE55F),
                foregroundColor: Colors.black,
                padding:
                const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _loadStations,
              child: const Text("Recargar lista de estaciones"),
            ),
          ],
        ),
      ),
    );
  }
}
