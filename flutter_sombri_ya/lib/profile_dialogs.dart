import 'package:flutter/material.dart';
import 'theme.dart';

Future<String?> showEditFieldDialog({
  required BuildContext context,
  required String title,
  required String initialValue,
  TextInputType keyboardType = TextInputType.text,
  bool isPassword = false,
}) {
  final TextEditingController controller = TextEditingController(
    text: initialValue,
  );

  return showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Cambiar $title'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: keyboardType,
          obscureText: isPassword,
          decoration: InputDecoration(
            labelText: 'Nuevo $title',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(controller.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppThem.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Guardar'),
          ),
        ],
      );
    },
  );
}

void showChangePasswordDialog(BuildContext context) {
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Cambiar Contraseña'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Contraseña Actual',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Nueva Contraseña',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
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
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (newPasswordController.text.isNotEmpty &&
                  newPasswordController.text ==
                      confirmPasswordController.text) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Contraseña actualizada con éxito.'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Las contraseñas nuevas no coinciden o están vacías.',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppThem.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Guardar'),
          ),
        ],
      );
    },
  );
}
