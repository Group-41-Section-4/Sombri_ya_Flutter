import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'location_service.dart';
import 'menu.dart';
import 'notifications.dart';
import 'profile.dart';
import 'rent.dart';
import 'package:google_fonts/google_fonts.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final LocationService _locationService = LocationService();
  GoogleMapController? _mapController;
  LatLng _initialPosition = const LatLng(4.603083745590484, -74.06513067239409);
  Marker? _userLocationMarker;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _setUserLocation();
  }

  Future<void> _setUserLocation() async {
    try {
      final position = await _locationService.getCurrentLocation();
      setState(() {
        _initialPosition = position;
        _userLocationMarker = Marker(
          markerId: const MarkerId('userLocation'),
          position: _initialPosition,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: const InfoWindow(title: 'Tu Ubicación'),
        );
        _isLoading = false;
      });
      _mapController?.animateCamera(CameraUpdate.newLatLng(_initialPosition));
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF90E0EF),
        foregroundColor: Colors.black,
        centerTitle: true,
        title: Text(
          '',
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
              backgroundColor: Colors.black,
              backgroundImage: AssetImage('assets/images/profile.png'),
            ),
          ),
        ],
      ),

      endDrawer: const AppDrawer(),

      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _initialPosition,
              zoom: 16,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
            },
            markers: _userLocationMarker != null ? {_userLocationMarker!} : {},
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            mapToolbarEnabled: false,
            zoomControlsEnabled: false,
          ),

          if (_isLoading) const Center(child: CircularProgressIndicator()),

          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF005E7C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 6,
                ),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const EstacionesSheet(),
                  );
                },
                child: Text(
                  'ESTACIONES',
                  style: GoogleFonts.robotoSlab(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          // Positioned(
          //   top: 60,
          //   left: 130,
          //   child: Image.asset('assets/images/pin.png', width: 60, height: 60),
          // ),
          // Positioned(
          //   top: 350,
          //   left: 150,
          //   child: Image.asset('assets/images/pin.png', width: 60, height: 60),
          // ),
        ],
      ),
      floatingActionButton: SizedBox(
        width: 76,
        height: 76,
        child: FloatingActionButton(
          backgroundColor: Colors.transparent,
          elevation: 6,
          shape: const CircleBorder(),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RentPage()),
            );
          },
          child: Image.asset(
            'assets/images/home_button.png',
            width: 100,
            height: 100,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
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
                onPressed: () {},
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
    );
  }
}

class EstacionesSheet extends StatelessWidget {
  const EstacionesSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.3,
      minChildSize: 0.2,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                "Estaciones cercanas",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              _buildEstacionCard(
                "ML - 2",
                "Edificio ML piso 2",
                "4 min",
                "200 mts",
                5,
                2,
              ),
              _buildEstacionCard(
                "W - 1",
                "Edificio W piso 1",
                "6 min",
                "300 mts",
                5,
                2,
              ),
              _buildEstacionCard(
                "B - 2",
                "Edificio B piso 2",
                "8 min",
                "400 mts",
                5,
                2,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEstacionCard(
    String titulo,
    String direccion,
    String tiempo,
    String distancia,
    int disponibles,
    int ocupadas,
  ) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset('assets/images/pin.png', width: 50, height: 50),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),

                  Row(
                    children: [
                      Image.asset(
                        'assets/images/umbrella_available.png',
                        width: 20,
                        height: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "$disponibles",
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Image.asset(
                        'assets/images/no_umbrella.png',
                        width: 20,
                        height: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "$ocupadas",
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),
                  Text(direccion, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(width: 0),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(tiempo, style: const TextStyle(color: Colors.green)),
                Text(distancia, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
