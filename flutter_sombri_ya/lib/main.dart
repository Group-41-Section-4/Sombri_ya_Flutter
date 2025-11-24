import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_sombri_ya/presentation/blocs/weather/weather_cubit.dart';
import 'package:flutter_sombri_ya/services/weather_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:nfc_manager/nfc_manager.dart';

import 'core/providers/api_provider.dart';
import 'core/services/secure_storage_service.dart';
import 'data/repositories/auth_repository.dart';
import 'presentation/blocs/auth/auth_bloc.dart';

import 'presentation/blocs/connectivity/connectivity_cubit.dart';
import 'core/connectivity/connectivity_service.dart';

import 'services/notification_service.dart';
import 'services/rain_alert_scheduler.dart';

import 'views/rent/rent_page.dart';
import 'views/auth/login_page.dart';
import 'views/auth/reset_password_page.dart';
import 'app_shell.dart';

import 'core/services/local_prefs.dart';
import 'core/images/app_image_cache.dart';
import 'data/repositories/rental_repository.dart';
import 'presentation/blocs/rent/rent_bloc.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
const String kBaseUrl = 'https://sombri-ya-back-4def07fa1804.herokuapp.com';
late LocalPrefs gLocalPrefs;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES', null);
  await NfcManager.instance.isAvailable();

  await NotificationService.init(onTap: (payload) async {
    if (payload == null) return;
    navigatorKey.currentState?.pushNamed(
      RentPage.routeName,
      arguments: {'stationId': payload},
    );
  });

  await RainAlertScheduler.cancelAll();
  await RainAlertScheduler.registerPeriodic();

  gLocalPrefs = await LocalPrefs.create();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ApiProvider>(
          create: (_) => ApiProvider(baseUrl: kBaseUrl),
        ),
        RepositoryProvider<AuthRepository>(
          create: (ctx) => AuthRepository(
            api: ctx.read<ApiProvider>(),
            storage: const SecureStorageService(),
          ),
        ),
        RepositoryProvider<ConnectivityService>(
          create: (_) => ConnectivityService(
            probeInterval: const Duration(seconds: 4),
          ),
        ),
        RepositoryProvider<LocalPrefs>.value(
          value: gLocalPrefs,
        ),
        RepositoryProvider<WeatherService>(
          create: (_) => WeatherService(
            jsonStalePeriod: const Duration(hours: 12),
          ),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (ctx) => AuthBloc(repo: ctx.read<AuthRepository>()),
          ),
          BlocProvider<ConnectivityCubit>(
            create: (ctx) =>
            ConnectivityCubit(ctx.read<ConnectivityService>())..start(),
          ),
          BlocProvider<WeatherCubit>(
            create: (ctx) => WeatherCubit(weather: ctx.read<WeatherService>()),
          ),
        ],
        child: MaterialApp(
          title: 'Sombri-Ya',
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF28BCEF)),
          ),
          routes: {
            RentPage.routeName: (ctx) {
              return RepositoryProvider(
                create: (_) => RentalRepository(
                  storage: const FlutterSecureStorage(),
                ),
                child: BlocProvider(
                  create: (blocCtx) =>
                      RentBloc(repo: blocCtx.read<RentalRepository>()),
                  child: const RentPage(),
                ),
              );
            },
            '/reset': (ctx) {
              final args =
                  ModalRoute.of(ctx)!.settings.arguments as Map<String, String>;
              final userId = args['userId']!;
              final token = args['token']!;
              return ResetPasswordPage(userId: userId, token: token);
            },
            '/login': (ctx) => const LoginPage(),
          },
          builder: (context, child) =>
              AppShell(child: child ?? const SizedBox()),
          home: const SplashScreen(),
        ),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    tuneImageCache(maxEntries: 300, maxBytesMB: 120);
    scheduleWarmUp(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF90E0EF),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: IntrinsicHeight(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 2),
                    Align(
                      alignment: Alignment.center,
                      child: Image.asset(
                        'assets/images/logo_no_bg.png',
                        fit: BoxFit.contain,
                        width: MediaQuery.of(context).size.width * 0.7,
                      ),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF001242),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 70,
                          vertical: 15,
                        ),
                      ),
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      child: const Text('Iniciar Sesión',
                          style: TextStyle(fontSize: 20)),
                    ),
                    const Spacer(flex: 3),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
