import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../presentation/blocs/auth/forgot_password/forgot_password_bloc.dart';
import '../../../presentation/blocs/auth/forgot_password/forgot_password_event.dart';
import '../../../presentation/blocs/auth/forgot_password/forgot_password_state.dart';
import '../../core/providers/api_provider.dart';
import '../../core/services/secure_storage_service.dart';
import '../../data/repositories/auth_repository.dart';
import '../../presentation/blocs/auth/auth_bloc.dart';
import 'login_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  String? _emailValidator(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'Ingresa tu correo';
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(value)) return 'Correo inválido';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF90E0EF),
      body: Center(
        child: SingleChildScrollView(
          child: BlocConsumer<ForgotPasswordBloc, ForgotPasswordState>(
            listener: (context, state) {
              if (state.error != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.error!), backgroundColor: Colors.red),
                );
              }
              if (state.success != null) {
                // NO navegamos a ResetPasswordPage aquí.
                // Mostramos mensaje y volvemos al login (o simplemente pop).
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.success!), backgroundColor: Colors.green),
                );
                // Si esta pantalla fue abierta con push desde Login, un pop basta:
                Navigator.pop(context);
                // O si quieres reemplazar explícitamente por LoginPage:
                // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
              }
            },
            builder: (context, state) {
              return Column(
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey, width: 2),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const Text(
                            "Recuperar contraseña",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Icon(Icons.lock_reset, size: 50, color: Color(0xFF001242)),
                          const SizedBox(height: 15),
                          TextFormField(
                            controller: _emailCtrl,
                            validator: _emailValidator,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: "Correo electrónico",
                              hintText: "correo@ejemplo.com",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              filled: true,
                              fillColor: const Color(0xFFF2F2F2),
                              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: state.loading
                                  ? null
                                  : () {
                                if (_formKey.currentState!.validate()) {
                                  context
                                      .read<ForgotPasswordBloc>()
                                      .add(ForgotPasswordSubmitted(_emailCtrl.text.trim()));
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF001242),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: state.loading
                                  ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                                  : const Text("Enviar", style: TextStyle(fontSize: 16, color: Colors.white)),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                const baseUrl =
                                    'https://sombri-ya-back-4def07fa1804.herokuapp.com';

                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => RepositoryProvider(
                                      create: (_) => ApiProvider(baseUrl: baseUrl),
                                      child: BlocProvider(
                                        create: (ctx) => AuthBloc(
                                          repo: AuthRepository(
                                            api: ctx.read<ApiProvider>(),
                                            storage: const SecureStorageService(),
                                          ),
                                        ),
                                        child: const LoginPage(),
                                      ),
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[600],
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text(
                                "Volver al inicio",
                                style: TextStyle(fontSize: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    "Sombri-Ya",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Ahorra tiempo y mantente\nseco en cualquier trayecto",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
