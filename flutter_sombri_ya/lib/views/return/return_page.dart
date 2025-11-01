import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/platform_tags.dart';

import '../profile/profile_page.dart';

import '../../data/models/gps_coord.dart';
import '../../data/repositories/profile_repository.dart';
import '../../presentation/blocs/notifications/notifications_bloc.dart';
import '../../presentation/blocs/notifications/notifications_event.dart';
import '../../presentation/blocs/profile/profile_bloc.dart';
import '../../presentation/blocs/profile/profile_event.dart';
import '../../presentation/blocs/return/return_bloc.dart';
import '../../presentation/blocs/return/return_event.dart';
import '../../presentation/blocs/return/return_state.dart';

import '../home/home_page.dart';
import '../../presentation/blocs/home/home_bloc.dart';
import '../notifications/notifications_page.dart';
import '../../widgets/app_drawer.dart';

import '../../core/net/is_online.dart';

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


class ReturnPage extends StatefulWidget {
  final GpsCoord userPosition;
  const ReturnPage({super.key, required this.userPosition});

  @override
  State<ReturnPage> createState() => _ReturnPageState();
}

class _ReturnPageState extends State<ReturnPage> {
  final MobileScannerController _scanner = MobileScannerController();
  bool _scannerRunning = true;
  DateTime? _ignoreDetectionsUntil;

  DateTime? _lastOfflineNoticeAt;

  void _showOfflineSnackOnce({int cooldownSeconds =4}) {
    if (!mounted) return;
    final now = DateTime.now();
    if (_lastOfflineNoticeAt != null &&
        now.difference(_lastOfflineNoticeAt!) < Duration(seconds: cooldownSeconds)) {
      return;
    }

    _lastOfflineNoticeAt = now;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sin conexión a internet. Inténtalo más tarde.'),
        duration: Duration(seconds: 2),
      ),
    );

    _ignoreDetectionsUntil = now.add(const Duration(seconds: 2));
  }


  @override
  void initState() {
    super.initState();
    context.read<ReturnBloc>().add(ReturnInit());
  }

  Future<void> _ensureScanner(bool shouldRun) async {
    if (shouldRun && !_scannerRunning) {
      try {
        await _scanner.start();
      } catch (_) {}
      _scannerRunning = true;
    } else if (!shouldRun && _scannerRunning) {
      try {
        await _scanner.stop();
      } catch (_) {}
      _scannerRunning = false;
    }
  }

  Future<void> _handleNfc() async {
    await _ensureScanner(false);
    try {
      await NfcManager.instance.stopSession();
    } catch (_) {}
    await Future.delayed(const Duration(milliseconds: 150));
    context.read<ReturnBloc>().add(ReturnClearMessage());
    NfcManager.instance.startSession(
      pollingOptions: {NfcPollingOption.iso14443},
      onDiscovered: (NfcTag tag) async {
        try {
          await _ensureScanner(false);
          final tagData = tag.data;
          Uint8List? rawId = NfcA.from(tag)?.identifier ?? IsoDep.from(tag)?.identifier;
          rawId ??= _extractRawIdFromTagData(tagData);
          if (rawId == null) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("No se pudo leer el ID del tag NFC"),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 1),
            ));
            await NfcManager.instance.stopSession();
            await _ensureScanner(true);
            return;
          }
          final uid = bytesToHexColonUpper(rawId);
          context.read<ReturnBloc>().add(ReturnWithNfc(uid));
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
    return BlocConsumer<ReturnBloc, ReturnState>(
      listenWhen: (prev, curr) =>
      prev.loading != curr.loading ||
          prev.ended != curr.ended ||
          prev.message != curr.message ||
          prev.error != curr.error,
      listener: (context, state) async {
        await _ensureScanner(!state.loading && !state.nfcBusy);
        if (state.message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message!),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 1),
            ),
          );
          context.read<ReturnBloc>().add(ReturnClearMessage());
        }
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
          context.read<ReturnBloc>().add(ReturnClearMessage());
        }
        if (state.ended) {
          if (mounted) Navigator.pop(context, "returned");
        }
      },
      builder: (context, state) {
        final scheme = Theme.of(context).colorScheme;
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Color(0xFF90E0EF),
            foregroundColor: Colors.black,
            centerTitle: true,
            title: Text(
              'Devolver sombrilla',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.notifications_none),
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
                await _ensureScanner(true);
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
              MobileScanner(
                controller: _scanner,
                fit: BoxFit.cover,
                onDetect: (capture) async {
                  if (state.loading || state.ended) return;

                  if (!isOnline(context)) {
                    _showOfflineSnackOnce();
                    return;
                  }

                  final raw = capture.barcodes.isNotEmpty
                      ? capture.barcodes.first.rawValue
                      : null;
                  if (raw == null) return;
                  await _ensureScanner(false);
                  context.read<ReturnBloc>().add(ReturnWithQr(raw));
                },
              ),
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.78,
                  height: MediaQuery.of(context).size.width * 0.58,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF28BCEF),
                      width: 3,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 70,
                left: 0,
                right: 0,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: const Text(
                          'Apunta la cámara al QR para devolver',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 15),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.contactless, size: 20),
                        label: const Text('Devolver con NFC'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF004D63),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 15,
                          ),
                          shape: const StadiumBorder(),
                        ),
                        onPressed: state.nfcBusy 
                          ? null 
                          : () async {
                            if (!isOnline(context)) {
                              _showOfflineSnackOnce();
                              return;
                            } 
                            await _handleNfc();
                          } 
                      ),
                    ],
                  ),
                ),
              ),
              if (state.loading)
                const Center(child: CircularProgressIndicator()),
            ],
          ),
          bottomNavigationBar: BottomAppBar(
            shape: const CircularNotchedRectangle(),
            color: const Color(0xFF90E0EF),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: const Icon(Icons.home, color: Colors.black),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider(create: (_) => HomeBloc(), child: const HomePage()),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 48),
                Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.menu, color: Colors.black),
                    onPressed: () => Scaffold.of(context).openEndDrawer(),
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: Colors.transparent,
            elevation: 6,
            shape: const CircleBorder(),
            onPressed: () {},
            child: Image.asset(
              'assets/images/home_button.png',
              width: 100,
              height: 100,
            ),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
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
