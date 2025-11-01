import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../presentation/blocs/auth/forgot_password/forgot_password_bloc.dart';
import '../../../presentation/blocs/auth/forgot_password/forgot_password_event.dart';
import '../../../presentation/blocs/auth/forgot_password/forgot_password_state.dart';

import '../../core/providers/api_provider.dart';
import '../../core/services/secure_storage_service.dart';
import '../../data/repositories/auth_repository.dart';
import '../../presentation/blocs/auth/auth_bloc.dart';

import '../../core/connectivity/connectivity_service.dart';
import '../../presentation/blocs/connectivity/connectivity_cubit.dart';

import 'login_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();

  bool _submitting = false;
  bool _retrying = false;

  ConnectivityStatus? _effectiveNet;
  Timer? _offlineGrace;

  @override
  void initState() {
    super.initState();
    _effectiveNet = null;
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _offlineGrace?.cancel();
    _offlineGrace = null;
    super.dispose();
  }

  String? _emailValidator(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'Ingresa tu correo';
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(value)) return 'Correo inválido';
    return null;
  }

  void _submit(BuildContext context, {required bool online}) {
    if (_submitting) return;
    if (!online) return;
    if (_formKey.currentState!.validate()) {
      setState(() => _submitting = true);
      context.read<ForgotPasswordBloc>().add(
        ForgotPasswordSubmitted(_emailCtrl.text.trim()),
      );
    }
  }

  Future<void> _retryConnectivity(BuildContext context) async {
    if (_retrying) return;
    setState(() => _retrying = true);
    try {
      await context.read<ConnectivityCubit>().retry();
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ConnectivityCubit>(
      create: (_) => ConnectivityCubit(ConnectivityService())..start(),
      child: Scaffold(
        backgroundColor: const Color(0xFF90E0EF),
        body: SafeArea(
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Center(
              child: SingleChildScrollView(
                child: MultiBlocListener(
                  listeners: [
                    BlocListener<ConnectivityCubit, ConnectivityStatus>(
                      listener: (context, status) {
                        if (status == ConnectivityStatus.online) {
                          _offlineGrace?.cancel();
                          _offlineGrace = null;
                          if (_effectiveNet != ConnectivityStatus.online) {
                            setState(
                              () => _effectiveNet = ConnectivityStatus.online,
                            );
                          }
                        } else {
                          _offlineGrace?.cancel();
                          _offlineGrace = Timer(
                            const Duration(milliseconds: 200),
                            () {
                              if (mounted &&
                                  _effectiveNet != ConnectivityStatus.offline) {
                                setState(
                                  () => _effectiveNet =
                                      ConnectivityStatus.offline,
                                );
                              }
                            },
                          );
                        }
                      },
                    ),
                    BlocListener<ForgotPasswordBloc, ForgotPasswordState>(
                      listener: (context, state) {
                        if (state.loading == false) {
                          setState(() => _submitting = false);
                        }
                        if (state.error != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(state.error!),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                        if (state.success != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(state.success!),
                              backgroundColor: Colors.green,
                            ),
                          );
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ],
                  child: BlocBuilder<ForgotPasswordBloc, ForgotPasswordState>(
                    builder: (context, state) {
                      final isUnknown = _effectiveNet == null;
                      final online = _effectiveNet == ConnectivityStatus.online;
                      final offline =
                          _effectiveNet == ConnectivityStatus.offline;

                      return Column(
                        children: [
                          const SizedBox(height: 32),
                          const Text(
                            "Sombri-ya",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF001242),
                            ),
                          ),
                          const SizedBox(height: 24),

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
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text(
                                    "Recuperar contraseña",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Icon(
                                    Icons.lock_reset,
                                    size: 50,
                                    color: Color(0xFF001242),
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _emailCtrl,
                                    validator: _emailValidator,
                                    keyboardType: TextInputType.emailAddress,
                                    autofillHints: const [AutofillHints.email],
                                    decoration: InputDecoration(
                                      labelText: "Correo electrónico",
                                      hintText: "correo@ejemplo.com",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      filled: true,
                                      fillColor: const Color(0xFFF2F2F2),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 10,
                                            horizontal: 15,
                                          ),
                                    ),
                                  ),

                                  if (offline)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        'Sin conexión a internet. Verifica tu red y toca "Reintentar".',
                                        style: TextStyle(
                                          color: Colors.red.shade700,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    )
                                  else
                                    const SizedBox(height: 8),

                                  const SizedBox(height: 20),

                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: isUnknown
                                          ? null
                                          : () async {
                                              if (online) {
                                                _submit(context, online: true);
                                              } else {
                                                await _retryConnectivity(
                                                  context,
                                                );
                                              }
                                            },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isUnknown
                                            ? Colors.grey[700]
                                            : (online
                                                  ? const Color(0xFF001242)
                                                  : Colors.grey[800]),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                      ),
                                      child: Builder(
                                        builder: (_) {
                                          if (isUnknown) {
                                            return const Text(
                                              "Conectando…",
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.white,
                                              ),
                                            );
                                          }
                                          final isBusy = online
                                              ? (state.loading || _submitting)
                                              : _retrying;
                                          if (isBusy) {
                                            return const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            );
                                          }
                                          return Text(
                                            online ? "Enviar" : "Reintentar",
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.white,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        const baseUrl =
                                            'https://sombri-ya-back-4def07fa1804.herokuapp.com';

                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                RepositoryProvider<ApiProvider>(
                                                  create: (_) => ApiProvider(
                                                    baseUrl: baseUrl,
                                                  ),
                                                  child: BlocProvider<AuthBloc>(
                                                    create: (ctx) => AuthBloc(
                                                      repo: AuthRepository(
                                                        api: ctx
                                                            .read<
                                                              ApiProvider
                                                            >(),
                                                        storage:
                                                            const SecureStorageService(),
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
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                      ),
                                      child: const Text(
                                        "Volver al inicio",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),
                          const Text(
                            "Sombri-Ya",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 6),
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
            ),
          ),
        ),
      ),
    );
  }
}
