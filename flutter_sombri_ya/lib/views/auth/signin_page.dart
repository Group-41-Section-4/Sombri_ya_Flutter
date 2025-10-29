import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../presentation/blocs/auth/auth_bloc.dart';
import '../../presentation/blocs/auth/auth_event.dart';
import '../../presentation/blocs/auth/auth_state.dart';

class SigninPage extends StatefulWidget {
  const SigninPage({super.key});
  @override
  State<SigninPage> createState() => _SigninPageState();
}

class _SigninPageState extends State<SigninPage> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final nameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool useBiometrics = true;

  @override
  void dispose() {
    emailController.dispose();
    nameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden')),
      );
      return;
    }
    context.read<AuthBloc>().add(
      RegisterSubmitted(
        email: emailController.text.trim(),
        name: nameController.text.trim(),
        password: passwordController.text,
        biometricEnabled: useBiometrics,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF90E0EF),
      body: BlocListener<AuthBloc, AuthState>(
        listenWhen: (p, c) => c is RegistrationSuccess || c is AuthFailure,
        listener: (context, state) {
          if (state is RegistrationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Usuario registrado correctamente. Inicia sesión'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          } else if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 40),
                const Text(
                  'Sombri-ya',
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const Text(
                          'Regístrate',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Icon(Icons.person, size: 50, color: Color(0xFF001242)),
                        const SizedBox(height: 15),

                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _decor('Correo electrónico', 'correo@ejemplo.com'),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Ingresa tu correo';
                            final re = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                            if (!re.hasMatch(v)) return 'Ingresa un correo válido';
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),

                        TextFormField(
                          controller: nameController,
                          inputFormatters: [LengthLimitingTextInputFormatter(30)],
                          decoration: _decor('Nombre', 'Nombre'),
                          validator: (v) => (v == null || v.isEmpty) ? 'Ingresa tu nombre' : null,
                        ),
                        const SizedBox(height: 15),

                        TextFormField(
                          controller: passwordController,
                          inputFormatters: [LengthLimitingTextInputFormatter(30)],
                          obscureText: true,
                          decoration: _decor('Contraseña', 'Contraseña'),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
                            if (v.length < 6) return 'Debe tener al menos 6 caracteres';
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),

                        TextFormField(
                          controller: confirmPasswordController,
                          inputFormatters: [LengthLimitingTextInputFormatter(30)],
                          obscureText: true,
                          decoration: _decor('Confirmar contraseña', 'Contraseña'),
                          validator: (v) => (v == null || v.isEmpty) ? 'Confirma tu contraseña' : null,
                        ),

                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    final loading = state is AuthLoading;
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF001242),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        padding: const EdgeInsets.symmetric(horizontal: 70, vertical: 15),
                      ),
                      onPressed: loading ? null : _submit,
                      child: Text(loading ? 'Registrando…' : 'Registrar', style: const TextStyle(fontSize: 20)),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _decor(String label, String hint) => InputDecoration(
    labelText: label,
    hintText: hint,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    filled: true,
    fillColor: const Color(0xFFF2F2F2),
    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
  );
}
