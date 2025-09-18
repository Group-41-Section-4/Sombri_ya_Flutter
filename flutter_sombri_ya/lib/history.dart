import 'package:flutter/material.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    //Ejemplo para ver el historial
    final history = [
      {"date": "Septiembre 15, 2025", "duration": "Duración: 5 minutos"},
      {"date": "Agosto 31, 2025", "duration": "Duración: 12 horas"},
      {"date": "Agosto 25, 2025", "duration": "Duración: 1 hora"},
      {"date": "Agosto 17, 2025", "duration": "Duración: 1 hora"},
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF28BCEF),
        title: const Text("Historial"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: const Color(0xFFFFFDFD),
      body: Column(
        children: [
          // Lista de tarjetas
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final item = history[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB1E6F3),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.umbrella, color: Colors.black54),
                    title: Text(
                      item["date"]!,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(item["duration"]!),
                    trailing: Text(
                      "9:41 AM",
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                );
              },
            ),
          ),

          // Botón "Borrar historial"
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFC5152), // rojo
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  // poner metodos para borrar el historial
                },
                child: const Text(
                  "Borrar Historial",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
