import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'menu.dart';
import 'home.dart';
import 'notifications.dart';
import 'profile.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api.dart';
import '../models/gps_coord.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/platform_tags.dart';
import 'dart:typed_data';


class ReturnPage extends StatefulWidget {
  final GpsCoord userPosition;

  const ReturnPage({
    super.key,
    required this.userPosition,
  });

  @override
  State<ReturnPage> createState() => _ReturnPageState();
}

class _ReturnPageState extends State<ReturnPage> {
  final Api api = Api();
  final storage = const FlutterSecureStorage();
  final MobileScannerController _scannerController = MobileScannerController();

  bool _isProcessing = false;
  bool _endedSuccessfully = false;
  String? rentalIdDebug;

  @override
  void initState() {
    super.initState();
    _checkRentalDebug();
  }

  Future<void> _checkRentalDebug() async {
    final rentalId = await storage.read(key: "rental_id");
    if (!mounted) return;
    setState(() => rentalIdDebug = rentalId);

  }

  /// Finaliza correctamente y regresa al home
  Future<void> _finishAndExit(String message, Color color) async {
  // Primero borra la renta y espera confirmación
  await storage.delete(key: "rental_id");
  await Future.delayed(const Duration(milliseconds: 200));

  // Detiene el escáner y actualiza estado
  await _scannerController.stop();
  setState(() {
    _endedSuccessfully = true;
    rentalIdDebug = null;
  });

  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: color,
      duration: const Duration(seconds: 1),
    ),
  );

  await Future.delayed(const Duration(milliseconds: 300));
  Navigator.pop(context, "returned"); 
}

  Future<void> _startNfcReturn() async {
    await _scannerController.stop();


    await NfcManager.instance.stopSession();
    await Future.delayed(const Duration(milliseconds: 200));

    NfcManager.instance.startSession(
      pollingOptions: {NfcPollingOption.iso14443},
      onDiscovered: (NfcTag tag) async {
        //  UID fijo (no leído del tag)
        const uid = "08:F8:93:B2";

        // ID de estación fija (la misma que usas en rent)
        const fixedStationId = "acadc4ef-f5b3-4ab8-9ab5-58f1161f0799";

        // Obtiene usuario actual
        final userId = await storage.read(key: "user_id");
        final api = Api();



        //  Llama directamente al backend
        await api.endRental(
          userId: userId!,
          stationEndId: fixedStationId,
        );

        // Limpia el rental guardado
        await storage.delete(key: "rental_id");

        setState(() {
          rentalIdDebug = null;
        });



        await NfcManager.instance.stopSession();

        if (mounted) {
          Navigator.pop(context, "returned");
        }
      },
    );
  }


  Future<void> _processQrCode(String code) async {
    try {
      final data = jsonDecode(code);
      final stationId = data["station_id"]?.toString();

      if (stationId == null || stationId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("QR inválido: falta station_id"),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 1),
          ),
        );
        return;
      }

      final userId = await storage.read(key: "user_id");
      if (userId == null || userId.isEmpty) {
        print("[ERROR] Usuario no encontrado en storage");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Usuario no encontrado"),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 1),
          ),
        );
        return;
      }


      await api.endRental(
        userId: userId,
        stationEndId: stationId,
      );

      await _finishAndExit("Sombrilla devuelta exitosamente", Colors.green);
    } catch (e) {
      final msg = e.toString();


      if (msg.contains("No active rental found")) {
        await _finishAndExit("☂️ No tenías ninguna sombrilla activa", Colors.orange);
        return;
      }



      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al procesar devolución: $e"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF90E0EF),
        centerTitle: true,
        foregroundColor: Colors.black,
        title: Text(
          'Devolver sombrilla',
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

      endDrawer: AppDrawer(),

      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            fit: BoxFit.cover,
            onDetect: (capture) async {
              if (_isProcessing || _endedSuccessfully) return;

              final raw = capture.barcodes.isNotEmpty
                  ? capture.barcodes.first.rawValue
                  : null;

              if (raw == null) return;

              _isProcessing = true;
              await _scannerController.stop();

              await _processQrCode(raw);

              if (!_endedSuccessfully) {
                await Future.delayed(const Duration(seconds: 3));
                _isProcessing = false;
                await _scannerController.start();
              }
            },
          ),

          // Debug del estado
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.black54,
              child: Text(
                "🔹 rental_id: ${rentalIdDebug ?? '(null)'}",
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),

          // Cuadro del escáner
          Align(
            alignment: Alignment.center,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.78,
              height: MediaQuery.of(context).size.width * 0.58,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF28BCEF), width: 3),
              ),
            ),
          ),

          // Botón para guiar al usuario
          Positioned(
            bottom: 130,
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.assignment_return, size: 32),
                    label: const Text(
                      '✅ Escanea para devolver',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF004D63),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: const StadiumBorder(),
                      elevation: 8,
                      shadowColor: Colors.black26,
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("📷 Escanea el QR de la estación para devolver"),
                          backgroundColor: Colors.orange,
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  ElevatedButton.icon(
                    icon: const Icon(Icons.nfc, size: 32),
                    label: const Text(
                      '📡 Devolver con NFC',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF004D63),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: const StadiumBorder(),
                      elevation: 8,
                      shadowColor: Colors.black26,
                    ),
                    onPressed: _startNfcReturn,
                  ),
                ],
              ),
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
            IconButton(
              icon: const Icon(Icons.home, color: Colors.black),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage()),
                );
              },
            ),
            const SizedBox(width: 48),
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.black),
                onPressed: () {
                  Scaffold.of(context).openEndDrawer();
                },
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.transparent,
        elevation: 6,
        shape: const CircleBorder(),
        onPressed: () {},
        child: Image.asset(
          'assets/images/home_button.png',
          width: 100,
          height: 100,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
