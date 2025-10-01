import 'package:flutter/material.dart';
import 'theme.dart';
import 'package:google_fonts/google_fonts.dart';

import 'profile_dialogs.dart';
import 'login.dart';

//Temporal class. We should remove it when connecting to backend.
class _User {
  String name;
  String email;
  String password; // No se muestra, pero se gestiona aquí
  int minutesDry;

  _User({
    required this.name,
    required this.email,
    required this.password,
    required this.minutesDry,
  });
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<StatefulWidget> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _user = _User(
    name: 'NombreEjemplo',
    email: 'user@uniandes.edu.co',
    password: 'password123',
    minutesDry: 1245,
  );

  void _editName() async {
    final newName = await showEditFieldDialog(
      context: context,
      title: 'Nombre',
      initialValue: _user.name,
    );

    if (newName != null && newName.isNotEmpty) {
      setState(() {
        _user.name = newName;
      });
    }
  }

  void _editEmail() async {
    final newEmail = await showEditFieldDialog(
      context: context,
      title: 'Email',
      initialValue: _user.email,
      keyboardType: TextInputType.emailAddress,
    );

    if (newEmail != null && newEmail.isNotEmpty) {
      setState(() {
        _user.email = newEmail;
      });
    }
  }

  void _editPassword() {
    showChangePasswordDialog(context);
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
      builder: (context) => AlertDialog(
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
            Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 100,
                  backgroundColor: const Color(0xFFADD8E6),
                  child: ClipOval(
                    child: Image.asset('assets/images/raindrop.png'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Minutos en el que el usuario ha estado seco: 0',
              style: TextStyle(color: Colors.black54, fontSize: 14),
            ),
            const SizedBox(height: 30),
            buildProfileItem('Nombre', _user.name, _editName),
            const SizedBox(height: 20),
            buildProfileItem('Contraseña', '*********', _editPassword),
            const SizedBox(height: 20),
            buildProfileItem('Email', _user.email, _editEmail),
            const SizedBox(height: 50),
            buildActionButton(
              'Borrar Cuenta',
              AppThem.accent,
              Colors.white,
              _deleteAccount,
            ),
            const SizedBox(height: 20),
            buildActionButton(
              'Desactivar Cuenta',
              Colors.grey[400]!,
              Colors.black,
              _deactivateAccount,
            ),
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

  Widget buildActionButton(
    String text,
    Color backgroundColor,
    Color textColor,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text(text, style: TextStyle(color: textColor, fontSize: 18)),
      ),
    );
  }
}
