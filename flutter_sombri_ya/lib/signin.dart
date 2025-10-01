import 'package:flutter/material.dart';
import 'login.dart';

class SigninPage extends StatelessWidget {
  const SigninPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF28BCEF),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Text(
                "Sombri-ya",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF001242),
                ),
              ),
              const SizedBox(height: 30),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFDFD),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey, width: 2),
                ),
                child: Column(
                  children: [
                    const Text(
                      "Regístrate",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Icon(
                      Icons.person,
                      size: 50,
                      color: Color(0xFF001242),
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: "Correo electrónico",
                        hintText: "correo@ejemplo.com",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Color(0xFFF2F2F2),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 15,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Ingresa tu correo";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Contraseña",
                        hintText: "Contraseña",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Color(0xFFF2F2F2),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 15,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Ingresa tu contraseña";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Confirmar contraseña",
                        hintText: "Contraseña",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Color(0xFFF2F2F2),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 15,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Confirma tu contraseña";
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF001242),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 70,
                    vertical: 15,
                  ),
                ),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
                child: const Text("Registrar", style: TextStyle(fontSize: 20)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
