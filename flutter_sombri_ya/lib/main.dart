import 'package:flutter/material.dart';
import 'package:flutter_sombri_ya/home.dart';
import 'home.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sombri-Ya',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF28BCEF)),
      ),
      home: const SplashScreen(),
      //theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        //colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      //),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF28BCEF), // azul de fondo
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,      // centra verticalmente
        crossAxisAlignment: CrossAxisAlignment.center,    // centra horizontalmente
        children: [
          // Logo
          Align(
            alignment: Alignment.center, // fuerza al centro
            child: Image.asset(
              'assets/images/logo_no_bg.png',
              fit: BoxFit.contain,
              width: MediaQuery.of(context).size.width * 0.8,
            ),
          ),

          const SizedBox(height: 40), // espacio entre logo y botón

          // Botón
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFC5152),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 70, vertical: 15),
            ),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
            },
            child: const Text(
              "Iniciar Sesión",
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}


