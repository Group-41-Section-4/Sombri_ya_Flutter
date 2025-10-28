import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../main.dart';

import 'package:flutter_sombri_ya/presentation/blocs/profile/profile_bloc.dart';
import 'package:flutter_sombri_ya/presentation/blocs/profile/profile_event.dart';
import 'package:flutter_sombri_ya/presentation/blocs/profile/profile_state.dart';
import 'package:flutter_sombri_ya/data/repositories/profile_repository.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _storage = const FlutterSecureStorage();
  final _auth = LocalAuthentication();
  late final ProfileBloc _bloc;
  String? _userId;

  static const double _goalKm = 5.0;

  static const int _nameMax = 20, _emailMax = 40, _passMax = 12;

  @override
  void initState() {
    super.initState();
    _bloc = ProfileBloc(repository: ProfileRepository());
    _init();
  }

  Future<void> _init() async {
    final id = await _storage.read(key: 'user_id');
    if (!mounted) return;
    setState(() => _userId = id);
    if (id != null && id.isNotEmpty) _bloc.add(LoadProfile(id));
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  Future<bool> _authenticateUser() async {
    try {
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      if (!supported && !canCheck) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tu dispositivo no admite biometría o PIN.'),
          ),
        );
        return false;
      }
      final ok = await _auth.authenticate(
        localizedReason: 'Confirma tu identidad para continuar',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
        authMessages: const <AuthMessages>[
          AndroidAuthMessages(
            signInTitle: 'Verificación requerida',
            cancelButton: 'Cancelar',
            biometricHint: 'Usa tu huella o PIN',
            biometricNotRecognized: 'No reconocido',
            biometricSuccess: 'Autenticación exitosa',
            biometricRequiredTitle: 'Autenticación necesaria',
            deviceCredentialsRequiredTitle: 'Usa tu PIN o patrón',
            deviceCredentialsSetupDescription:
                'Configura un PIN o patrón en Ajustes',
          ),
        ],
      );
      return ok;
    } on PlatformException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error en autenticación: ${e.message}')),
      );
      return false;
    }
  }

  void _showVerificationPanel(VoidCallback onConfirm) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      backgroundColor: Colors.white,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 45, color: Colors.black54),
            const SizedBox(height: 10),
            const Text(
              'Verifica tu identidad',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Confirma tu identidad para continuar.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 25),
            ElevatedButton.icon(
              icon: const Icon(Icons.verified_user),
              label: const Text('Verificar ahora'),
              onPressed: () async {
                Navigator.pop(context);
                final ok = await _authenticateUser();
                if (ok) onConfirm();
              },
            ),
          ],
        ),
      ),
    );
  }

  //Dialogues
  Future<void> _editFieldDialog({
    required String title,
    required String fieldKey,
    required String initialValue,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter> formatters = const [],
  }) async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController(text: initialValue);

    final value = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Cambiar $title'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: formatters,
            validator: validator,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: InputDecoration(
              labelText: 'Nuevo $title',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (value != null && _userId != null) {
      _bloc.add(
        UpdateProfileField(
          userId: _userId!,
          fieldKey: fieldKey,
          newValue: value,
        ),
      );
    }
  }

  Future<void> _changePasswordDialog() async {
    final formKey = GlobalKey<FormState>();
    final curr = TextEditingController();
    final next = TextEditingController();
    final confirm = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cambiar Contraseña'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: curr,
                obscureText: true,
                inputFormatters: [LengthLimitingTextInputFormatter(_passMax)],
                maxLength: _passMax,
                maxLengthEnforcement: MaxLengthEnforcement.enforced,
                decoration: const InputDecoration(
                  labelText: 'Contraseña actual',
                  counterText: '',
                ),
                validator: (v) => (v == null || v.isEmpty)
                    ? 'Ingresa tu contraseña actual'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: next,
                obscureText: true,
                inputFormatters: [LengthLimitingTextInputFormatter(_passMax)],
                maxLength: _passMax,
                maxLengthEnforcement: MaxLengthEnforcement.enforced,
                decoration: const InputDecoration(
                  labelText: 'Nueva contraseña',
                  counterText: '',
                ),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (v) {
                  final s = (v ?? '').trim();
                  if (s.length < 8 || s.length > _passMax) {
                    return '8–$_passMax caracteres';
                  }
                  final ok =
                      RegExp(r'[a-z]').hasMatch(s) &&
                      RegExp(r'[A-Z]').hasMatch(s) &&
                      RegExp(r'\d').hasMatch(s) &&
                      RegExp(r'[^\w\s]').hasMatch(s);
                  return ok
                      ? null
                      : 'Incluye mayúscula, minúscula, número y símbolo';
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirm,
                obscureText: true,
                inputFormatters: [LengthLimitingTextInputFormatter(_passMax)],
                maxLength: _passMax,
                maxLengthEnforcement: MaxLengthEnforcement.enforced,
                decoration: const InputDecoration(
                  labelText: 'Confirmar nueva contraseña',
                  counterText: '',
                ),
                validator: (v) => (v ?? '') == next.text ? null : 'No coincide',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (ok == true && _userId != null) {
      _bloc.add(
        ChangePassword(
          userId: _userId!,
          currentPassword: curr.text.trim(),
          newPassword: next.text.trim(),
        ),
      );
    }
  }

  String? _vName(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Ingresa un nombre';
    if (s.length > _nameMax) return 'Máximo $_nameMax caracteres';
    if (!RegExp(r"^[A-Za-zÀ-ÿ\u00f1\u00d1' -]+$").hasMatch(s)) {
      return 'Solo letras y espacios';
    }
    return null;
  }

  String? _vEmail(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Ingresa un correo';
    if (s.length > _emailMax) return 'Máximo $_emailMax caracteres';
    if (!RegExp(
      r"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$",
      caseSensitive: false,
    ).hasMatch(s)) {
      return 'Correo no válido';
    }
    return null;
  }

  Future<void> _logout() async {
    await _storage.delete(key: 'auth_token');
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFDFD),
        appBar: AppBar(
          title: Text(
            'Cuenta',
            style: GoogleFonts.cormorantGaramond(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFF90E0EF),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: BlocListener<ProfileBloc, ProfileState>(
          listenWhen: (p, c) =>
              p.successMessage != c.successMessage ||
              p.errorMessage != c.errorMessage,
          listener: (context, state) {
            if (state.successMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.successMessage!),
                  backgroundColor: Colors.green,
                ),
              );
              _bloc.add(const ClearProfileMessages());
            }
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: Colors.red,
                ),
              );
              _bloc.add(const ClearProfileMessages());
            }
          },
          child: BlocBuilder<ProfileBloc, ProfileState>(
            builder: (context, state) {
              if (_userId == null || state.loading && state.profile == null) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.profile == null) {
                return const Center(
                  child: Text('No se pudo cargar el perfil.'),
                );
              }

              final profile = state.profile!;
              final totalKm = state.totalDistanceKm ?? 0;
              final dryProgress = (totalKm / _goalKm).clamp(0.0, 1.0);

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      'Te has mantenido seco durante',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    CircularPercentIndicator(
                      radius: 80.0,
                      lineWidth: 5.0,
                      percent: dryProgress,
                      center: const Icon(
                        Icons.sunny,
                        size: 50,
                        color: Color(0xFFFCE55F),
                      ),
                      progressColor: const Color(0xFF001242),
                      backgroundColor: Colors.grey[300]!,
                      animation: true,
                      circularStrokeCap: CircularStrokeCap.round,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${totalKm.toStringAsFixed(2)} km de ${_goalKm.toStringAsFixed(0)} km',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 40),

                    _item(
                      'Nombre',
                      profile['name'] ?? '-',
                      onTap: () {
                        _showVerificationPanel(() {
                          _editFieldDialog(
                            title: 'Nombre',
                            fieldKey: 'name',
                            initialValue: (profile['name'] ?? '').toString(),
                            validator: _vName,
                            formatters: [
                              LengthLimitingTextInputFormatter(_nameMax),
                            ],
                          );
                        });
                      },
                    ),

                    const SizedBox(height: 20),
                    _item(
                      'Contraseña',
                      '*********',
                      onTap: () {
                        _showVerificationPanel(_changePasswordDialog);
                      },
                    ),

                    const SizedBox(height: 20),
                    _item(
                      'Email',
                      profile['email'] ?? '-',
                      onTap: () {
                        _showVerificationPanel(() {
                          _editFieldDialog(
                            title: 'Correo',
                            fieldKey: 'email',
                            initialValue: (profile['email'] ?? '').toString(),
                            keyboardType: TextInputType.emailAddress,
                            validator: _vEmail,
                            formatters: [
                              LengthLimitingTextInputFormatter(_emailMax),
                            ],
                          );
                        });
                      },
                    ),

                    const SizedBox(height: 50),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _logout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Cerrar Sesión',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ),
                    ),

                    if (state.loading) ...[
                      const SizedBox(height: 16),
                      const LinearProgressIndicator(),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _item(String label, String value, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.black, width: 1),
          boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black12)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Text(
                  value,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
