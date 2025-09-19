import 'package:flutter/material.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'theme.dart'; // usa tus colores de AppThem
import 'menu.dart';


class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(

        backgroundColor: const Color(0xFF28BCEF),
        foregroundColor: Colors.white,
        title: const Text('Home'),
        leading: IconButton(
          icon: const Icon(Icons.notifications_none),
          onPressed: () {},
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white24,
              backgroundImage: AssetImage('assets/images/profile.png'),
            ),
          ),
        ],
      ),

      endDrawer: const AppDrawer(),

      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/map.png',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.low,
              cacheWidth: 1080,
            ),
          ),
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF005E7C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 6,
                ),
                onPressed: () {
                  //TODO: When the ESTACIONES button is pressed
                },
                child: const Text(
                  'ESTACIONES',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
              ),
            ),
          ),
        ],
      ),

      floatingActionButton: SizedBox(
        width: 76,
        height: 76,
        child: FloatingActionButton(
          backgroundColor : const Color(0xFFFF4645),
          elevation: 6,
          onPressed: () {},
          child: Image.asset(
            'assets/images/home_button.png',
            width: 52,
            height: 52,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,


      bottomNavigationBar: SafeArea(
        child: Container(
          height: 70, 
          color: const Color(0xFF28BCEF), 
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.map, color: Colors.white),
                    onPressed: () {
                      // TODO: Whenn the map button is pressed
                    },
                  ),
                  const Text(
                    "Mapa",
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
      
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onPressed: () {
                      // TODO: When the menu button is pressed
                    },
                  ),
                  const Text(
                    "Más",
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ],

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Botón Home (puede navegar o solo mostrar activo)
          Padding(
            padding: const EdgeInsets.all(14),
            child: IconButton(
              icon: const Icon(Icons.home),
              onPressed: () {
                // Aquí podrías navegar a Home o dejarlo fijo
                // Navigator.pushNamed(context, '/home');
              },
            ),
          ),

          const SizedBox(width: 48), // espacio para el notch del FAB

          // Botón Menu que abre el Drawer
          Padding(
            padding: const EdgeInsets.all(14),
            child: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openEndDrawer();
                },
              ),
            ),

          ),
        ),
      ),
    );
  }
}

