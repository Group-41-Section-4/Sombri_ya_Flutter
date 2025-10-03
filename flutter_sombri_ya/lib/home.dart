import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'location_service.dart' hide LocationServiceDisabledException;
import 'service_adapters/stations_service.dart';
import 'models/station_model.dart';
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

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final LocationService _locationService = LocationService();
  final StationsService _stationsService = StationsService();

  GoogleMapController? _mapController;
  LatLng _initialPosition = const LatLng(4.603083745590484, -74.06513067239409);
  bool _isLoading = true;

  Set<Marker> _markers = {};

  List<Station> _nearbyStations = [];
  BitmapDescriptor? _stationIcon;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCustomMarkerIcon();
    _initializeMap();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadCustomMarkerIcon() async {
    final icon = await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/images/pin.png',
    );
    setState(() {
      _stationIcon = icon;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _initializeMap();
    }
  }

  Future<void> _initializeMap() async {
    try {
      final userPosition = await _locationService.getCurrentLocation();
      if (!mounted) {
        return;
      }

      setState(() {
        _initialPosition = userPosition;
        _isLoading = false;
        _updateMarkers(userPosition, []);
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_initialPosition, 16),
      );

      _fetchNearbyStations(userPosition);
    } on LocationServiceDisabledException {
      _showEnableLocationDialog();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchNearbyStations(LatLng location) async {
    try {
      final stations = await _stationsService.findNearbyStations(location);
      if (!mounted) {
        return;
      }

      setState(() {
        _nearbyStations = stations;
      });
      _updateMarkers(_initialPosition, stations);
    } catch (e) {
      print("Error: $e");
    }
  }

  void _updateMarkers(LatLng userPosition, List<Station> stations) {
    final Set<Marker> markers = {};
    markers.add(
      Marker(
        markerId: const MarkerId('userLocation'),
        position: userPosition,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'Tu Ubicación'),
      ),
    );

    for (final station in stations) {
      markers.add(
        Marker(
          markerId: MarkerId(station.id),
          position: LatLng(station.latitude, station.longitude),
          icon: _stationIcon ?? BitmapDescriptor.defaultMarker,
          infoWindow: InfoWindow(
            title: station.placeName,
            snippet: '${station.availableUmbrellas} sombrillas disponibles',
          ),
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  void _showEnableLocationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ubicación Desactivada'),
          content: const Text(
            'Para mostrar las estaciones cercanas, por favor activa los servicios de ubicación de tu dispositivo.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Activar Ubicación'),
              onPressed: () {
                Geolocator.openLocationSettings();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
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
            markers: _markers,
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
                    builder: (context) =>
                        EstacionesSheet(stations: _nearbyStations),
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
  final List<Station> stations;
  const EstacionesSheet({super.key, required this.stations});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.2,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const Text(
                "Estaciones cercanas",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: stations.isEmpty
                    ? const Center(
                        child: Text("No se encontraron estaciones cercanas."),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: stations.length,
                        itemBuilder: (context, index) {
                          final station = stations[index];
                          final occupiedUmbrellas =
                              station.totalUmbrellas -
                              station.availableUmbrellas;
                          return _buildEstacionCard(
                            station.placeName,
                            station.description,
                            "",
                            "${station.distanceMeters} mts",
                            station.availableUmbrellas,
                            occupiedUmbrellas,
                          );
                        },
                      ),
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
