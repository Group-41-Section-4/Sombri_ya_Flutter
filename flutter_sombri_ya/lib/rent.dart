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

import '../return.dart';

// Strategy Imports
import '../strategies/nfc_rent_strategy.dart';
import '../strategies/qr_rent_strategy.dart';
import '../strategies/rent_strategy.dart';

import '../services/api.dart';
import '../models/gps_coord.dart';
import 'models/rental_model.dart';

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
  String? _lastCode;
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

  Future<void> _switchToNfc() async {
    setState(() {
      _rentContext.strategy = NfcRentStrategy();
    });
    await _rentContext.rent();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Renta por NFC ejecutada ✅"),
        backgroundColor: Colors.green,
        duration: const Duration(seconds:1)
      ),
    );
  }

  Future<void> _processQrCode(String code) async {
    try {
      final data = jsonDecode(code);
      final stationId = data["station_id"].toString();

      final existingRental = await storage.read(key: "rental_id");
      if (existingRental != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("⚠️ Ya tienes una sombrilla rentada"),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds:1)
          ),
        );
        return;
      }

      final userId = await storage.read(key: "user_id");
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Usuario no encontrado"),
          duration: const Duration(seconds:1)),
          
        );
        return;
      }

      final rental = await api.startRental(
        userId: userId,
        stationStartId: stationId,
        authType: "qr",
      );

      // Debug
      print("📦 startRental -> rental.id='${rental.id}'");

      // Fallback si rental.id no llega
      String? rentalIdToSave = rental.id.isNotEmpty ? rental.id : null;
      if (rentalIdToSave == null) {
        final active = await api.getActiveRental(userId);
        rentalIdToSave = active?.id;
        print(
          "🔁 Fallback getActiveRental -> id='${rentalIdToSave ?? '(null)'}'",
        );
      }

      if (rentalIdToSave == null || rentalIdToSave.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("⚠️ No pude obtener el ID de la renta 😕"),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds:1)
          ),
        );
        return;
      }

      // Guardar y actualizar UI
      await storage.write(key: "rental_id", value: rentalIdToSave);
      setState(() {
        hasRental = true;
        rentalIdDebug = rentalIdToSave;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("🌂 Sombrilla rentada con éxito\nID: $rentalIdToSave"),
          backgroundColor: Colors.green,
          duration: const Duration(seconds:1)
        ),
      );
    } catch (e) {
      print("❌ Error en _processQrCode: $e");

      String message = e.toString();
      if (message.contains("User already has an active rental")) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("⚠️ Ya tienes una sombrilla activa ☂️"),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds:1)
          ),
        );
      } else if (message.contains("No active rental found")) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("❌ No tienes una renta activa"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds:1)
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Error al iniciar la renta: $message"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds:1)
          ),
        );
      }
    }
  }
/*
  Future<void> _processNfcTag(String tagUid, String tagType) async {
    try {
      // 🚫 Verificar si ya hay una sombrilla rentada
      final existingRental = await storage.read(key: "rental_id");
      if (existingRental != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("⚠️ Ya tienes una sombrilla rentada"),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // 🧍 Obtener el usuario actual
      final userId = await storage.read(key: "user_id");
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Usuario no encontrado")),
        );
        return;
      }

      // 🛰️ Obtener estación asociada al tag NFC (consulta al backend)
      final station = await api.getStationByTag(tagUid);
      if (station == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("❌ Estación no encontrada para esta tarjeta NFC"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final stationId = station.id;

      // 🚀 Iniciar renta
      final rental = await api.startRental(
        userId: userId,
        stationStartId: stationId,
        authType: "nfc",
      );

      print("📦 startRental(NFC) -> rental.id='${rental.id}'");

      // 🧩 Fallback si no llega el ID
      String? rentalIdToSave = rental.id.isNotEmpty ? rental.id : null;
      if (rentalIdToSave == null) {
        final active = await api.getActiveRental(userId);
        rentalIdToSave = active?.id;
        print("🔁 Fallback getActiveRental -> id='${rentalIdToSave ?? '(null)'}'");
      }

      if (rentalIdToSave == null || rentalIdToSave.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("⚠️ No pude obtener el ID de la renta 😕"),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // 💾 Guardar en almacenamiento local
      await storage.write(key: "rental_id", value: rentalIdToSave);
      setState(() {
        hasRental = true;
        rentalIdDebug = rentalIdToSave;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("🌂 Sombrilla rentada con NFC con éxito\nID: $rentalIdToSave"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print("❌ Error en _processNfcTag: $e");
      final message = e.toString();

      if (message.contains("User already has an active rental")) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("⚠️ Ya tienes una sombrilla activa ☂️"),
            backgroundColor: Colors.orange,
          ),
        );
      } else if (message.contains("No active rental found")) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("❌ No tienes una renta activa"),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Error al iniciar la renta: $message"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

 */


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
              MaterialPageRoute(
                builder: (context) => const NotificationsPage(),
              ),
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

      endDrawer:  AppDrawer(),

      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            fit: BoxFit.cover,
            onDetect: (capture) async {
              final raw = capture.barcodes.isNotEmpty
                  ? capture.barcodes.first.rawValue
                  : null;
              if (raw == null) return;

              if (_isProcessing) return;
              _isProcessing = true;

              await _scannerController.stop();
              await _processQrCode(raw);

              await Future.delayed(const Duration(seconds: 2));
              _isProcessing = false;
              await _scannerController.start();
            },
          ),

          // Debug info
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

          // Scanner square
          Align(
            alignment: Alignment.center,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.78,
              height: MediaQuery.of(context).size.width * 0.58,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF28BCEF), width: 3),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),

          // QR detectado
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

          // Botones
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  ),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ReturnPage(userPosition: widget.userPosition),
                      ),
                    );
                    if (result == "returned") {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("🌞 Sombrilla devuelta exitosamente"),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }

                    await Future.delayed(const Duration(milliseconds: 300));
                    await _checkActiveRental();

                    setState(() {
                      _qrResult= null;
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  ),
                  onPressed: _switchToNfc,
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HomePage()),
                  );
                },
              ),
            ),
            const SizedBox(width: 48),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.black),
                  onPressed: () {
                    Scaffold.of(context).openEndDrawer();
                  },
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
