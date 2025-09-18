import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ───────── BARRA SUPERIOR ─────────
      appBar: AppBar(
        backgroundColor: const Color(0xFF28BCEF),
        foregroundColor: Colors.white,
        title: const Text('Home'),
        leading: IconButton(
          icon: const Icon(Icons.notifications_none),
          onPressed: () {},
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white24,
              backgroundImage: AssetImage('assets/images/profile.png'),
            ),
          ),
        ],
      ),

      // ───────── CUERPO (MAPA + BOTÓN ESTACIONES) ─────────
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/map.png',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.low,
              cacheWidth: 1080,
            ),
          ),
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF005E7C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 6,
                ),
                onPressed: () {},
                child: const Text(
                  'ESTACIONES',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
              ),
            ),
          ),
        ],
      ),

      // ───────── FAB ROJO CENTRADO (ASSET) ─────────
      floatingActionButton: SizedBox(
        width: 76,
        height: 76,
        child: FloatingActionButton(
          backgroundColor: Colors.white, // fondo transparente para el PNG
          elevation: 6,
          onPressed: () {},
          child: Image.asset(
            'assets/images/home_button.png',
            width: 48,
            height: 48,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // ───────── BOTTOM APP BAR AZUL ─────────
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        elevation: 10,
        color: const Color(0xFF28BCEF),
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Izquierda: Mapa
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.map_outlined, color: Colors.white),
                  SizedBox(height: 4),
                  Text(
                    "Mapa",
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(width: 48), // espacio para el notch
              // Derecha: Más
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.more_horiz, color: Colors.white),
                  SizedBox(height: 4),
                  Text(
                    "Más",
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
