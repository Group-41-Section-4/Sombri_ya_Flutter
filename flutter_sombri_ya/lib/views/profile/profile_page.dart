import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../presentation/blocs/profile/profile_bloc.dart';
import '../../presentation/blocs/profile/profile_event.dart';
import '../../presentation/blocs/profile/profile_state.dart';
import '../../../data/repositories/profile_repository.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _storage = const FlutterSecureStorage();
  late final ProfileBloc _bloc;
  String? _userId;

  static const int _nameMax = 30;
  static const int _emailMax = 254;
  static const int _phoneMax = 20;
  static const int _passMin = 8;
  static const int _passMax = 64;

  @override
  void initState() {
    super.initState();
    _bloc = ProfileBloc(repository: ProfileRepository());
    _loadUser();
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final id = await _storage.read(key: 'user_id');
    if (!mounted) return;
    setState(() => _userId = id);
    if (id != null && id.isNotEmpty) {
      _bloc.add(LoadProfile(id));
    }
  }

  Future<void> _onRefresh() async {
    if (_userId != null && _userId!.isNotEmpty) {
      _bloc.add(RefreshProfile(_userId!));
    }
  }

  String _val(Map<String, dynamic>? p, String key, {String fallback = '-'}) {
    final v = p?[key];
    if (v == null) return fallback;
    if (v is String && v.trim().isEmpty) return fallback;
    return '$v';
  }

  String? _validateName(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Ingresa un nombre';
    if (v.length > _nameMax) return 'Máximo $_nameMax caracteres';
    final ok = RegExp(r"^[A-Za-zÀ-ÿ\u00f1\u00d1' -]+$").hasMatch(v);
    if (!ok) return 'Usa solo letras y espacios';
    return null;
  }

  String? _validateEmail(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Ingresa un correo';
    if (v.length > _emailMax) return 'Máximo $_emailMax caracteres';
    final ok = RegExp(
      r"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$",
      caseSensitive: false,
    ).hasMatch(v);
    if (!ok) return 'Correo no válido';
    return null;
  }

  String? _validatePhone(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Ingresa un teléfono';
    if (v.length > _phoneMax) return 'Máximo $_phoneMax caracteres';
    final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 7 || digits.length > 15) {
      return 'Debe tener entre 7 y 15 dígitos';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final v = (value ?? '').trim();
    if (v.length < _passMin) return 'Mínimo $_passMin caracteres';
    if (v.length > _passMax) return 'Máximo $_passMax caracteres';
    final hasLower = RegExp(r'[a-z]').hasMatch(v);
    final hasUpper = RegExp(r'[A-Z]').hasMatch(v);
    final hasDigit = RegExp(r'\d').hasMatch(v);
    final hasSpec  = RegExp(r'[^\w\s]').hasMatch(v);
    if (!(hasLower && hasUpper && hasDigit && hasSpec)) {
      return 'Debe incluir mayúscula, minúscula, número y símbolo';
    }
    return null;
  }

  Future<void> _showEditFieldDialog({
    required String title,
    required String fieldKey,
    required String initialValue,
    required String? Function(String?) validator,
    List<TextInputFormatter> inputFormatters = const [],
    TextInputType keyboardType = TextInputType.text,
  }) async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController(text: initialValue);

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Cambiar $title'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              autofocus: true,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
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
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop(controller.text.trim());
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (result != null && _userId != null) {
      _bloc.add(UpdateProfileField(
        userId: _userId!,
        fieldKey: fieldKey,
        newValue: result,
      ));
    }
  }

  Future<void> _showChangePasswordDialog() async {
    final formKey = GlobalKey<FormState>();
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cambiar Contraseña'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: currentController,
                    obscureText: true,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Ingresa tu contraseña actual' : null,
                    decoration: InputDecoration(
                      labelText: 'Contraseña Actual',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: newController,
                    obscureText: true,
                    maxLength: _passMax,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(_passMax),
                    ],
                    validator: (v) => _validatePassword(v),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: InputDecoration(
                      labelText: 'Nueva Contraseña',
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: confirmController,
                    obscureText: true,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Confirma la nueva contraseña';
                      if (v != newController.text) return 'No coincide';
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: 'Confirmar Nueva Contraseña',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop(true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (ok == true && _userId != null) {
      _bloc.add(ChangePassword(
        userId: _userId!,
        currentPassword: currentController.text.trim(),
        newPassword: newController.text.trim(),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF90E0EF),
          centerTitle: true,
          title: Text(
            'Perfil',
            style: GoogleFonts.cormorantGaramond(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: BlocListener<ProfileBloc, ProfileState>(
          listenWhen: (prev, curr) =>
              prev.successMessage != curr.successMessage ||
              prev.errorMessage != curr.errorMessage,
          listener: (context, state) {
            if (state.successMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.successMessage!), backgroundColor: Colors.green),
              );
              _bloc.add(const ClearProfileMessages());
            }
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.errorMessage!), backgroundColor: Colors.red),
              );
              _bloc.add(const ClearProfileMessages());
            }
          },
          child: RefreshIndicator(
            onRefresh: _onRefresh,
            child: BlocBuilder<ProfileBloc, ProfileState>(
              builder: (context, state) {
                if (_userId == null || _userId!.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.loading && state.profile == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                final profile = state.profile ?? const <String, dynamic>{};

                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: 40,
                        child: Text(
                          _val(profile, 'name', fallback: 'U')[0].toUpperCase(),
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        _val(profile, 'name', fallback: 'Sin nombre'),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        _val(profile, 'email', fallback: 'correo@dominio.com'),
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        children: [
                          _ProfileTile(
                            icon: Icons.person_outline,
                            title: 'Nombre',
                            value: _val(profile, 'name'),
                            onEdit: () => _showEditFieldDialog(
                              title: 'Nombre',
                              fieldKey: 'name',
                              initialValue: _val(profile, 'name', fallback: ''),
                              validator: _validateName,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(_nameMax),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          _ProfileTile(
                            icon: Icons.email_outlined,
                            title: 'Correo',
                            value: _val(profile, 'email'),
                            onEdit: () => _showEditFieldDialog(
                              title: 'Correo',
                              fieldKey: 'email',
                              initialValue: _val(profile, 'email', fallback: ''),
                              keyboardType: TextInputType.emailAddress,
                              validator: _validateEmail,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(_emailMax),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          _ProfileTile(
                            icon: Icons.phone_outlined,
                            title: 'Teléfono',
                            value: _val(profile, 'phone'),
                            onEdit: () => _showEditFieldDialog(
                              title: 'Teléfono',
                              fieldKey: 'phone',
                              initialValue: _val(profile, 'phone', fallback: ''),
                              keyboardType: TextInputType.phone,
                              validator: _validatePhone,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(_phoneMax),
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9 +()\-\.]'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    ElevatedButton.icon(
                      onPressed: _showChangePasswordDialog,
                      icon: const Icon(Icons.lock_reset),
                      label: const Text('Cambiar contraseña'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),

                    if (state.loading) ...[
                      const SizedBox(height: 16),
                      const LinearProgressIndicator(),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onEdit;

  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.black54),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(value),
      trailing: IconButton(icon: const Icon(Icons.edit_outlined), onPressed: onEdit),
    );
  }
}
