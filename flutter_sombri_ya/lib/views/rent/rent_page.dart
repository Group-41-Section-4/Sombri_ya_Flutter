import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/platform_tags.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/services/voice_command_service.dart';
import '../../data/models/gps_coord.dart';
import '../../data/repositories/rental_repository.dart';
import '../../data/repositories/profile_repository.dart';

import '../../presentation/blocs/connectivity/connectivity_cubit.dart';
import '../../presentation/blocs/home/home_bloc.dart';
import '../../presentation/blocs/rent/rent_bloc.dart';
import '../../presentation/blocs/rent/rent_event.dart';
import '../../presentation/blocs/rent/rent_state.dart';

import '../../presentation/blocs/return/return_bloc.dart';
import '../../presentation/blocs/return/return_event.dart';

import '../../presentation/blocs/notifications/notifications_bloc.dart';
import '../../presentation/blocs/notifications/notifications_event.dart';

import '../../presentation/blocs/profile/profile_bloc.dart';
import '../../presentation/blocs/profile/profile_event.dart';

import '../../presentation/blocs/voice/voice_bloc.dart';
import '../../presentation/blocs/voice/voice_event.dart';
import '../../presentation/blocs/voice/voice_state.dart';
import '../../domain/voice/voice_intent.dart';

import '../home/home_page.dart';
import '../notifications/notifications_page.dart';
import '../profile/profile_page.dart';
import '../return/return_page.dart';

import '../../widgets/app_drawer.dart';
import '../../services/location_service.dart';

import '../../core/net/is_online.dart';

/// ---------- Utils ----------
String bytesToHexColonUpper(Uint8List bytes) => bytes
    .map((b) => b.toRadixString(16).padLeft(2, '0'))
    .join(':')
    .toUpperCase();

Uint8List? _extractRawIdFromTagData(Map<dynamic, dynamic> tagData) {
  if (tagData.containsKey('nfca')) {
    final nfca = tagData['nfca'];
    final raw = (nfca is Map) ? nfca['identifier'] : null;
    if (raw is Uint8List) return raw;
    if (raw is List) return Uint8List.fromList(raw.cast<int>());
  }
  if (tagData.containsKey('mifareclassic')) {
    final mifare = tagData['mifareclassic'];
    final raw = (mifare is Map) ? mifare['identifier'] : null;
    if (raw is Uint8List) return raw;
    if (raw is List) return Uint8List.fromList(raw.cast<int>());
  }
  for (final e in tagData.entries) {
    final v = e.value;
    if (v is Map && v['identifier'] != null) {
      final raw = v['identifier'];
      if (raw is Uint8List) return raw;
      if (raw is List) return Uint8List.fromList(raw.cast<int>());
    }
  }
  return null;
}

/// ---------- Page ----------
class RentPage extends StatefulWidget {
  static const routeName = '/rent';
  final GpsCoord? userPosition;
  final String? suggestedStationId;

  final bool startInNfc;

  const RentPage({
    super.key,
    this.userPosition,
    this.suggestedStationId,
    this.startInNfc = false,
  });

  @override
  State<RentPage> createState() => _RentPageState();
}

class _RentPageState extends State<RentPage> {
  final MobileScannerController _scanner = MobileScannerController();
  bool _weStoppedScanner = true;
  DateTime? _ignoreDetectionsUntil;
  String? _stationIdFromArgs;

  static const Color _barColor = Color(0xFF90E0EF);
  static const Color _brandPrimaryDark = Color(0xFF004D63);
  static const Color _accent = Color(0xFF28BCEF);

  DateTime? _lastOfflineNoticeAt;

  bool _launchedNfcFromArgs = false;
  bool _qrVisible = true;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _showOfflineSnackOnce({int cooldownSeconds = 4}) {
    if (!mounted) return;
    final now = DateTime.now();
    if (_lastOfflineNoticeAt != null &&
        now.difference(_lastOfflineNoticeAt!) <
            Duration(seconds: cooldownSeconds)) {
      return;
    }

    _lastOfflineNoticeAt = now;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sin conexión. Verifica tu internet.'),
        duration: Duration(seconds: 2),
      ),
    );

    _ignoreDetectionsUntil = now.add(const Duration(seconds: 2));
  }

  @override
  void initState() {
    super.initState();
    context.read<RentBloc>().add(const RentInit());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_stationIdFromArgs == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map && args['stationId'] is String) {
        _stationIdFromArgs = args['stationId'] as String;
      }
    }

    if (!_launchedNfcFromArgs) {
      final args = ModalRoute.of(context)?.settings.arguments;
      final modeArg = (args is Map)
          ? (args['mode'] ?? '').toSrting().toLowerCase().trim()
          : '';
      final shouldStarNfc = widget.startInNfc || modeArg == 'nfc';
      debugPrint(
        '[RentPage] startInNFC=${widget.startInNfc} modeArg=$modeArg shouldStartNfc=$shouldStarNfc',
      );
      if (shouldStarNfc && !_launchedNfcFromArgs) {
        _launchedNfcFromArgs = true;
        setState(() => _qrVisible = false);
        Future.microtask(() async {
          debugPrint('[RentPage] launching NFC from didChangeDependencies()');
          if (!mounted) return;
          await _ensureScanner(false);
          await _handleNfc();
        });
      }
    }
  }

  Future<void> _ensureScanner(bool shouldRun) async {
    if (!mounted) return;
    if (shouldRun) {
      if (_weStoppedScanner) {
        try {
          await _scanner.start();
        } catch (_) {}
        _weStoppedScanner = false;
      }
    } else {
      if (!_weStoppedScanner) {
        try {
          await _scanner.stop();
        } catch (_) {}
        _weStoppedScanner = true;
      }
    }
  }

  Future<void> _handleNfc() async {
    await _ensureScanner(false);
    try {
      await NfcManager.instance.stopSession();
    } catch (_) {}
    await Future.delayed(const Duration(milliseconds: 150));

    context.read<RentBloc>().add(const RentClearMessage());

    NfcManager.instance.startSession(
      pollingOptions: {NfcPollingOption.iso14443},
      onDiscovered: (NfcTag tag) async {
        try {
          await _ensureScanner(false);
          final tagData = tag.data;
          Uint8List? rawId =
              NfcA.from(tag)?.identifier ?? IsoDep.from(tag)?.identifier;
          rawId ??= _extractRawIdFromTagData(tagData);
          if (rawId == null) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("No se pudo leer el ID del tag NFC"),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 1),
              ),
            );
            await NfcManager.instance.stopSession();
            await _ensureScanner(true);
            return;
          }
          final uid = bytesToHexColonUpper(rawId);
          debugPrint('[RENT][NFC] uid=$uid');
          context.read<RentBloc>().add(RentStartWithNfc(uid));
          await NfcManager.instance.stopSession();
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error en NFC: $e"),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
          await NfcManager.instance.stopSession();
          await _ensureScanner(true);
        }
      },
    );
  }

  Future<void> _goToReturnFlow() async {
    await _ensureScanner(false);

    GpsCoord position =
        widget.userPosition ?? GpsCoord(latitude: 0, longitude: 0);
    if (widget.userPosition == null) {
      final pos = await LocationService.getPosition();
      if (pos != null) {
        position = GpsCoord(latitude: pos.latitude, longitude: pos.longitude);
      }
    }

    final reset = await Navigator.push(
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
            child: ReturnPage(userPosition: position),
          ),
        ),
      ),
    );

    if (reset == "returned") {
      _ignoreDetectionsUntil = DateTime.now().add(
        const Duration(milliseconds: 1500),
      );
      context.read<RentBloc>().add(const RentRefreshActive());
      await Future.delayed(const Duration(milliseconds: 350));
    }

    await _ensureScanner(true);
  }
  
  Future<void> _goToProfile(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProfilePage()),
    );
  }

  Future<void> _goToNotifications(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => NotificationsBloc(),
          child: const NotificationsPage(),
        ),
      ),
    );
  }

  /// ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          VoiceBloc(VoiceCommandService())..add(const VoiceInitRequested()),
      child: BlocListener<VoiceBloc, VoiceState>(
        listenWhen: (p, c) =>
            p.intent != c.intent && c.intent != VoiceIntent.none,
        listener: (context, vstate) async {
          switch (vstate.intent) {
            case VoiceIntent.rentDefault:
            case VoiceIntent.rentQR:
              await _ensureScanner(true);
              break;
            case VoiceIntent.rentNFC:
              await _ensureScanner(false);
              await _handleNfc();
              break;
            case VoiceIntent.returnUmbrella:
              await _goToReturnFlow();
              break;
            case VoiceIntent.openMenu:
              _scaffoldKey.currentState?.openEndDrawer();
              break;
            case VoiceIntent.openProfile:
              await _goToProfile(context);
              break;
            case VoiceIntent.openNotifications:
              await _goToNotifications(context);
              break;
            case VoiceIntent.none:
              break;
          }
          context.read<VoiceBloc>().add(const VoiceClearIntent());
        },
        child: BlocConsumer<RentBloc, RentState>(
          listenWhen: (prev, curr) =>
              prev.loading != curr.loading ||
              prev.message != curr.message ||
              prev.error != curr.error ||
              prev.hasActiveRental != curr.hasActiveRental ||
              prev.nfcBusy != curr.nfcBusy,
          listener: (context, state) async {
            // Control fino del scanner
            await _ensureScanner(!state.loading && !state.nfcBusy);

            if (state.message != null && mounted) {
              _ignoreDetectionsUntil = DateTime.now().add(
                const Duration(milliseconds: 800),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message!),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
              context.read<RentBloc>().add(const RentClearMessage());
              return;
            }

            if (state.error != null && mounted) {
              final err = state.error!.toLowerCase();
              final isAlreadyActive =
                  err.contains('ya tienes una sombrilla') ||
                  err.contains('ya tenías una sombrilla') ||
                  err.contains('already has an active rental');

              if (isAlreadyActive) {
                _ignoreDetectionsUntil = DateTime.now().add(
                  const Duration(milliseconds: 800),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Ya tenías una sombrilla activa. Te llevo a devolución.",
                    ),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
                context.read<RentBloc>().add(const RentClearMessage());
                await _goToReturnFlow();
                return;
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error!),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 2),
                ),
              );
              context.read<RentBloc>().add(const RentClearMessage());
            }
          },
          builder: (context, state) {
            return Scaffold(
              key: _scaffoldKey,
              appBar: AppBar(
                backgroundColor: _barColor, // Color estático
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
                // Campana de notificaciones (leading)
                leading: IconButton(
                  icon: const Icon(
                    Icons.notifications_none,
                    color: Colors.black,
                  ),
                  onPressed: () async {
                    await _ensureScanner(false);
                    final storage = const FlutterSecureStorage();
                    final userId = await storage.read(key: 'user_id');
                    if (userId == null || !context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No se pudo identificar al usuario.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      await _ensureScanner(true);
                      return;
                    }
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider(
                          create: (_) => NotificationsBloc()
                            ..add(StartRentalPolling(userId))
                            ..add(const CheckWeather()),
                          child: const NotificationsPage(),
                        ),
                      ),
                    );
                    await _ensureScanner(true);
                  },
                ),
                // Avatar de perfil (actions)
                actions: [
                  IconButton(
                    onPressed: () async {
                      await _ensureScanner(false);
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BlocProvider(
                            create: (_) =>
                                ProfileBloc(repository: ProfileRepository())
                                  ..add(const LoadProfile('')),
                            child: const ProfilePage(),
                          ),
                        ),
                      );
                      await _ensureScanner(true);
                    },
                    icon: const CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white24,
                      backgroundImage: AssetImage('assets/images/profile.png'),
                    ),
                  ),
                ],
              ),

              endDrawer: AppDrawer(),

              body: Stack(
                children: [
                  // Scanner de QR
                  if (_qrVisible)
                    MobileScanner(
                      controller: _scanner,
                      fit: BoxFit.cover,
                      onDetect: (capture) async {
                        if (state.loading || state.hasActiveRental) return;

                        if (!isOnline(context)) {
                          _showOfflineSnackOnce();
                          return;
                        }

                        final now = DateTime.now();
                        if (_ignoreDetectionsUntil != null &&
                            now.isBefore(_ignoreDetectionsUntil!)) {
                          return;
                        }

                        final raw = capture.barcodes.isNotEmpty
                            ? capture.barcodes.first.rawValue
                            : null;

                        if (raw == null) return;

                        await _ensureScanner(false);
                        context.read<RentBloc>().add(RentStartWithQr(raw));
                      },
                    ),

                  // Marco de guía de escaneo
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.78,
                      height: MediaQuery.of(context).size.width * 0.58,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _accent, width: 3),
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

                  // Botones de acción (NFC / Devolución)
                  Positioned(
                    bottom: 120,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (state.hasActiveRental)
                          ElevatedButton.icon(
                            icon: const Icon(Icons.assignment_return, size: 30),
                            label: const Text("Ir a devolución"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white60,
                              foregroundColor: _brandPrimaryDark,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 15,
                              ),
                            ),
                            onPressed: _goToReturnFlow,
                          ),

                        if (state.hasActiveRental) const SizedBox(width: 12),

                        if (!state.hasActiveRental)
                          ElevatedButton.icon(
                            icon: const Icon(Icons.contactless, size: 30),
                            label: const Text("Rentar con NFC"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: _brandPrimaryDark,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 15,
                              ),
                            ),
                            onPressed: state.nfcBusy
                                ? null
                                : () async {
                                    if (!isOnline(context)) {
                                      _showOfflineSnackOnce();
                                      return;
                                    }
                                    await _handleNfc();
                                  },
                          ),
                      ],
                    ),
                  ),

                  // FAB de voz (mic)
                  Positioned(
                    right: 16,
                    bottom:
                        kBottomNavigationBarHeight +
                        MediaQuery.of(context).padding.bottom,
                    child: BlocBuilder<VoiceBloc, VoiceState>(
                      builder: (context, vstate) {
                        return FloatingActionButton.extended(
                          heroTag: 'voice-mic',
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

                  if (state.loading)
                    const Center(child: CircularProgressIndicator()),
                ],
              ),

              bottomNavigationBar: BottomAppBar(
                shape: const CircularNotchedRectangle(),
                color: _barColor,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: IconButton(
                        icon: const Icon(Icons.home, color: Colors.black),
                        onPressed: () {
                          final connectivityCubit = context
                              .read<ConnectivityCubit>();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MultiBlocProvider(
                                providers: [
                                  BlocProvider<ConnectivityCubit>.value(
                                    value: connectivityCubit,
                                  ),
                                  BlocProvider<HomeBloc>(
                                    create: (ctx) => HomeBloc(
                                      connectivityCubit: connectivityCubit,
                                    ),
                                  ),
                                ],
                                child: const HomePage(),
                              ),
                            ),
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
                          onPressed: () => Scaffold.of(context).openEndDrawer(),
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
                  onPressed: () {},
                  child: Image.asset(
                    'assets/images/home_button.png',
                    width: 200,
                    height: 200,
                  ),
                ),
              ),
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.centerDocked,
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }
}