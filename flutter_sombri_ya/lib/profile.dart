import 'package:flutter/material.dart';
import 'theme.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<StatefulWidget> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThem.primaryColor,
      appBar: AppBar(
        title: const Text(
          'Cuenta',
          style: TextStyle(color: Colors.black, fontSize: 30),
        ),
        centerTitle: true,
        backgroundColor: AppThem.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 100,
                  backgroundColor: Colors.white,
                  child: ClipOval(
                    child: Image.asset('assets/images/profile_icon.png'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Cambiar foto de perfil',
              style: TextStyle(color: Colors.black54, fontSize: 14),
            ),
            const SizedBox(height: 30),
            buildProfileItem('Nombre', 'NombreEjemplo'),
            const SizedBox(height: 20),
            buildProfileItem('Contraseña', '*********'),
            const SizedBox(height: 20),
            buildProfileItem('Email', 'user@uniandes.edu.co'),
            const SizedBox(height: 50),
            buildActionButton(
              'Borrar Cuenta',
              AppThem.accent,
              Colors.white,
              () {},
            ),
            const SizedBox(height: 20),
            buildActionButton(
              'Desactivar Cuenta',
              Colors.grey[400]!,
              Colors.black,
              () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget buildProfileItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppThem.primaryColor, width: 1),
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
