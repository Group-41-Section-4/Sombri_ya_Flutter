import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../config/ollama_config.dart';
import '../data/repositories/chat_repository.dart';
import '../services/ollama_service.dart';
import '../presentation/blocs/chat/chat_bloc.dart';
import '../views/nfc_registration/register_nfc_station_page.dart';
import '../views/chat/chat_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_sombri_ya/views/history/history_page.dart';
import 'package:flutter_sombri_ya/views/payment/payment_methods_page.dart';

class AppDrawer extends StatelessWidget {
  AppDrawer({super.key});
  final storage = FlutterSecureStorage();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          SizedBox(
            height: 100,
            child: DrawerHeader(
              decoration: BoxDecoration(color: scheme.primary),
              margin: EdgeInsets.zero,
              padding: EdgeInsets.all(16),
              child: Text(
                "Menu",
                style: GoogleFonts.cormorantGaramond(
                  color: scheme.onPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          /*
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text("Configuración"),
            onTap: () {
              // TODO: add functionality to navigate to "configuraciones" view
              Navigator.pop(context);
            },
            */
          ListTile(
            leading: const Icon(Icons.bookmark_border),
            title: const Text("Historial de Reservas"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.payment),
            title: const Text("Métodos de Pago"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PaymentMethodsPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.chat_bubble_outline),
            title: const Text("Sombri-IA"),

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

          /*
          ListTile(
            leading: const Icon(Icons.check_box_outlined),
            title: const Text("Subscripción"),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text("Ayuda"),
            onTap: () {
              // TODO: add functionality to navigate to "ayuda" view
            },
          ),

           */
          ListTile(
            leading: const Icon(Icons.nfc),
            title: const Text("Registrar NFC"),
            onTap: () async {
              Navigator.pop(context);
              final storage = FlutterSecureStorage();
              final token = await storage.read(key: "auth_token");

              if (token == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("No se encontró el token de autenticación"),
                  ),
                );
                return;
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      RegisterNfcStationPage(authToken: token),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
