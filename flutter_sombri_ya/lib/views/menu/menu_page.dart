import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_sombri_ya/presentation/blocs/notifications/notifications_event.dart';
import 'package:flutter_sombri_ya/views/notifications/notifications_page.dart';
import 'package:flutter_sombri_ya/presentation/blocs/notifications/notifications_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/ollama_config.dart';
import '../../../core/services/secure_storage_service.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../services/ollama_service.dart';
import '../../../presentation/blocs/chat/chat_bloc.dart';

import '../history/history_page.dart';
import '../payment/payment_methods_page.dart';
import '../chat/chat_page.dart';
import '../help/help_page.dart';
import '../nfc_registration/register_nfc_station_page.dart';
import '../profile/profile_page.dart';
import 'package:flutter_sombri_ya/presentation/blocs/profile/profile_bloc.dart';
import 'package:flutter_sombri_ya/data/repositories/profile_repository.dart';

class MenuPage extends StatelessWidget {
  MenuPage({super.key});

  final SecureStorageService _secureStorage = const SecureStorageService();

  Future<String> _loadUserName() async {
    return await _secureStorage.readUserName() ?? 'Usuario';
  }

  Future<void> _operNotifications(BuildContext context) async {
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
      backgroundColor: const Color(0xFFE9F9FF),
      appBar: AppBar(
        title: const Text('Más'),
        backgroundColor: const Color(0xFF90E0EF),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) {
                        return BlocProvider(
                          create: (_) =>
                              ProfileBloc(repository: ProfileRepository()),
                          child: const ProfilePage(),
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
              child: ListView(
                children: [
                  _MenuItem(
                    icon: Icons.payment,
                    title: 'Métodos de Pago',
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
                    icon: Icons.bookmark_border,
                    title: 'Historial de Reservas',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HistoryPage()),
                      );
                    },
                  ),
                  _MenuItem(
                    icon: Icons.notifications_none,
                    title: 'Notificaciones',
                    onTap: () {
                      _operNotifications(context);
                    },
                  ),
                  _MenuItem(
                    icon: Icons.chat_bubble_outline,
                    title: 'Sombri-IA',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) {
                            final service = OllamaService(
                              ollamaBaseUrl: OllamaConfig.ollamaBaseUrl,
                              model: OllamaConfig.model,
                            );

                            final chatRepo = ChatRepository(service: service);

                            return BlocProvider<ChatBloc>(
                              create: (_) => ChatBloc(repo: chatRepo),
                              child: const ChatPage(),
                            );
                          },
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
                        MaterialPageRoute(builder: (_) => const HelpPage()),
                      );
                    },
                  ),
                  _MenuItem(
                    icon: Icons.nfc,
                    title: 'Registrar NFC',
                    onTap: () async {
                      final token = await _secureStorage.readToken();
                      if (token == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'No se encontró el token de autenticación',
                            ),
                          ),
                        );
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              RegisterNfcStationPage(authToken: token),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
            Text(
              'Términos y condiciones',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 14,
                color: Colors.grey[700],
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: Colors.grey[800]),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(title, style: const TextStyle(fontSize: 16)),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
