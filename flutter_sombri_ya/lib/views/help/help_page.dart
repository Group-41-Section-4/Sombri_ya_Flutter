import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  static const Color _blue = Color(0xFF90E0EF);
  static const Color _background = Color(0xFFF6FBFF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _blue,
        foregroundColor: Colors.black,
        centerTitle: true,
        title: Text(
          'Ayuda',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: const [
              _HelpSectionCard(
                title: 'Preguntas frecuentes',
                children: [
                  _HelpFaqItem(
                    question: '¿Qué métodos de pago tienen disponibles?',
                    answer: 'Recomendamos tarjetas y Nequi.',
                  ),
                  SizedBox(height: 12),
                  _HelpFaqItem(
                    question: '¿Qué hago si olvidé mi contraseña?',
                    answer:
                        'Puedes recuperar tu cuenta desde la opción "Perfil".',
                  ),
                ],
              ),
              SizedBox(height: 16),
              _HelpSectionCard(
                title: 'Tutoriales',
                children: [
                  _HelpSimpleItem(text: 'Reservar una sombrilla'),
                  SizedBox(height: 8),
                  _HelpSimpleItem(text: 'Agregar métodos de pago'),
                  SizedBox(height: 8),
                  _HelpSimpleItem(text: 'Reportar una sombrilla dañada'),
                ],
              ),
              SizedBox(height: 16),
              _HelpSectionCard(
                title: 'Contáctanos',
                children: [
                  _HelpContactRow(
                    icon: Icons.email_outlined,
                    label: 'ayuda@sombriya.com',
                  ),
                  SizedBox(height: 8),
                  _HelpContactRow(
                    icon: Icons.chat_bubble_outline,
                    label: '@Sombri-YA',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HelpSectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _HelpSectionCard({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 1,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.cormorantGaramond(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _HelpFaqItem extends StatelessWidget {
  final String question;
  final String answer;

  const _HelpFaqItem({
    required this.question,
    required this.answer,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          answer,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}

class _HelpSimpleItem extends StatelessWidget {
  final String text;

  const _HelpSimpleItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.play_circle_outline, size: 18, color: Colors.black54),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}

class _HelpContactRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HelpContactRow({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.black54),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
