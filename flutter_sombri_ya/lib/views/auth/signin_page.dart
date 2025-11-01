import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';

import '../../presentation/blocs/auth/auth_bloc.dart';
import '../../presentation/blocs/auth/auth_event.dart';
import '../../presentation/blocs/auth/auth_state.dart';

import '../../presentation/blocs/connectivity/connectivity_cubit.dart';
import '../../core/connectivity/connectivity_service.dart';

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

  ConnectivityStatus? _effectiveNet;
  Timer? _offlineGrace;

  @override
  void initState() {
    super.initState();
    _effectiveNet = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<ConnectivityCubit?>();
      cubit?.retry();

      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        if (_effectiveNet == null) {
          setState(() => _effectiveNet = ConnectivityStatus.online);
        }
      });
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    nameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    _offlineGrace?.cancel();
    _offlineGrace = null;
    super.dispose();
  }

  void _submit() {
    final isOffline = _effectiveNet == ConnectivityStatus.offline;

    if (isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sin conexión. Revisa tu internet e inténtalo de nuevo.',
          ),
        ),
      );
      return;
    }

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
    return BlocProvider<ConnectivityCubit>(
      create: (_) => ConnectivityCubit(ConnectivityService())..start(),
      child: _SigninScaffold(
        formKey: _formKey,
        emailController: emailController,
        nameController: nameController,
        passwordController: passwordController,
        confirmPasswordController: confirmPasswordController,
        submit: _submit,
        effectiveNet: _effectiveNet,
        onConnectivity: (status) {
          if (status == ConnectivityStatus.online) {
            _offlineGrace?.cancel();
            _offlineGrace = null;
            if (_effectiveNet != ConnectivityStatus.online) {
              setState(() => _effectiveNet = ConnectivityStatus.online);
            }
          } else {
            _offlineGrace?.cancel();
            _offlineGrace = Timer(const Duration(milliseconds: 700), () {
              if (mounted && _effectiveNet != ConnectivityStatus.offline) {
                setState(() => _effectiveNet = ConnectivityStatus.offline);
              }
            });
          }
        },
      ),
    );
  }
}

class _SigninScaffold extends StatelessWidget {
  const _SigninScaffold({
    required this.formKey,
    required this.emailController,
    required this.nameController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.submit,
    required this.effectiveNet,
    required this.onConnectivity,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController nameController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final VoidCallback submit;
  final ConnectivityStatus? effectiveNet;
  final void Function(ConnectivityStatus) onConnectivity;

  @override
  Widget build(BuildContext context) {
    final isUnknown = effectiveNet == null;
    final offline = effectiveNet == ConnectivityStatus.offline;

    return Scaffold(
      backgroundColor: const Color(0xFF90E0EF),
      body: MultiBlocListener(
        listeners: [
          BlocListener<ConnectivityCubit, ConnectivityStatus>(
            listener: (context, status) => onConnectivity(status),
          ),
          BlocListener<AuthBloc, AuthState>(
            listenWhen: (p, c) => c is RegistrationSuccess || c is AuthFailure,
            listener: (context, state) {
              if (state is RegistrationSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Usuario registrado correctamente. Inicia sesión',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context);
              } else if (state is AuthFailure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ],
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                children: [
                  if (!isUnknown && offline)
                    Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.wifi_off),
                          SizedBox(width: 8),
                          Expanded(child: Text('Sin conexión a internet')),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),
                  const Text(
                    'Sombri-ya',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF001242),
                    ),
                  ),
                  const SizedBox(height: 30),

                  AbsorbPointer(
                    absorbing: isUnknown || offline,
                    child: Opacity(
                      opacity: (isUnknown || offline) ? 0.6 : 1.0,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFDFD),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey, width: 2),
                        ),
                        child: Form(
                          key: formKey,
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
                              const Icon(
                                Icons.person,
                                size: 50,
                                color: Color(0xFF001242),
                              ),
                              const SizedBox(height: 15),

                              TextFormField(
                                controller: emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: _decor(
                                  'Correo electrónico',
                                  'correo@ejemplo.com',
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty)
                                    return 'Ingresa tu correo';
                                  final re = RegExp(
                                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                  );
                                  if (!re.hasMatch(v))
                                    return 'Ingresa un correo válido';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 15),

                              TextFormField(
                                controller: nameController,
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(30),
                                ],
                                decoration: _decor('Nombre', 'Nombre'),
                                validator: (v) => (v == null || v.isEmpty)
                                    ? 'Ingresa tu nombre'
                                    : null,
                              ),
                              const SizedBox(height: 15),

                              TextFormField(
                                controller: passwordController,
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(30),
                                ],
                                obscureText: true,
                                decoration: _decor('Contraseña', 'Contraseña'),
                                validator: (v) {
                                  if (v == null || v.isEmpty)
                                    return 'Ingresa tu contraseña';
                                  if (v.length < 6)
                                    return 'Debe tener al menos 6 caracteres';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 15),

                              TextFormField(
                                controller: confirmPasswordController,
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(30),
                                ],
                                obscureText: true,
                                decoration: _decor(
                                  'Confirmar contraseña',
                                  'Contraseña',
                                ),
                                validator: (v) => (v == null || v.isEmpty)
                                    ? 'Confirma tu contraseña'
                                    : null,
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final loading = state is AuthLoading;

                      final disable = loading || isUnknown || offline;
                      final label = isUnknown
                          ? 'Conectando…'
                          : (offline
                                ? 'Sin conexión'
                                : (loading ? 'Registrando…' : 'Registrar'));

                      return ElevatedButton(
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
                        onPressed: disable ? null : submit,
                        child: Text(
                          label,
                          style: const TextStyle(fontSize: 20),
                        ),
                      );
                    },
                  ),
                ],
              ),
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
