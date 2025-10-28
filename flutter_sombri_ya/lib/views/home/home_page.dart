import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../config/openweather_config.dart';
import '../../presentation/blocs/home/home_bloc.dart';
import '../../presentation/blocs/home/home_event.dart';
import '../../presentation/blocs/home/home_state.dart';

import '../../services/weather_service.dart';
import '../../widgets/app_drawer.dart';
import '../../data/models/gps_coord.dart';
import '../../data/models/station_model.dart';

import '../notifications/notifications_page.dart';
import '../../presentation/blocs/notifications/notifications_bloc.dart';
import '../../presentation/blocs/notifications/notifications_event.dart';

import '../profile/profile_page.dart';
import '../../data/repositories/profile_repository.dart';

import '../../presentation/blocs/weather/weather_cubit.dart';
import '../../data/models/weather_models.dart';
import '../../widgets/weather_icon.dart';

import '../rent/rent_page.dart';
import '../return/return_page.dart';
import '../../presentation/blocs/rent/rent_bloc.dart';
import '../../presentation/blocs/return/return_bloc.dart';
import '../../presentation/blocs/rent/rent_event.dart';
import '../../presentation/blocs/return/return_event.dart';
import '../../data/repositories/rental_repository.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => HomeBloc()),
        BlocProvider(
          create: (_) => WeatherCubit(
            weather: WeatherService(apiKey: OpenWeatherConfig.apiKey),
          )..start(every: const Duration(minutes: 10)),
        ),
      ],
      child: const HomeView(),
    );
  }
}

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with WidgetsBindingObserver {
  GoogleMapController? _mapController;
  BitmapDescriptor? _stationIcon;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCustomMarkerIcon().then((_) {
      if (mounted) {
        context.read<HomeBloc>().add(InitializeHome(stationIcon: _stationIcon));
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<HomeBloc>().add(RefreshHome(stationIcon: _stationIcon));
    }
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

  void _showEnableLocationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Ubicación Desactivada'),
        content: const Text(
          'Para mostrar las estaciones cercanas, por favor activa los servicios de ubicación de tu dispositivo.',
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Activar Ubicación'),
            onPressed: () {
              Geolocator.openLocationSettings();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BlocListener<WeatherCubit, SimpleWeather?>(
      listenWhen: (prev, curr) =>
      prev?.condition != curr?.condition || prev?.isNight != curr?.isNight,
      listener: (context, w) {
        final cond = w?.condition.name ?? 'unknown';
        final night = (w?.isNight ?? false) ? 'night' : 'day';
        debugPrint('[Weather] condition=$cond isNight=$night');
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          centerTitle: true,

          title: Text(
            '',
            style: GoogleFonts.robotoSlab(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: scheme.onPrimary,
              letterSpacing: 0.3,
            ),
          ),
          leading: Builder(
            builder: (ctx) => IconButton(
              tooltip: 'Notificaciones',
              icon: Icon(Icons.notifications_none, color: scheme.onPrimary),
              onPressed: () async {
                debugPrint('[Home] Tap notifications');
                final storage = const FlutterSecureStorage();
                final userId = await storage.read(key: 'user_id');

                if (!ctx.mounted) return;

                if (userId == null || userId.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('No se pudo identificar al usuario.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.of(ctx, rootNavigator: true).push(
                  MaterialPageRoute(
                    builder: (_) => BlocProvider(
                      create: (_) => NotificationsBloc()
                        ..add(StartRentalPolling(userId))
                        ..add(const CheckWeather()),
                      child: const NotificationsPage(),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            Builder(
              builder: (ctx) => IconButton(
                tooltip: 'Perfil',
                onPressed: () {
                  debugPrint('[Home] Tap perfil');
                  Navigator.of(ctx, rootNavigator: true).push(
                    MaterialPageRoute(builder: (_) => const ProfilePage()),
                  );
                },
                icon: const CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.black,
                  backgroundImage: AssetImage('assets/images/profile.png'),
                ),
              ),
            ),
          ],
        ),
        endDrawer: AppDrawer(),
        body: BlocConsumer<HomeBloc, HomeState>(
          listenWhen: (prev, current) =>
          prev.locationError != current.locationError ||
              (prev.cameraTarget != current.cameraTarget &&
                  current.cameraTarget != null),
          listener: (context, state) {
            if (state.locationError == 'disabled') {
              _showEnableLocationDialog();
            }
            if (state.cameraTarget != null) {
              _mapController?.animateCamera(
                CameraUpdate.newLatLngZoom(
                  state.cameraTarget!,
                  state.cameraZoom,
                ),
              );
            }
          },
          builder: (context, state) {
            return Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: state.cameraTarget ??
                        const LatLng(4.603083, -74.065130),
                    zoom: state.cameraZoom,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  markers: state.markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  mapToolbarEnabled: false,
                  zoomControlsEnabled: false,
                ),
                if (state.isLoading)
                  const Center(child: CircularProgressIndicator()),


            Positioned(
              top: 12,
              left: 12,
              child: SafeArea(
              child: IgnorePointer(
              ignoring: true,
              child: Material(
              shape: const CircleBorder(),
              elevation: 6,
              color: Color(0xFFD1D5DB),
                  child: Padding(
                      padding: const EdgeInsets.all(6),
                        child: BlocBuilder<WeatherCubit, SimpleWeather?>(
                          builder: (context, w) => WeatherIcon(
                            condition: w?.condition ?? WeatherCondition.unknown,
                          isNight: w?.isNight ?? false,
                          size: 30,
                          ),
                        ),
                      ),
                    ),
                ),
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
                          builder: (_) =>
                              EstacionesSheet(stations: state.nearbyStations),
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
            );
          },
        ),
        floatingActionButton: SizedBox(
          width: 76,
          height: 76,
          child: FloatingActionButton(
            backgroundColor: Colors.transparent,
            elevation: 6,
            shape: const CircleBorder(),
            onPressed: () async {
              final userPosition =
                  context.read<HomeBloc>().state.userPosition;
              if (userPosition == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Esperando tu ubicación...')),
                );
                return;
              }

              final storage = const FlutterSecureStorage();
              final rentalId = await storage.read(key: 'rental_id');

              if (rentalId != null && rentalId.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MultiRepositoryProvider(
                      providers: [
                        RepositoryProvider(
                          create: (_) => RentalRepository(
                            storage: const FlutterSecureStorage(),
                          ),
                        ),
                        RepositoryProvider(create: (_) => ProfileRepository()),
                      ],
                      child: BlocProvider(
                        create: (ctx) => ReturnBloc(
                          repo: RepositoryProvider.of<RentalRepository>(ctx),
                          profileRepo:
                          RepositoryProvider.of<ProfileRepository>(ctx),
                        )..add(const ReturnInit()),
                        child: ReturnPage(
                          userPosition: GpsCoord(
                            latitude: userPosition.latitude,
                            longitude: userPosition.longitude,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RepositoryProvider(
                      create: (_) => RentalRepository(
                        storage: const FlutterSecureStorage(),
                      ),
                      child: BlocProvider(
                        create: (ctx) => RentBloc(
                          repo: RepositoryProvider.of<RentalRepository>(ctx),
                        )..add(const RentInit()),
                        child: RentPage(
                          userPosition: GpsCoord(
                            latitude: userPosition.latitude,
                            longitude: userPosition.longitude,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }
            },
            child: Image.asset(
              'assets/images/home_button.png',
              width: 100,
              height: 100,
              fit: BoxFit.contain,
            ),
          ),
        ),
        floatingActionButtonLocation:
        FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          color: scheme.primary,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: IconButton(
                  icon: Icon(Icons.home, color: scheme.onPrimary),
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: 48),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Builder(
                  builder: (context) => IconButton(
                    icon: Icon(Icons.menu, color: scheme.onPrimary),
                    onPressed: () => Scaffold.of(context).openEndDrawer(),
                  ),
                ),
              ),
            ],
          ),
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
