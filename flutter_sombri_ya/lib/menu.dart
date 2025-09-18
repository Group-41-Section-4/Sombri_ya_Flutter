import 'package:flutter/material.dart';

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
            child: const DrawerHeader(
              decoration: BoxDecoration(
                color: Color(0xFF28BCEF),
              ),
              margin: EdgeInsets.zero,
              padding: EdgeInsets.all(16),
              child: Text(
                "Menu",
                style: TextStyle(
                  color: Colors.white,
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
              // Navegar a configuración
              Navigator.pop(context); // cierra el drawer
              // Navigator.pushNamed(context, '/settings');
            },
          ),
          ListTile(
            leading: const Icon(Icons.bookmark_border),
            title: const Text("Historial de Reservas"),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.payment),
            title: const Text("Métodos de Pago"),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.check_box_outlined),
            title: const Text("Subscripción"),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text("Ayuda"),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
