import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_sombri_ya/presentation/blocs/profile/profile_bloc.dart';
import 'package:flutter_sombri_ya/presentation/blocs/profile/profile_event.dart';
import 'package:flutter_sombri_ya/presentation/blocs/profile/profile_state.dart';
import '../../main.dart';

class ManageAccountPage extends StatelessWidget {
  const ManageAccountPage({super.key});
  static const int _nameMax = 20, _emailMax = 40, _passMax = 12;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String? _validateName(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Ingresa un nombre';
    if (s.length > _nameMax) return 'Máximo $_nameMax caracteres';
    if (!RegExp(r"^[A-Za-zÀ-ÿ\u00f1\u00d1' -]+$").hasMatch(s)) {
      return 'Solo letras y espacios';
    }
    return null;
  }

  String? _validateEmail(String? v) {
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

  String? _validateNewPassword(String? v) {
    final s = (v ?? '').trim();
    if (s.length < 8 || s.length > _passMax) {
      return '8–$_passMax caracteres';
    }
    final ok =
        RegExp(r'[a-z]').hasMatch(s) &&
        RegExp(r'[A-Z]').hasMatch(s) &&
        RegExp(r'\d').hasMatch(s) &&
        RegExp(r'[^\w\s]').hasMatch(s);
    return ok ? null : 'Incluye mayúscula, minúscula, número y símbolo';
  }

  Future<void> _logout(BuildContext context) async {
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'user_id');
    await _storage.delete(key: 'user_name');

    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (route) => false,
    );
  }

  void _deleteAccount(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Cuenta'),
        content: const Text(
          'Esta funcionalidad aún no está disponible. '
          'Pronto podrás solicitar la eliminación de tu cuenta desde la app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    ProfileBloc bloc,
    String userId,
    String fieldKey,
    String currentValue,
  ) {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController(text: currentValue);

    String label;
    int maxLength;
    TextInputType keyboardType = TextInputType.text;
    String? Function(String?) validator;

    switch (fieldKey) {
      case 'name':
        label = 'Nombre';
        maxLength = _nameMax;
        validator = _validateName;
        break;
      case 'email':
        label = 'Correo';
        maxLength = _emailMax;
        keyboardType = TextInputType.emailAddress;
        validator = _validateEmail;
        break;
      default:
        return;
    }

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Cambiar $label'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              maxLength: maxLength,
              keyboardType: keyboardType,
              validator: validator,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: InputDecoration(
                labelText: 'Nuevo $label',
                border: const OutlineInputBorder(),
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
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(context);
                final newValue = controller.text.trim();
                if (newValue.isNotEmpty && userId.isNotEmpty) {
                  bloc.add(
                    UpdateProfileField(
                      userId: userId,
                      fieldKey: fieldKey,
                      newValue: newValue,
                    ),
                  );
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void _showChangePasswordDialog(
    BuildContext context,
    ProfileBloc bloc,
    String userId,
  ) {
    final formKey = GlobalKey<FormState>();
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cambiar Contraseña'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: currentController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña Actual',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Ingresa tu contraseña actual'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: newController,
                  obscureText: true,
                  maxLength: _passMax,
                  decoration: const InputDecoration(
                    labelText: 'Nueva Contraseña',
                    border: OutlineInputBorder(),
                    counterText: '',
                  ),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: _validateNewPassword,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: confirmController,
                  obscureText: true,
                  maxLength: _passMax,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar Nueva Contraseña',
                    border: OutlineInputBorder(),
                    counterText: '',
                  ),
                  validator: (v) =>
                      (v ?? '') == newController.text ? null : 'No coincide',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(context);
                final current = currentController.text.trim();
                final newPass = newController.text.trim();
                if (current.isNotEmpty &&
                    newPass.isNotEmpty &&
                    userId.isNotEmpty) {
                  bloc.add(
                    ChangePassword(
                      userId: userId,
                      currentPassword: current,
                      newPassword: newPass,
                    ),
                  );
                }
              },
              child: const Text('Cambiar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ProfileBloc>();

    return BlocConsumer<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${state.errorMessage}')),
          );
          bloc.add(const ClearProfileMessages());
        }
        if (state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Éxito: ${state.successMessage}')),
          );
          bloc.add(const ClearProfileMessages());
        }
      },
      builder: (context, state) {
        final name = state.profile?['name'] ?? 'Cargando...';
        final email = state.profile?['email'] ?? 'cargando@email.com';
        final userId = (state.profile?['id'] ?? '').toString();

        return Scaffold(
          backgroundColor: const Color(0xFFFFFDFD),
          appBar: AppBar(
            title: Text(
              'Administrar Cuenta',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: const Color(0xFF90E0EF),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ManageItem(
                  icon: Icons.badge_outlined,
                  title: 'Cambiar Nombre',
                  subtitle: name,
                  onTap: () =>
                      _showEditDialog(context, bloc, userId, 'name', name),
                ),
                _ManageItem(
                  icon: Icons.email_outlined,
                  title: 'Cambiar Correo',
                  subtitle: email,
                  onTap: () =>
                      _showEditDialog(context, bloc, userId, 'email', email),
                ),
                _ManageItem(
                  icon: Icons.lock_outline,
                  title: 'Cambiar Contraseña',
                  subtitle: '********',
                  onTap: () => _showChangePasswordDialog(context, bloc, userId),
                ),
                _ManageItem(
                  icon: Icons.camera_alt_outlined,
                  title: 'Editar Foto',
                  subtitle: 'Editar tu foto de perfil',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Funcionalidad de Edición de Foto Pendiente',
                        ),
                      ),
                    );
                  },
                ),
                const Divider(height: 30, thickness: 1),
                _ActionItem(
                  icon: Icons.logout,
                  title: 'Cerrar Sesión',
                  color: Colors.orange,
                  onTap: () => _logout(context),
                ),
                const SizedBox(height: 12),
                _ActionItem(
                  icon: Icons.delete_forever,
                  title: 'Eliminar Cuenta',
                  color: Colors.red,
                  onTap: () => _deleteAccount(context),
                ),
                if (state.loading)
                  const Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: LinearProgressIndicator(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ManageItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ManageItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF90E0EF), size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _ActionItem({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
