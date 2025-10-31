import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_sombri_ya/data/repositories/auth_repository.dart';

class ResetPasswordPage extends StatefulWidget {
  final String userId;
  final String token;

  const ResetPasswordPage({
    super.key,
    required this.userId,
    required this.token,
  });

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _pwdCtrl = TextEditingController();
  final _pwd2Ctrl = TextEditingController();

  bool _obscure = true;
  bool _loading = false;

  static const _brandBg = Color(0xFF90E0EF);
  static const _brandDark = Color(0xFF001242);

  @override
  void dispose() {
    _pwdCtrl.dispose();
    _pwd2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final repo = context.read<AuthRepository>();
      await repo.resetPassword(
        userId: widget.userId,
        token: widget.token,
        newPassword: _pwdCtrl.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contraseña actualizada correctamente')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _validatePwd(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return 'Ingresa una contraseña';
    if (t.length < 8) return 'Mínimo 8 caracteres';
    return null;
  }

  String? _validateConfirm(String? v) {
    if (v != _pwdCtrl.text) return 'No coincide';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: _brandBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                Text(
                  'Sombrí-ya',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    color: _brandDark,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 24),

                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: width > 560 ? 520 : width,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          offset: const Offset(0, 10),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            'Restablecer contraseña',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: _brandDark,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Icon(Icons.lock, size: 48, color: _brandDark),
                          const SizedBox(height: 20),

                          TextFormField(
                            controller: _pwdCtrl,
                            obscureText: _obscure,
                            decoration: InputDecoration(
                              labelText: 'Nueva contraseña',
                              labelStyle: const TextStyle(color: Colors.black87),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: Color(0xFFBFDCEB)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: _brandDark, width: 1.4),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                                color: Colors.black54,
                                onPressed: () => setState(() => _obscure = !_obscure),
                              ),
                            ),
                            validator: _validatePwd,
                            autofillHints: const [AutofillHints.newPassword],
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 14),

                          TextFormField(
                            controller: _pwd2Ctrl,
                            obscureText: _obscure,
                            decoration: InputDecoration(
                              labelText: 'Confirmar contraseña',
                              labelStyle: const TextStyle(color: Colors.black87),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: Color(0xFFBFDCEB)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: _brandDark, width: 1.4),
                              ),
                            ),
                            validator: _validateConfirm,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                          ),

                          const SizedBox(height: 22),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _brandDark,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 14,
                                ),
                              ),
                              child: _loading
                                  ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                                  : const Text(
                                'Guardar',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
