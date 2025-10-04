import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'menu.dart';
import 'home.dart';
import 'notifications.dart';
import 'profile.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../return.dart';

//Strategy Imports
import '../strategies/nfc_rent_strategy.dart';
import '../strategies/qr_rent_strategy.dart';
import '../strategies/rent_strategy.dart';

import '../services/api.dart';
import '../models/gps_coord.dart';
import '../models/rental.dart';

class RentPage extends StatefulWidget {
  final GpsCoord userPosition;

  const RentPage({
    super.key,
    required this.userPosition,
  });

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

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Renta por NFC ejecutado")));
  }

  Future<void> _processQrCode(String code) async {
    try {
      final data = jsonDecode(code);
      final stationId = data["station_id"];

      final existingRental = await storage.read(key: "rental_id");
      if (existingRental != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Ya tienes una renta activa")),
        );
        return;
      }

      final userId = await storage.read(key: "user_id");
      final token = await storage.read(key: "auth_token");

      final rental = await api.startRental(
        userId: userId!,
        stationStartId: stationId,
        startGps: widget.userPosition,
        authType: "qr",
      );

      // 🔍 Debug
      print("📦 startRental -> rental.id='${rental.id}'");

      // 🛡️ Si no vino el id en la respuesta (por mapeo/serialización), buscamos la renta activa
      String? rentalIdToSave = rental.id.isNotEmpty ? rental.id : null;
      if (rentalIdToSave == null) {
        final active = await api.getActiveRental(userId);
        rentalIdToSave = active?.id;
        print("🔁 Fallback getActiveRental -> id='${rentalIdToSave ?? '(null)'}'");
      } 

      if (rentalIdToSave == null || rentalIdToSave.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No pude obtener el ID de la renta 😕")),
        );
        return;
      }

      // 💾 Guardar y actualizar UI
      await storage.write(key: "rental_id", value: rentalIdToSave);
      setState(() => hasRental = true);


      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Renta iniciada: ${rentalIdToSave}")),
      );
    } catch (e, stack) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al procesar QR")),
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

                // Bloquear mientras procesas una devolución
                if (_isProcessing) return;
                _isProcessing = true;

                await _scannerController.stop();

                await _processQrCode(raw);

                // 🔁 Permitir nueva devolución del mismo código tras 2 segundos
                await Future.delayed(const Duration(seconds: 2));
                _isProcessing = false;
                await _scannerController.start();
              }

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

          // Mostrar el resultado del QR
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

          // Botón para activar NFC
          Positioned(
            bottom: 130,
            left: 0,
            right: 0,
            child: Center(
              child: hasRental ? ElevatedButton.icon(
                icon: const Icon(Icons.assignment_return, size: 32),
                label: const Text(
                  'Ir a devolución',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF004D63),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: StadiumBorder(
                    side: BorderSide(color: const Color(0xFF004D63)),
                  ),
                  elevation: 8,
                  shadowColor: Colors.black26,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReturnPage(userPosition: widget.userPosition),
                    ),
                  ).then((_) {
                    _checkActiveRental();
                  });
                },
              )
              : ElevatedButton.icon(
                icon: const Icon(Icons.nfc, size: 32),
                label: const Text(
                  'Activar por NFC',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF004D63),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: StadiumBorder(
                    side: BorderSide(color: const Color(0xFF004D63)),
                  ),
                  elevation: 8,
                  shadowColor: Colors.black26,
                ),
                onPressed: _switchToNfc,
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
          onPressed: (_switchToQr),
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
