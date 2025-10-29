import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Config & Services
import '../../config/openweather_config.dart';
import '../../services/weather_service.dart';
import '../../core/services/pedometer_service.dart';

// BLoCs Home / Weather / Voice
import '../../data/repositories/profile_repository.dart';
import '../../presentation/blocs/home/home_bloc.dart';
import '../../presentation/blocs/home/home_event.dart';
import '../../presentation/blocs/home/home_state.dart';

import '../../presentation/blocs/weather/weather_cubit.dart';
import '../../data/models/weather_models.dart';
import '../../widgets/weather_icon.dart';
import '../../core/theme/weather_theme.dart';

import '../../core/services/voice_command_service.dart';
import '../../presentation/blocs/voice/voice_bloc.dart';
import '../../presentation/blocs/voice/voice_event.dart';
import '../../presentation/blocs/voice/voice_state.dart';
import '../../domain/voice/voice_intent.dart';

// Notifications
import '../notifications/notifications_page.dart';
import '../../presentation/blocs/notifications/notifications_bloc.dart';
import '../../presentation/blocs/notifications/notifications_event.dart';

// Rent / Return
import '../profile/profile_page.dart';
import '../rent/rent_page.dart';
import '../return/return_page.dart';
import '../../presentation/blocs/return/return_bloc.dart';
import '../../presentation/blocs/rent/rent_bloc.dart';
import '../../presentation/blocs/rent/rent_event.dart';
import '../../presentation/blocs/return/return_event.dart';
import '../../data/repositories/rental_repository.dart';

// Other UI
import '../../widgets/app_drawer.dart';
import '../../data/models/gps_coord.dart';
import '../../data/models/station_model.dart';

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
        BlocProvider(
          create: (_) =>
          VoiceBloc(VoiceCommandService())..add(const VoiceInitRequested()),
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
  final PedometerService _pedometer = PedometerService();

  SimpleWeather? _weatherForUI;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final w = context.read<WeatherCubit>().state;
      setState(() => _weatherForUI = w);
      context.read<WeatherCubit>().emitFromCachedForecastOrState();
    });

    _loadCustomMarkerIcon().then((_) {
      if (!mounted) return;
      context.read<HomeBloc>().add(InitializeHome(stationIcon: _stationIcon));
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
      context.read<WeatherCubit>().emitFromCachedForecastOrState();
    }
  }

  Future<void> _loadCustomMarkerIcon() async {
    final icon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/images/pin.png',
    );
    if (!mounted) return;
    setState(() => _stationIcon = icon);
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

  Future<void> _goToReturnIfActiveOrRentOtherwise() async {
    final userPosition = context.read<HomeBloc>().state.userPosition;
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
                create: (_) =>
                    RentalRepository(storage: const FlutterSecureStorage()),
              ),
              RepositoryProvider(create: (_) => ProfileRepository()),
            ],
            child: BlocProvider(
              create: (ctx) => ReturnBloc(
                repo: RepositoryProvider.of<RentalRepository>(ctx),
                profileRepo: RepositoryProvider.of<ProfileRepository>(ctx),
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
            create: (_) =>
                RentalRepository(storage: const FlutterSecureStorage()),
            child: BlocProvider(
              create: (ctx) =>
              RentBloc(repo: RepositoryProvider.of<RentalRepository>(ctx))
                ..add(const RentInit()),
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
  }

  Future<void> _goToReturnIfActiveElseSnack() async {
    final storage = const FlutterSecureStorage();
    final rentalId = await storage.read(key: 'rental_id');
    if (rentalId == null || rentalId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tienes una renta activa para devolver.'),
        ),
      );
      return;
    }
    await _goToReturnIfActiveOrRentOtherwise();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [

        BlocListener<WeatherCubit, SimpleWeather?>(
          listenWhen: (prev, curr) =>
          prev?.condition != curr?.condition || prev?.isNight != curr?.isNight,
          listener: (context, w) {
            if (!mounted) return;
            setState(() => _weatherForUI = w);
          },
        ),

        BlocListener<VoiceBloc, VoiceState>(
          listenWhen: (p, c) => p.intent != c.intent && c.intent != VoiceIntent.none,
          listener: (context, vstate) async {
            switch (vstate.intent) {
              case VoiceIntent.rentDefault:
              case VoiceIntent.rentQR:
              case VoiceIntent.rentNFC:
                await _goToReturnIfActiveOrRentOtherwise();
                break;
              case VoiceIntent.returnUmbrella:
                await _goToReturnIfActiveElseSnack();
                break;
              case VoiceIntent.none:
                break;
            }
            context.read<VoiceBloc>().add(const VoiceClearIntent());
          },
        ),
      ],
      child: Builder(
        builder: (context) {
          final w = _weatherForUI;
          final theme = themeFor(
            w?.condition ?? WeatherCondition.unknown,
            w?.isNight ?? false,
          );
          final scheme = theme.colorScheme;

          return Theme(
            data: theme,
            child: Scaffold(
              appBar: AppBar(
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
                centerTitle: true,
                // En el AppBar.title
                title: ValueListenableBuilder<bool>(
                  valueListenable: _pedometer.isTracking,
                  builder: (context, isTracking, _) {
                    if (!isTracking) {
                      return const SizedBox.shrink();
                    }
                    return ValueListenableBuilder<int>(
                      valueListenable: _pedometer.sessionSteps,
                      builder: (context, steps, _) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'PASOS: $steps',
                            style: GoogleFonts.robotoSlab(
                              fontSize: 16, fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onInverseSurface,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),

                leading: Builder(
                  builder: (ctx) => IconButton(
                    tooltip: 'Notificaciones',
                    icon: Icon(Icons.notifications_none, color: scheme.onPrimary),
                    onPressed: () async {
                      final storage = const FlutterSecureStorage();
                      final userId = await storage.read(key: 'user_id');
                      if (userId == null || userId.isEmpty) {
                        if (!ctx.mounted) return;
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('No se pudo identificar al usuario.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      if (!ctx.mounted) return;
                      Navigator.push(
                        ctx,
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
                        current.cameraTarget != null) ||
                    prev.userPosition != current.userPosition,
                listener: (context, state) {
                  if (state.locationError == 'disabled') {
                    _showEnableLocationDialog();
                  }
                  if (state.cameraTarget != null) {
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLngZoom(
                        state.cameraTarget!, state.cameraZoom,
                      ),
                    );
                  }
                  if (state.userPosition != null) {
                    context.read<WeatherCubit>().refreshAt(
                      lat: state.userPosition!.latitude,
                      lon: state.userPosition!.longitude,
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

                      // Ícono del clima arriba-izquierda
                      Positioned(
                        top: 12,
                        left: 12,
                        child: SafeArea(
                          child: IgnorePointer(
                            ignoring: true,
                            child: Material(
                              shape: const CircleBorder(),
                              elevation: 6,
                              color: const Color(0xFFD1D5DB),
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: WeatherIcon(
                                  condition:
                                  _weatherForUI?.condition ?? WeatherCondition.unknown,
                                  isNight: _weatherForUI?.isNight ?? false,
                                  size: 30,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Botón ESTACIONES (arriba-centro)
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
                                horizontal: 40, vertical: 12,
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
                                builder: (_) => EstacionesSheet(
                                  stations: state.nearbyStations,
                                ),
                              );
                            },
                            child: Text(
                              'ESTACIONES',
                              style: GoogleFonts.robotoSlab(
                                fontSize: 16, fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // FAB de voz (derecha, sobre la BottomBar)
                      Positioned(
                        right: 16,
                        bottom: kBottomNavigationBarHeight +
                            MediaQuery.of(context).padding.bottom +
                            12,
                        child: BlocBuilder<VoiceBloc, VoiceState>(
                          builder: (context, vstate) {
                            return FloatingActionButton.extended(
                              heroTag: 'home-voice-mic',
                              onPressed: () {
                                final bloc = context.read<VoiceBloc>();
                                vstate.isListening
                                    ? bloc.add(const VoiceStopRequested())
                                    : bloc.add(const VoiceStartRequested());
                              },
                              icon: Icon(
                                vstate.isListening ? Icons.mic : Icons.mic_none,
                              ),
                              label: Text(
                                vstate.isListening ? 'Escuchando…' : 'Hablar',
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),

              // FAB central (rentar/devolver)
              floatingActionButton: SizedBox(
                width: 76,
                height: 76,
                child: FloatingActionButton(
                  backgroundColor: Colors.transparent,
                  elevation: 6,
                  shape: const CircleBorder(),
                  onPressed: _goToReturnIfActiveOrRentOtherwise,
                  child: Image.asset(
                    'assets/images/home_button.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

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
        },
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
                        station.totalUmbrellas - station.availableUmbrellas;
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
