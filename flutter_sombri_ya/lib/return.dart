import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'menu.dart';
import 'home.dart';
import 'views/notifications/notifications_page.dart';
import 'profile.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api.dart';
import 'data/models/gps_coord.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/platform_tags.dart';
import 'dart:typed_data';

class ReturnPage extends StatefulWidget {
  final GpsCoord userPosition;

  const ReturnPage({super.key, required this.userPosition});

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
    try {
      await _scannerController.start();
    } catch (e) {
      debugPrint("Scanner already running: $e");
    }
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

    await Future.delayed(const Duration(seconds: 1));

    await storage.delete(key: "rental_id");
    print("[DEBUG] Storage limpiado antes de volver a RentPage");

    if (mounted) {
      Navigator.pop(context, "returned");
    }
  }

  Future<void> _startNfcReturn() async {
    await _scannerController.stop();

    await NfcManager.instance.stopSession();
    await Future.delayed(const Duration(milliseconds: 200));

    NfcManager.instance.startSession(
      pollingOptions: {NfcPollingOption.iso14443},
      onDiscovered: (NfcTag tag) async {
        try {
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
          if (id == null) {
            _showSnack("No se pudo leer el ID del tag NFC", Colors.red);
            await NfcManager.instance.stopSession();
            return;
          }
          final uid = id
              .map((b) => b.toRadixString(16).padLeft(2, '0'))
              .join(':')
              .toUpperCase();

          final userId = await storage.read(key: "user_id");

          if (userId == null) {
            _showSnack("Usuario no encontrado", Colors.red);
            await NfcManager.instance.stopSession();
            return;
          }

          final api = Api();
          final station = await api.getStationByTag(uid);
          if (station == null) {
            _showSnack("Estación no encontrada para este tag", Colors.red);
            await NfcManager.instance.stopSession();
            return;
          }
          await api.endRental(userId: userId, stationEndId: station.id);

          await storage.delete(key: "rental_id");
          await storage.deleteAll();

          setState(() {
            rentalIdDebug = null;
          });

          await Future.delayed(const Duration(milliseconds: 300));

          await NfcManager.instance.stopSession();

          if (mounted) {
            Navigator.pop(context, "returned");
          }
        } catch (e) {
          print("Error en devolución NFC: $e");
          _showSnack("Error en devolución NFC: $e", Colors.red);
        }
      },
    );
  }

  Future<void> _processQrCode(String code) async {
    try {
      final data = jsonDecode(code);
      final stationId = data["station_id"]?.toString();

      debugPrint("[DEBUG] Cídgo leído del QR: $code");
      debugPrint("[DEBUG] station_id extraído: $stationId");

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
      debugPrint("[DEBUG] user_id desde storage: $userId");

      await api.endRental(userId: userId!, stationEndId: stationId);

      debugPrint("[DEBUG] endRental called successfully");

      await _finishAndExit("Sombrilla devuelta exitosamente", Colors.green);
    } catch (e) {
      debugPrint("[DEBUG] Error durante la devolución: $e");
      _showSnack("Error al procesar devolución: $e", Colors.red);
    }
  }
  //   if (userId == null || userId.isEmpty) {
  //     print("[ERROR] Usuario no encontrado en storage");
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text("Usuario no encontrado"),
  //         backgroundColor: Colors.red,
  //         duration: Duration(seconds: 1),
  //       ),
  //     );
  //     return;
  //   }

  //   await api.endRental(userId: userId, stationEndId: stationId);

  //   await _finishAndExit("Sombrilla devuelta exitosamente", Colors.green);
  // } catch (e) {
  //   final msg = e.toString();

  //   if (msg.contains("No active rental found")) {
  //     await _finishAndExit(
  //       "No tenías ninguna sombrilla activa",
  //       Colors.orange,
  //     );
  //     return;
  //   }

  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: Text("Error al procesar devolución: $e"),
  //       backgroundColor: Colors.red,
  //       duration: const Duration(seconds: 1),
  //     ),
  //   );
  // }
  //}

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
          /*
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

           */

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

          const SizedBox(height: 50),

          // Botón para guiar al usuario
          Positioned(
            bottom: 70,
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Text(
                      'Apunta la cámara al QR para devolver',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.contactless, size: 20),
                    label: const Text('Devolver con NFC'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF004D63),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                      shape: const StadiumBorder(),
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

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }
}
