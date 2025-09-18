import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'theme.dart'; // usa tus colores de AppThem

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Centro aproximado Uniandes
    final center = LatLng(4.6022, -74.0665);

    // Mock de estaciones
    final stations = [
      _Station('ML-2', 'Edificio ML piso 2', 4.6019, -74.0665, 6, 12, 2),
      _Station('W-1',  'Edificio W piso 1',  4.6027, -74.0669, 3, 10, 4),
      _Station('B-2',  'Edificio B piso 2',  4.6031, -74.0658, 9, 13, 6),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        // si prefieres sin título y sólo los íconos, usa toolbarHeight y quita title
      ),
      body: Stack(
        children: [
          // MAPA
          FlutterMap(
            options: MapOptions(initialCenter: center, initialZoom: 17),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              ),
              MarkerLayer(
                markers: [
                  for (final s in stations)
                    Marker(
                      width: 44,
                      height: 60,
                      point: LatLng(s.lat, s.lng),
                      child: _Pin(count: s.umbrellas),
                    ),
                ],
              ),
            ],
          ),

          // Botones redondos arriba a la derecha (campana / perfil)
          Positioned(
            top: 12,
            right: 12,
            child: Row(
              children: [
                _RoundIcon(
                  icon: Icons.notifications_none,
                  onTap: () {},
                ),
                const SizedBox(width: 8),
                _RoundIcon(
                  icon: Icons.person_outline,
                  onTap: () {},
                ),
              ],
            ),
          ),

          // Botones flotantes laterales (mi ubicación / lista)
          Positioned(
            right: 16,
            bottom: 110,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'locate',
                  onPressed: () {/* centrar en usuario (luego) */},
                  child: const Icon(Icons.my_location),
                ),
                const SizedBox(height: 10),
                FloatingActionButton.small(
                  heroTag: 'list',
                  backgroundColor: AppThem.accent,
                  onPressed: () {/* Navigator.pushNamed(context, '/stations'); */},
                  child: const Icon(Icons.list),
                ),
              ],
            ),
          ),
        ],
      ),

      // FAB rojo centrado (Rentar / QR)
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppThem.accent,
        onPressed: () {/* Navigator.pushNamed(context, '/rent'); */},
        child: const Icon(Icons.qr_code_scanner),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // Bottom bar con notch
      bottomNavigationBar: const _BottomBar(currentIndex: 0),
    );
  }
}

/// ---- Widgets de apoyo ----

class _Pin extends StatelessWidget {
  final int count; // sombrillas disponibles
  const _Pin({required this.count});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppThem.primaryColor, width: 1),
            boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black12)],
          ),
          child: Text(
            '☂ $count',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        const Icon(Icons.location_on, color: AppThem.primaryColor, size: 34),
      ],
    );
  }
}

class _RoundIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: AppThem.primaryColor),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int currentIndex;
  const _BottomBar({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: const [
          Padding(
            padding: EdgeInsets.all(14),
            child: Icon(Icons.home),
          ),
          SizedBox(width: 48), // espacio para el notch del FAB
          Padding(
            padding: EdgeInsets.all(14),
            child: Icon(Icons.menu), // reemplaza por el que necesites
          ),
        ],
      ),
    );
  }
}

/// Modelo ligero sólo para esta pantalla
class _Station {
  final String code, name;
  final double lat, lng;
  final int umbrellas, docks, minutes;
  _Station(this.code, this.name, this.lat, this.lng, this.umbrellas, this.docks, this.minutes);
}
