import 'package:flutter/material.dart';
import 'package:flutter_sombri_ya/signin.dart';
import 'package:flutter_sombri_ya/forgot_password.dart';
import 'package:local_auth/local_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'home.dart';
import "signin.dart";
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  final storage = const FlutterSecureStorage();
  final LocalAuthentication auth = LocalAuthentication();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    serverClientId: "751256331187-i160vbb6d96fo4bnnqhglrha2es9hla0.apps.googleusercontent.com",
  );


  Future<void> login(BuildContext context) async {
    final email = emailController.text;
    final password = passwordController.text;

    final url = Uri.parse("https://sombri-ya-back-4def07fa1804.herokuapp.com/auth/login/password");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final token = data["access_token"];
      await storage.write(key: "auth_token", value: token);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Correo o contraseña incorrectos")),
      );
    }
  }


  Future<void> loginWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return; // usuario canceló
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final idToken = googleAuth.idToken;
      print("ID Token: $idToken");

      if (idToken == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No se obtuvo ID Token")),
        );
        return;
      }

      final url = Uri.parse("https://sombri-ya-back-4def07fa1804.herokuapp.com/auth/login/google");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"idToken": idToken}),
      );

      if (response.statusCode == 200|| response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final token = data["accessToken"]; // ojo: tu backend devuelve "accessToken"
        await storage.write(key: "auth_token", value: token);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } else {
        print("Error Google login: ${response.statusCode}, body: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al iniciar con Google (${response.statusCode})")),
        );
      }
    } catch (e) {
      print("Error en login con Google: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al iniciar con Google")),
      );
    }
  }



  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF90E0EF),
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
                      "Iniciar sesión",
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
                      controller: emailController,
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
                      controller: passwordController,
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
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.center,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ForgotPassword(),
                            ),
                          );
                        },
                        child: const Text(
                          "¿Olvidaste tu contraseña?",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.center,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SigninPage(),
                            ),
                          );
                        },
                        child: const Text(
                          "¿No tienes una cuenta? Regístrate",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => login(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF001242),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          "Iniciar sesión",
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFFFFFDFD),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => loginWithGoogle(context), // Login con Google
                        icon: SizedBox(
                          width: 20,
                          height: 20,
                          child: Image.asset(
                            'assets/images/google_logo2.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        label: const Text(
                          "Iniciar sesión con Google",
                          style: TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.grey),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Footer
              const Text(
                "Sombri-Ya",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Ahorra tiempo y mantente\nseco en cualquier trayecto",
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF001242), fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
