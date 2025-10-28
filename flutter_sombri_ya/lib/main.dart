import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:nfc_manager/nfc_manager.dart';

import 'views/auth/login_page.dart';

import 'services/notification_service.dart';
import 'services/rain_alert_scheduler.dart';
import 'views/rent/rent_page.dart'; 

import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/providers/api_provider.dart';
import 'core/services/secure_storage_service.dart';
import 'data/repositories/auth_repository.dart';
import 'presentation/blocs/auth/auth_bloc.dart';

import 'core/services/voice_command_service.dart';
import 'presentation/blocs/voice/voice_bloc.dart';
import 'presentation/blocs/voice/voice_event.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
  await RainAlertScheduler.registerTestEveryFiveMinutes();
  //await RainAlertScheduler.registerPeriodic();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sombri-Ya',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey, 
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF28BCEF)),
      ),
      routes: {
        RentPage.routeName: (_) => const RentPage(),
      },
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

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
                  crossAxisAlignment: CrossAxisAlignment.center,
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
                        const baseUrl =
                            'https://sombri-ya-back-4def07fa1804.herokuapp.com';

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RepositoryProvider(
                              create: (_) => ApiProvider(baseUrl: baseUrl),
                              child: BlocProvider(
                                create: (ctx) => AuthBloc(
                                  repo: AuthRepository(
                                    api: ctx.read<ApiProvider>(),
                                    storage: const SecureStorageService(),
                                  ),
                                ),
                                child: const LoginPage(),
                              ),
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        'Iniciar Sesión',
                        style: TextStyle(fontSize: 20),
                      ),
                    ),

                    // ElevatedButton(
                    //   onPressed: () async {
                    //     await NotificationService.showRainAlert(
                    //       title: '🔔 Test notificación',
                    //       body: 'Si ves esto, las notificaciones están OK',
                    //       payload: 'test-station-id',
                    //     );
                    //   },
                    //   child: const Text('🔔 Test notificación directa'),
                    // ),

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
