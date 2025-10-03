import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'menu.dart';
import 'home.dart';
import 'notifications.dart';
import 'profile.dart';
import 'package:google_fonts/google_fonts.dart';

//Strategy Imports
import '../strategies/nfc_rent_strategy.dart';
import '../strategies/rent_strategy.dart';

class RentPage extends StatefulWidget {
  const RentPage({super.key});

  @override
  State<RentPage> createState() => _RentPageState();
}

class _RentPageState extends State<RentPage> {
  late RentContext _rentContext;
  String? _qrResult;

  bool _hasScanned = false;

  @override
  void initState() {
    super.initState();
    // TODO: cambiar de NFC a QR  
    _hasScanned = false;
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

  void _switchToQr() {
    setState(() {
      //TODO: Implementar QRRentStrategy
      _rentContext.strategy = QrRentStrategy(
        onCodeScanned: (code) {
          setState(() {
            _qrResult = code;    
          });
          debugPrint("Procesando renta con QR: $code");
        },
      );
      //_rentContext.strategy = QrRentStrategy();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar (same as Home)
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

      endDrawer: const AppDrawer(),
      // QR Scanner Body or NFC Activation
      body: Stack(
        children: [
          MobileScanner(
            fit: BoxFit.cover,
            onDetect: (capture) {
              if (!_hasScanned) {
                _hasScanned = true;

                final barcodes = capture.barcodes;

                if (barcodes.isNotEmpty) {
                  final code = barcodes.first.rawValue;
                  if (code != null) {
                    setState(() {
                      _qrResult = code;
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Sombrilla rentada con QR: $code")),
                    );

                    debugPrint("Código QR detectado: $code");

                    Future.delayed(const Duration(seconds: 3), () {
                      if (mounted) {
                        setState(() {
                          _qrResult = null;
                        });
                      }
                    });
                  }
                }
              }
            },
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

          //Show QR Result
          if(_qrResult != null)
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

          // Activate NFC button
          Positioned(
            bottom: 130,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.contactless, size: 32),
                label: const Text(
                  'Activar NFC',
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

      // Bottom Navigation Bar
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        color: const Color(0xFF90E0EF),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            //  Home button
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

            const SizedBox(width: 48), // espacio para el notch del FAB
            // Botón Menú
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

      // Floating Action Button (Home)
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
