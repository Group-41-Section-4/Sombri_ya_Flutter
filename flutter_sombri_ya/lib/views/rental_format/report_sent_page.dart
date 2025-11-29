import 'package:flutter/material.dart';

import '../home/home_page.dart';

class ReportSentPage extends StatefulWidget {
  const ReportSentPage({super.key});

  @override
  State<ReportSentPage> createState() => _ReportSentPageState();
}

class _ReportSentPageState extends State<ReportSentPage> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const HomePage(),
        ),
            (route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.check_circle, size: 80, color: Colors.green,),
            SizedBox(height: 16),
            Text(
              '¡Reporte Enviado!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Gracias por tu reporte. Lo revisaremos lo antes posible.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

