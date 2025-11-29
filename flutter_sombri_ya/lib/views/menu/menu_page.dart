import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/ollama_config.dart';
import '../../../core/services/secure_storage_service.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../services/ollama_service.dart';

import '../../../presentation/blocs/chat/chat_bloc.dart';
import '../../../presentation/blocs/notifications/notifications_bloc.dart';
import '../../../presentation/blocs/notifications/notifications_event.dart';

import '../chat/chat_page.dart';
import '../help/help_page.dart';
import '../history/history_page.dart';
import '../nfc_registration/register_nfc_station_page.dart';
import '../notifications/notifications_page.dart';
import '../payment/payment_methods_page.dart';

import '../nfc_registration/register_nfc_station_page.dart';
import '../profile/profile_page.dart';
import 'package:flutter_sombri_ya/presentation/blocs/profile/profile_bloc.dart';
import 'package:flutter_sombri_ya/data/repositories/profile_repository.dart';


class MenuPage extends StatelessWidget {
  final VoidCallback onRentTap;
  final SecureStorageService _secureStorage;

  MenuPage({
    super.key,
    required this.onRentTap,
  }) : _secureStorage = const SecureStorageService();

  static const Color _menuBlue = Color(0xFF90E0EF);
  static const Color _menuBackground = Color(0xFFF6FBFF);

  Future<String> _loadUserLabel() async {
    final name = await _secureStorage.readUserName();
    if (name != null && name.isNotEmpty) return name;

    final email = await _secureStorage.readUserEmail();
    if (email != null && email.isNotEmpty) return email;

    return 'Usuario';
  }

  Future<void> _openNotifications(BuildContext context) async {
    final userId = await _secureStorage.readUserId();

    if (userId == null || userId.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo identificar al usuario.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!context.mounted) return;

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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _menuBackground,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: _menuBlue,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: _menuBackground,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      size: 28,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FutureBuilder<String>(
                      future: _loadUserLabel(),
                      builder: (context, snapshot) {
                        final label = snapshot.data ?? 'Usuario';
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.cormorantGaramond(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Mi perfil >',
                              style: GoogleFonts.cormorantGaramond(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: Color(0xFF90E0EF),
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FutureBuilder<String>(
                          future: _loadUserName(),
                          builder: (context, snapshot) {
                            final name = snapshot.data ?? 'Usuario';
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: GoogleFonts.cormorantGaramond(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      'Mi perfil',
                                      style: GoogleFonts.cormorantGaramond(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView(
                  children: [
                    _MenuItem(
                      icon: Icons.payment_rounded,
                      title: 'Métodos de pago',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PaymentMethodsPage(),
                          ),
                        );
                      },
                    ),
                    _MenuItem(
                      icon: Icons.history_rounded,
                      title: 'Historial',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HistoryPage(),
                          ),
                        );
                      },
                    ),
                    _MenuItem(
                      icon: Icons.notifications_none,
                      title: 'Notificaciones',
                      onTap: () => _openNotifications(context),
                    ),
                    _MenuItem(
                      icon: Icons.chat_bubble_outline,
                      title: 'Sombri - IA',
                      onTap: () {
                        final service = OllamaService(
                          ollamaBaseUrl: OllamaConfig.ollamaBaseUrl,
                          model: OllamaConfig.model,
                        );
                        final chatRepo = ChatRepository(service: service);

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BlocProvider<ChatBloc>(
                              create: (_) => ChatBloc(repo: chatRepo),
                              child: const ChatPage(),
                            ),
                          ),
                        );
                      },
                    ),
                    _MenuItem(
                      icon: Icons.help_outline,
                      title: 'Ayuda',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HelpPage(),
                          ),
                        );
                      },
                    ),
                    _MenuItem(
                      icon: Icons.contactless_outlined,
                      title: 'Registrar NFC',
                      onTap: () async {
                        final token = await _secureStorage.readToken();
                        if (token == null) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'No se encontró el token de autenticación'),
                            ),
                          );
                          return;
                        }
                        if (!context.mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                RegisterNfcStationPage(authToken: token),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Términos y condiciones',
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SizedBox(
        width: 76,
        height: 76,
        child: FloatingActionButton(
          backgroundColor: Colors.transparent,
          elevation: 6,
          shape: const CircleBorder(),
          onPressed: () {
            Navigator.pop(context);
            onRentTap();
          },
          child: Image.asset(
            'assets/images/home_button.png',
            width: 100,
            height: 100,
            fit: BoxFit.contain,
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        color: _menuBlue,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: IconButton(
                icon: const Icon(Icons.home, color: Colors.white),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(width: 48),
            Padding(
              padding: const EdgeInsets.all(14),
              child: IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () {
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: const Color(0xFFF6FBFF),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: Colors.black87),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.black45),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
