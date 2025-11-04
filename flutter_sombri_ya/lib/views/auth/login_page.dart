import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';

import '../../core/services/secure_storage_service.dart';
import '../../data/repositories/auth_repository.dart';
import '../../presentation/blocs/auth/auth_bloc.dart';
import '../../presentation/blocs/auth/auth_event.dart';
import '../../presentation/blocs/auth/auth_state.dart';

import '../../../core/providers/api_provider.dart';
import '../../presentation/blocs/auth/forgot_password/forgot_password_bloc.dart';
import 'signin_page.dart';
import '../home/home_page.dart';
import 'forgot_password_page.dart';

import '../../presentation/blocs/connectivity/connectivity_cubit.dart';
import '../../core/connectivity/connectivity_service.dart';

import '../../core/services/local_prefs.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _rememberEmail = true;

  ConnectivityStatus? _effectiveNet;
  Timer? _offlineGrace;

  @override
  void initState() {
    super.initState();

    final prefs = context.read<LocalPrefs>();
    _rememberEmail = prefs.getRememberEmail();
    final last = prefs.getLastEmail();
    if (_rememberEmail && last != null && last.isNotEmpty) {
      _emailCtrl.text = last;
    }
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
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _offlineGrace?.cancel();
    _offlineGrace = null;
    super.dispose();
  }

  void _submitLogin() {
    if (!_formKey.currentState!.validate()) return;

    //DEBUG:
    assert(() {
      print('[DEBUG] AuthBloc encontrado en LoginPage: OK');
      return true;
    }());
    context.read<AuthBloc>().add(
      LoginWithPasswordSubmitted(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ConnectivityCubit>(
      create: (_) => ConnectivityCubit(ConnectivityService())..start(),
      child: _LoginScaffold(
        formKey: _formKey,
        emailCtrl: _emailCtrl,
        passCtrl: _passCtrl,
        submitLogin: _submitLogin,
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

        rememberEmail: _rememberEmail,
        onRememberChanged: (val) async {
          setState(() => _rememberEmail = val);
          final prefs = context.read<LocalPrefs>();
          await prefs.setRememberEmail(val);
          if (!val) await prefs.clearLastEmail();
        },
      ),
    );
  }
}

class _LoginScaffold extends StatelessWidget {
  const _LoginScaffold({
    required this.formKey,
    required this.emailCtrl,
    required this.passCtrl,
    required this.submitLogin,
    required this.effectiveNet,
    required this.onConnectivity,
    required this.rememberEmail,
    required this.onRememberChanged,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final VoidCallback submitLogin;

  final ConnectivityStatus? effectiveNet;
  final void Function(ConnectivityStatus) onConnectivity;

  final bool rememberEmail;
  final void Function(bool) onRememberChanged;


  @override
  Widget build(BuildContext context) {
    final isUnknown = effectiveNet == null;
    final isOnline = effectiveNet == ConnectivityStatus.online;
    final isOffline = effectiveNet == ConnectivityStatus.offline;

    return Scaffold(
      backgroundColor: const Color(0xFF90E0EF),
      body: MultiBlocListener(
        listeners: [
          BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              debugPrint('[AuthBloc] state => ${state.runtimeType}');
            },
          ),
          BlocListener<AuthBloc, AuthState>(
            listenWhen: (prev, curr) =>
                curr is AuthAuthenticated || curr is AuthFailure,
            listener: (context, state) {
              if (state is AuthAuthenticated) {
                final prefs = context.read<LocalPrefs>();
                if (prefs.getRememberEmail()) {
                  final email = emailCtrl.text.trim();
                  if (email.isNotEmpty) {
                    prefs.setLastEmail(email);
                  }
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Inicio de sesión exitoso'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const HomePage()),
                );
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
          BlocListener<ConnectivityCubit, ConnectivityStatus>(
            listener: (context, status) => onConnectivity(status),
          ),
        ],
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 40),
                const Text(
                  'Sombri-Ya',
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
                    key: formKey,
                    child: Column(
                      children: [
                        const Text(
                          'Iniciar sesión',
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
                          controller: emailCtrl,
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
                            if (!re.hasMatch(v)) return 'Correo inválido';
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),

                        TextFormField(
                          controller: passCtrl,
                          obscureText: true,
                          decoration: _decor('Contraseña', 'Contraseña'),
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Ingresa tu contraseña'
                              : null,
                        ),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: rememberEmail,
                              onChanged: (v) => onRememberChanged(v ?? true),
                            ),
                            const Text('Recordar correo'),
                          ],
                        ),

                        const SizedBox(height: 16),

                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          child: isUnknown
                              ? Column(
                                  key: const ValueKey('connectingButtons'),
                                  children: [
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: null,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF6B7280,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: const [
                                            SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                            SizedBox(width: 10),
                                            Text('Conectando…'),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : (isOnline
                                    ? Column(
                                        key: const ValueKey('onlineButtons'),
                                        children: [
                                          SizedBox(
                                            width: double.infinity,
                                            child: BlocBuilder<AuthBloc, AuthState>(
                                              builder: (context, state) {
                                                final loading =
                                                    state is AuthLoading;
                                                return ElevatedButton(
                                                  onPressed: loading
                                                      ? null
                                                      : submitLogin,
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        const Color(0xFF001242),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                    ),
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 14,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    loading
                                                        ? 'Ingresando…'
                                                        : 'Iniciar sesión',
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      color: Color(0xFFFFFDFD),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          SizedBox(
                                            width: double.infinity,
                                            child: OutlinedButton.icon(
                                              onPressed: () =>
                                                  context.read<AuthBloc>().add(
                                                    const LoginWithGoogleRequested(),
                                                  ),
                                              icon: SizedBox(
                                                width: 10,
                                                height: 10,
                                                child: Image.asset(
                                                  'assets/images/google_logo2.png',
                                                  fit: BoxFit.contain,
                                                ),
                                              ),
                                              label: const Text(
                                                'Iniciar sesión con Google',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              style: OutlinedButton.styleFrom(
                                                side: const BorderSide(
                                                  color: Colors.grey,
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 14,
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    : Column(
                                        key: const ValueKey('offlineButtons'),
                                        children: [
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton.icon(
                                              onPressed: () => context
                                                  .read<ConnectivityCubit>()
                                                  .retry(),
                                              icon: const Icon(Icons.refresh),
                                              label: const Text(
                                                'Reintentar conexión',
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(
                                                  0xFF6B7280,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 14,
                                                    ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          const Text(
                                            'Sin conexión. Asegúrate de estar conectado a la red.',
                                            style: TextStyle(
                                              color: Colors.orange,
                                            ),
                                          ),
                                        ],
                                      )),
                        ),

                        const SizedBox(height: 20),

                        Builder(
                          builder: (context) {
                            final authLoading =
                                context.watch<AuthBloc>().state is AuthLoading;
                            final linksEnabled = isOnline && !authLoading;
                            return _LinksBlock(linksEnabled: linksEnabled);
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                const Text(
                  'Sombri-Ya',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ahorra tiempo y mantente\nseco en cualquier trayecto',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF001242), fontSize: 14),
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

class _LinksBlock extends StatelessWidget {
  const _LinksBlock({required this.linksEnabled});

  final bool linksEnabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: linksEnabled
                ? () {
                    final api = context.read<ApiProvider>();
                    final repo = AuthRepository(
                      api: api,
                      storage: const SecureStorageService(),
                    );

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider(
                          create: (_) => ForgotPasswordBloc(repo: repo),
                          child: const ForgotPasswordPage(),
                        ),
                      ),
                    );
                  }
                : null,
            child: Text(
              '¿Olvidaste tu contraseña?',
              style: TextStyle(
                color: linksEnabled ? Colors.grey : Colors.grey.shade400,
                fontSize: 12,
                decoration: linksEnabled
                    ? TextDecoration.underline
                    : TextDecoration.none,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: linksEnabled
                ? () {
                    final api = context.read<ApiProvider>();
                    final authBloc = context.read<AuthBloc>();

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RepositoryProvider.value(
                          value: api,
                          child: BlocProvider.value(
                            value: authBloc,
                            child: const SigninPage(),
                          ),
                        ),
                      ),
                    );
                  }
                : null,
            child: Text(
              '¿No tienes una cuenta? Regístrate',
              style: TextStyle(
                color: linksEnabled ? Colors.grey : Colors.grey.shade400,
                fontSize: 12,
                decoration: linksEnabled
                    ? TextDecoration.underline
                    : TextDecoration.none,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
