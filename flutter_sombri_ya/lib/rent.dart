import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'menu.dart';
import 'home.dart';
import 'notifications.dart';
import 'profile.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/platform_tags.dart';
import '../return.dart';
import '../strategies/nfc_rent_strategy.dart';
import '../strategies/qr_rent_strategy.dart';
import '../strategies/rent_strategy.dart';
import '../services/api.dart';
import '../models/gps_coord.dart';
import 'models/rental_model.dart';
import 'dart:typed_data';

class RentPage extends StatefulWidget {
  final GpsCoord userPosition;

  const RentPage({super.key, required this.userPosition});

  @override
  State<RentPage> createState() => _RentPageState();
}

class _RentPageState extends State<RentPage> {
  late RentContext _rentContext;
  String? _qrResult;
  final Api api = Api();
  final storage = const FlutterSecureStorage();

  final MobileScannerController _scannerController = MobileScannerController();
  bool _isProcessing = false;
  bool hasRental = false;
  String? rentalIdDebug;

  @override
  void initState() {
    super.initState();
    _checkActiveRental();
    _rentContext = RentContext(
      QrRentStrategy(
        onCodeScanned: (code) {
          setState(() {
            _qrResult = code;
          });
          debugPrint("Procesando renta con QR: $code");
        },
      ),
    );
  }

  Future<void> _checkActiveRental() async {
    final rentalId = await storage.read(key: "rental_id");
    setState(() {
      hasRental = rentalId != null;
      rentalIdDebug = rentalId;
    });
  }

  void _switchToQr() {
    setState(() {
      _rentContext.strategy = QrRentStrategy(
        onCodeScanned: (code) {
          setState(() {
            _qrResult = code;
          });
          debugPrint("Procesando renta con QR: $code");
        },
      );
    });
  }

  Future<void> _startNfcRental() async {
    await _scannerController.stop();

    await NfcManager.instance.stopSession();
    await Future.delayed(const Duration(milliseconds: 200));

    NfcManager.instance.startSession(
      pollingOptions: {NfcPollingOption.iso14443},
      onDiscovered: (NfcTag tag) async {
        Uint8List? id;

        final nfca = NfcA.from(tag);
        if (nfca != null) {
          id = nfca.identifier;
        } else {
          final iso = IsoDep.from(tag);
          if (iso != null) {
            id = iso.identifier;
          }
        }

        final uid = id!
            .map((b) => b.toRadixString(16).padLeft(2, '0'))
            .join(':')
            .toUpperCase();

        const fixedStationId = "acadc4ef-f5b3-4ab8-9ab5-58f1161f0799";

        final userId = await storage.read(key: "user_id");
        final api = Api();


        final rental = await api.startRental(
          userId: userId!,
          stationStartId: fixedStationId,
          authType: "nfc",
        );

        await storage.write(key: "rental_id", value: rental.id);

        setState(() {
          hasRental = true;
          rentalIdDebug = rental.id;
        });


        await NfcManager.instance.stopSession();
      },
    );
  }



  /// Procesa la renta por NFC (con estación fija opcional)
  Future<void> _processNfcTag(String tagUid, String tagType) async {
    try {
      final existingRental = await storage.read(key: "rental_id");
      if (existingRental != null) {
        _showSnack("⚠Ya tienes una sombrilla rentada", Colors.orange);
        return;
      }

      final userId = await storage.read(key: "user_id");
      if (userId == null) {
        _showSnack("Usuario no encontrado", Colors.red);
        return;
      }


      final Map<String, String> tagToStation = {
        "08:F8:93:B2": "acadc4ef-f5b3-4ab8-9ab5-58f1161f0799", // ejemplo: Uniandes
        // Puedes agregar más:
        // "04:A1:22:C3": "b2cd23aa-30b4-42e0-91b7-3f8a6e05f123",
      };

      String? stationId = tagToStation[tagUid];
      dynamic station;

      if (stationId != null) {
        print("Tag fijo reconocido → estación $stationId");
      } else {
        // Si el tag no está en el mapa, buscar en el backend
        station = await api.getStationByTag(tagUid);
        if (station == null) {
          _showSnack("Estación no encontrada para este tag NFC", Colors.red);
          return;
        }
        stationId = station.id;
      }
      if (stationId == null) {
        _showSnack("No se pudo determinar la estación.", Colors.red);
        return;
      }

      final rental = await api.startRental(
        userId: userId,
        stationStartId: stationId,
        authType: "nfc",
      );

      String? rentalIdToSave = rental.id.isNotEmpty ? rental.id : null;
      if (rentalIdToSave == null) {
        final active = await api.getActiveRental(userId);
        rentalIdToSave = active?.id;
      }

      if (rentalIdToSave == null || rentalIdToSave.isEmpty) {
        _showSnack("No pude obtener el ID de la renta", Colors.orange);
        return;
      }

      await storage.write(key: "rental_id", value: rentalIdToSave);
      setState(() {
        hasRental = true;
        rentalIdDebug = rentalIdToSave;
      });

      if (station != null) {
        _showSnack("Sombrilla rentada con NFC en ${station.placeName ?? station.id}", Colors.green);
      } else {
        _showSnack("Sombrilla rentada con NFC (estación fija)", Colors.green);
      }

    } catch (e) {
      print("Error en renta NFC: $e");
      _showSnack("Error en renta NFC: $e", Colors.red);
    }
  }




  /// 🔹 Procesa el QR detectado
  Future<void> _processQrCode(String code) async {
    try {
      final data = jsonDecode(code);
      final stationId = data["station_id"].toString();

      final existingRental = await storage.read(key: "rental_id");
      if (existingRental != null) {
        _showSnack("Ya tienes una sombrilla rentada", Colors.orange);
        return;
      }

      final userId = await storage.read(key: "user_id");
      if (userId == null) {
        _showSnack("Usuario no encontrado", Colors.red);
        return;
      }

      final rental = await api.startRental(
        userId: userId,
        stationStartId: stationId,
        authType: "qr",
      );

      String? rentalIdToSave = rental.id.isNotEmpty ? rental.id : null;
      if (rentalIdToSave == null) {
        final active = await api.getActiveRental(userId);
        rentalIdToSave = active?.id;
      }

      if (rentalIdToSave == null || rentalIdToSave.isEmpty) {
        _showSnack("No pude obtener el ID de la renta", Colors.orange);
        return;
      }

      await storage.write(key: "rental_id", value: rentalIdToSave);
      setState(() {
        hasRental = true;
        rentalIdDebug = rentalIdToSave;
      });

      _showSnack("🌂 Sombrilla rentada con éxito (QR)", Colors.green);
    } catch (e) {
      print("Error en _processQrCode: $e");
      _showSnack("Error al iniciar la renta: $e", Colors.red);
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
        backgroundColor: const Color(0xFF90E0EF),
        centerTitle: true,
        foregroundColor: Colors.black,
        title: Text(
          'Rentar',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.notifications_none),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NotificationsPage()),
            );
          },
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
            icon: const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white24,
              backgroundImage: AssetImage('assets/images/profile.png'),
            ),
          ),
        ],
      ),
      endDrawer: AppDrawer(),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            fit: BoxFit.cover,
            onDetect: (capture) async {
              final raw = capture.barcodes.isNotEmpty ? capture.barcodes.first.rawValue : null;
              if (raw == null || _isProcessing) return;
              _isProcessing = true;
              await _scannerController.stop();
              await _processQrCode(raw);
              await Future.delayed(const Duration(seconds: 2));
              _isProcessing = false;
              await _scannerController.start();
            },
          ),
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.black54,
              child: Text(
                "hasRental: $hasRental\nrental_id: ${rentalIdDebug ?? '(null)'}",
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.78,
              height: MediaQuery.of(context).size.width * 0.58,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF28BCEF), width: 3),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, spreadRadius: 1)],
              ),
            ),
          ),
          if (_qrResult != null)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.22,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  "QR Detectado: $_qrResult",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    backgroundColor: Colors.black54,
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 130,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.assignment_return, size: 28),
                  label: const Text("Ir a devolución"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF004D63),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  ),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ReturnPage(userPosition: widget.userPosition)),
                    );
                    if (result == "returned") {
                      _showSnack("Sombrilla devuelta exitosamente", Colors.green);
                    }
                    await Future.delayed(const Duration(milliseconds: 300));
                    await _checkActiveRental();
                    setState(() {
                      _qrResult = null;
                      _isProcessing = false;
                    });
                  },
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.nfc, size: 28),
                  label: const Text("Rentar con NFC"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF004D63),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  ),
                  onPressed: _startNfcRental,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        color: const Color(0xFF90E0EF),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: IconButton(
                icon: const Icon(Icons.home, color: Colors.black),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const HomePage()));
                },
              ),
            ),
            const SizedBox(width: 48),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.black),
                  onPressed: () => Scaffold.of(context).openEndDrawer(),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: SizedBox(
        width: 76,
        height: 76,
        child: FloatingActionButton(
          backgroundColor: Colors.transparent,
          elevation: 6,
          shape: const CircleBorder(),
          onPressed: _switchToQr,
          child: Image.asset(
            'assets/images/home_button.png',
            width: 100,
            height: 100,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
