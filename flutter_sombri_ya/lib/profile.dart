import 'package:flutter/material.dart';
import 'theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:local_auth/local_auth.dart';

import 'profile_dialogs.dart';
import 'login.dart';
import 'main.dart';

class UserProfile {
  final String id;
  String name;
  String email;
  int minutesDry;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.minutesDry,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      minutesDry: json['minutesDry'] ?? 0,
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<StatefulWidget> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final storage = const FlutterSecureStorage();

  UserProfile? _user;
  bool _loading = true;
  double? _totalDistanceKm;
  final double goalKm = 5.0;
  final LocalAuthentication auth = LocalAuthentication();



  @override
  void initState() {
    super.initState();
    _loadUserProfile().then((_) => _loadTotalDistance());
  }

  Future<void> _updateUserField(String field, dynamic value) async {
    if (_user == null) return;
    final token = await storage.read(key: 'auth_token');
    if (token == null) return;

    final url = Uri.parse(
        "https://sombri-ya-back-4def07fa1804.herokuapp.com/users/${_user!.id}");

    final response = await http.put(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({field: value}),
    );

    if (response.statusCode == 200) {
      print("Usuario actualizado: ${response.body}");
    } else {
      print("Error al actualizar: ${response.statusCode} ${response.body}");
    }
  }

  Future<void> _loadTotalDistance() async {
    if (_user == null) return;
    final token = await storage.read(key: 'auth_token');
    if (token == null) return;

    final url = Uri.parse(
      "https://sombri-ya-back-4def07fa1804.herokuapp.com/users/${_user!
          .id}/total-distance",
    );

    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _totalDistanceKm = (data['totalDistanceKm'] as num).toDouble();
        });
        final double goalKm = 5.0;
        final double progress = (_totalDistanceKm ?? 0) / goalKm;
      } else {
        print("Error al obtener distancia: ${response.statusCode}");
      }
    } catch (e) {
      print("Excepción en _loadTotalDistance: $e");
    }
  }

  Future<bool> _authenticateUser() async {
    try {
      final bool isSupported = await auth.isDeviceSupported();
      final bool canCheck = await auth.canCheckBiometrics;
      final biometrics = await auth.getAvailableBiometrics();

      if (!isSupported && !canCheck) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Tu dispositivo no admite autenticación biométrica o PIN."),
            backgroundColor: Colors.redAccent,
          ),
        );
        return false;
      }


      final bool didAuthenticate = await auth.authenticate(
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
            biometricHint: 'Usa tu huella o PIN del dispositivo',
            biometricNotRecognized: 'No reconocido. Intenta de nuevo.',
            biometricSuccess: 'Autenticación exitosa',
            biometricRequiredTitle: 'Autenticación necesaria',
            deviceCredentialsRequiredTitle: 'Usa tu PIN o patrón',
            deviceCredentialsSetupDescription: 'Configura un PIN o patrón en Ajustes',
          ),
        ],
      );

      return didAuthenticate;
    } on PlatformException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error en autenticación: ${e.message}")),
      );
      return false;
    } catch (e) {
      print("Error en autenticación: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error al verificar tu identidad."),
          backgroundColor: Colors.redAccent,
        ),
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
      builder: (context) {
        return Padding(
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF001242),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  final success = await _authenticateUser();
                  if (success) {
                    onConfirm();
                  }
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }



  Future<void> _loadUserProfile() async {
    final token = await storage.read(key: 'auth_token');

    if (token == null) {
      setState(() {
        _loading = false;
      });
      return;
    }

    final url = Uri.parse(
        "https://sombri-ya-back-4def07fa1804.herokuapp.com/auth/me");

    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _user = UserProfile.fromJson(data);
          _loading = false;
        });
      } else {
        print("Error al cargar perfil: ${response.body}");
        setState(() {
          _loading = false;
        });
      }
    } catch (e) {
      print(" Excepción al cargar perfil: $e");
      setState(() {
        _loading = false;
      });
    }
  }

  void _logout() async {
    await storage.delete(key: 'accessToken');

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const MyApp()),
          (Route<dynamic> route) => false,
    );
  }

  void _editName() async {
    if (_user == null) return;

    _showVerificationPanel(() async {
      final newName = await showEditFieldDialog(
        context: context,
        title: 'Nombre',
        initialValue: _user!.name,
      );

      if (newName != null && newName.isNotEmpty) {
        setState(() {
          _user!.name = newName;
        });
        await _updateUserField("name", newName);
      }
    });
  }

  void _editEmail() async {
    if (_user == null) return;

    _showVerificationPanel(() async {
      final newEmail = await showEditFieldDialog(
        context: context,
        title: 'Email',
        initialValue: _user!.email,
        keyboardType: TextInputType.emailAddress,
      );

      if (newEmail != null && newEmail.isNotEmpty) {
        setState(() {
          _user!.email = newEmail;
        });
        await _updateUserField("email", newEmail);
      }
    });
  }

  void _editPassword() async {
    _showVerificationPanel(() {
      showChangePasswordDialog(context);
    });
  }


  void _deactivateAccount() {
    _showConfirmationDialog(
      title: 'Desactivar Cuenta',
      content:
      'Al desactivar la cuenta, no recibirás más notificaciones y tus subscripciones se suspenderán al final del periodo de pago actual. ¿Estás seguro?',
      onConfirm: () {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
              (Route<dynamic> route) => false,
        );
      },
    );
  }

  void _deleteAccount() {
    _showConfirmationDialog(
      title: 'Borrar Cuenta',
      content:
      'Esta acción es permanente y no se puede deshacer. Se borrarán todos tus datos, historial y subscripciones. ¿Estás seguro de que quieres continuar?',
      onConfirm: () {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
              (Route<dynamic> route) => false,
        );
      },
    );
  }

  void _showConfirmationDialog({
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Regresar'),
              ),
              ElevatedButton(
                onPressed: onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppThem.accent,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Confirmar'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_user == null) {
      return const Scaffold(
        body: Center(child: Text("No se pudo cargar el perfil.")),
      );
    }

    final double goalKm = 5.0;
    final double dryProgress = (_totalDistanceKm ?? 0) / goalKm;

    return Scaffold(
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
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            Text(
              "Te has mantenido seco durante",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            CircularPercentIndicator(
              radius: 80.0,
              lineWidth: 5.0,
              percent: dryProgress.clamp(0, 1),
              center: const Icon(
                  Icons.sunny, size: 50, color: Color(0xFFFCE55F)),
              progressColor: const Color(0xFF001242),
              backgroundColor: Colors.grey[300]!,
              animation: true,
              circularStrokeCap: CircularStrokeCap.round,
            ),
            const SizedBox(height: 10),
            Text(
              "${_totalDistanceKm?.toStringAsFixed(2) ?? '0'} km de ${goalKm
                  .toStringAsFixed(0)} km",
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),

            const SizedBox(height: 40),
            buildProfileItem('Nombre', _user!.name, _editName),
            const SizedBox(height: 20),
            buildProfileItem('Contraseña', '*********', _editPassword),
            const SizedBox(height: 20),
            buildProfileItem('Email', _user!.email, _editEmail),

            const SizedBox(height: 50),
            buildActionButton(
                'Cerrar Sesión', Colors.redAccent, Colors.white, _logout),
          ],
        ),
      ),
    );
  }

  Widget buildProfileItem(String label, String value, VoidCallback onTap) {
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
            Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Row(
              children: [
                Text(value, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildActionButton(
      String text, Color backgroundColor, Color textColor, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: Text(text, style: TextStyle(color: textColor, fontSize: 18)),
      ),
    );
  }
}