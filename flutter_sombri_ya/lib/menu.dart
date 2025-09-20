import 'package:flutter/material.dart';
import 'history.dart';
import 'package:google_fonts/google_fonts.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          SizedBox(
            height: 100,
            child:  DrawerHeader(
              decoration: BoxDecoration(
                color: Color(0xFF90E0EF),
              ),
              margin: EdgeInsets.zero,
              padding: EdgeInsets.all(16),
              child: Text(
                "Menu",
                style: GoogleFonts.cormorantGaramond(
                  color: Colors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

            ),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text("Configuración"),
            onTap: () {
              // TODO: add functionality to navigate to "configuraciones" view
              Navigator.pop(context);

            },
          ),
          ListTile(
            leading: const Icon(Icons.bookmark_border),
            title: const Text("Historial de Reservas"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder:(context) => const HistoryPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.payment),
            title: const Text("Métodos de Pago"),
            onTap: (
                // TODO: add functionality to navigate to "métodos de pago" view
                ) {},
          ),
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
        ],
      ),
    );
  }
}
