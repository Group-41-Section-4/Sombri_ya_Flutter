import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/platform_tags.dart';

import '../../data/models/gps_coord.dart';
import '../../data/repositories/rental_repository.dart';
import '../../presentation/blocs/notifications/notifications_bloc.dart';
import '../../presentation/blocs/notifications/notifications_event.dart';
import '../../presentation/blocs/rent/rent_bloc.dart';
import '../../presentation/blocs/rent/rent_event.dart';
import '../../presentation/blocs/rent/rent_state.dart';
import '../home/home_page.dart';
import '../../presentation/blocs/home/home_bloc.dart';
import '../notifications/notifications_page.dart';
import '../profile/profile_page.dart';
import '../../data/repositories/profile_repository.dart';
import '../../presentation/blocs/profile/profile_bloc.dart';
import '../../presentation/blocs/profile/profile_event.dart';
import '../../widgets/app_drawer.dart';
import '../return/return_page.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../presentation/blocs/return/return_bloc.dart';
import '../../presentation/blocs/return/return_event.dart';
import '../../services/location_service.dart';

String bytesToHexColonUpper(Uint8List bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':').toUpperCase();

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

class RentPage extends StatefulWidget {
  static const routeName = '/rent';
  final GpsCoord? userPosition;
  final String? suggestedStationId;
  const RentPage({super.key, this.userPosition, this.suggestedStationId});
  @override
  State<RentPage> createState() => _RentPageState();
}

class _RentPageState extends State<RentPage> {
  final MobileScannerController _scanner = MobileScannerController();
  bool _weStoppedScanner = true;
  DateTime? _ignoreDetectionsUntil;
  String? _stationIdFromArgs;

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
          Uint8List? rawId = NfcA.from(tag)?.identifier ?? IsoDep.from(tag)?.identifier;
          rawId ??= _extractRawIdFromTagData(tagData);
          if (rawId == null) {
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return BlocConsumer<RentBloc, RentState>(
      listenWhen: (prev, curr) =>
      prev.loading != curr.loading ||
          prev.message != curr.message ||
          prev.error != curr.error ||
          prev.hasActiveRental != curr.hasActiveRental,
      listener: (context, state) async {
        await _ensureScanner(!state.loading && !state.nfcBusy);
        if (state.message != null) {
          _ignoreDetectionsUntil = DateTime.now().add(const Duration(milliseconds: 800));
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
        if (state.error != null) {
          final err = state.error!.toLowerCase();
          final isAlreadyActive = err.contains('Ya tienes una sombrilla') ||
              err.contains('Ya tenías una sombrilla') ||
              err.contains('Already has an active rental');
          if (isAlreadyActive) {
            _ignoreDetectionsUntil = DateTime.now().add(const Duration(milliseconds: 800));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Ya tenías una sombrilla activa. Te llevo a devolución."),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
            context.read<RentBloc>().add(const RentClearMessage());
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
          appBar: AppBar(
            backgroundColor: Color(0xFF90E0EF),
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
              icon: Icon(Icons.notifications_none, color: Colors.black),
              onPressed: () async {
                final storage = const FlutterSecureStorage();
                final userId = await storage.read(key: 'user_id');
                if (userId == null || !context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No se pudo identificar al usuario.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                Navigator.push(
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
              },
            ),
            actions: [
              IconButton(
                onPressed: () async {
                  await _ensureScanner(false);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider(
                        create: (_) =>
                        ProfileBloc(repository: ProfileRepository())..add(const LoadProfile('')),
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
              MobileScanner(
                controller: _scanner,
                fit: BoxFit.cover,
                onDetect: (capture) async {
                  if (state.loading || state.hasActiveRental) return;
                  final now = DateTime.now();
                  if (_ignoreDetectionsUntil != null && now.isBefore(_ignoreDetectionsUntil!)) {
                    return;
                  }
                  final raw = capture.barcodes.isNotEmpty ? capture.barcodes.first.rawValue : null;
                  if (raw == null) return;
                  await _ensureScanner(false);
                  context.read<RentBloc>().add(RentStartWithQr(raw));
                },
              ),
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.78,
                  height: MediaQuery.of(context).size.width * 0.58,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF28BCEF), width: 3),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, spreadRadius: 1)],
                  ),
                ),
              ),
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
                          foregroundColor: const Color(0xFF004D63),
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        ),
                        onPressed: () async {
                          await _ensureScanner(false);
                          GpsCoord position = widget.userPosition ?? GpsCoord(latitude: 0, longitude: 0);
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
                                    create: (_) => RentalRepository(storage: const FlutterSecureStorage()),
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
                            _ignoreDetectionsUntil = DateTime.now().add(const Duration(milliseconds: 1500));
                            context.read<RentBloc>().add(const RentRefreshActive());
                            await Future.delayed(const Duration(milliseconds: 350));
                          }
                          await _ensureScanner(true);
                        },
                      ),
                    const SizedBox(width: 12),
                    if (!state.hasActiveRental)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.contactless, size: 30),
                        label: const Text("Rentar con NFC"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF004D63),
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        ),
                        onPressed: state.nfcBusy ? null : _handleNfc,
                      ),
                  ],
                ),
              ),
              if (state.loading) const Center(child: CircularProgressIndicator()),
            ],
          ),
          bottomNavigationBar: BottomAppBar(
            shape: const CircularNotchedRectangle(),
            color: Color(0xFF90E0EF),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: IconButton(
                    icon: Icon(Icons.home, color: Colors.black),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BlocProvider(create: (_) => HomeBloc(), child: const HomePage()),
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
                      icon: Icon(Icons.menu, color: Colors.black),
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
              child: Image.asset('assets/images/home_button.png', width: 200, height: 200),
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        );
      },
    );
  }

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }
}
