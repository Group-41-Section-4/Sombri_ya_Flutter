// lib/presentation/pages/legal/terms_and_conditions_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kTermsAcceptedVersionKey = 'terms_accepted_version';
const int kCurrentTermsVersion = 1;

class TermsAndConditionsPage extends StatefulWidget {
  const TermsAndConditionsPage({super.key});

  @override
  State<TermsAndConditionsPage> createState() => _TermsAndConditionsPageState();
}

class _TermsAndConditionsPageState extends State<TermsAndConditionsPage> {
  bool _isLoading = true;
  bool _hasAccepted = false;
  bool _isChecked = false;

  @override
  void initState() {
    super.initState();
    _loadAcceptance();
  }

  Future<void> _loadAcceptance() async {
    final prefs = await SharedPreferences.getInstance();
    final acceptedVersion = prefs.getInt(kTermsAcceptedVersionKey) ?? 0;

    setState(() {
      _hasAccepted = acceptedVersion >= kCurrentTermsVersion;
      _isChecked = _hasAccepted;
      _isLoading = false;
    });
  }

  Future<void> _onAcceptPressed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(kTermsAcceptedVersionKey, kCurrentTermsVersion);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Has aceptado los términos y condiciones.')),
    );

    // We just close the page. Later, you can handle this result if needed.
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Términos y condiciones')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: _buildContent(context),
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _isChecked,
                            onChanged: (value) {
                              setState(() {
                                _isChecked = value ?? false;
                              });
                            },
                          ),
                          const Expanded(
                            child: Text(
                              'He leído y acepto los términos y condiciones.',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isChecked ? _onAcceptPressed : null,
                          child: Text(
                            _hasAccepted
                                ? 'Actualizar aceptación'
                                : 'Aceptar términos y condiciones',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final titleStyle = Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold);
    final bodyStyle = Theme.of(context).textTheme.bodyMedium;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Términos y condiciones de uso',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text('Última actualización: noviembre de 2025', style: bodyStyle),
        const SizedBox(height: 16),
        Text(
          'Al usar esta aplicación aceptas los presentes términos y condiciones. '
          'Si no estás de acuerdo con alguno de los puntos descritos a continuación, '
          'no deberás utilizar la aplicación.',
          style: bodyStyle,
        ),
        const SizedBox(height: 24),

        // 1. Responsable del tratamiento
        Text('1. Responsable del tratamiento de datos', style: titleStyle),
        const SizedBox(height: 8),
        Text(
          'La aplicación es operada por el equipo desarrollador de Sombri-Ya, '
          'quien actúa como responsable del tratamiento de los datos personales '
          'que se recolectan a través de la misma.',
          style: bodyStyle,
        ),
        const SizedBox(height: 16),

        // 2. Datos que recopilamos
        Text('2. Datos que recopilamos', style: titleStyle),
        const SizedBox(height: 8),
        Text(
          'Al utilizar la aplicación, podemos recopilar los siguientes tipos de datos:',
          style: bodyStyle,
        ),
        const SizedBox(height: 8),
        _buildBullet(
          context,
          'Datos de identificación: nombre, correo electrónico y otra '
          'información básica necesaria para crear y mantener tu cuenta.',
        ),
        _buildBullet(
          context,
          'Datos de uso de la aplicación: historial de alquileres, estaciones utilizadas, '
          'tiempos de uso, calificaciones y reportes de sombrillas.',
        ),
        _buildBullet(
          context,
          'Datos de ubicación aproximada: cuando sea necesario para mostrar estaciones cercanas '
          'o mejorar la experiencia de uso (siempre que otorgues los permisos correspondientes).',
        ),
        _buildBullet(
          context,
          'Datos técnicos: información del dispositivo, versión de la aplicación y registros '
          'técnicos para diagnóstico de errores y mejora del servicio.',
        ),
        const SizedBox(height: 16),

        // 3. Finalidades
        Text('3. Finalidades del tratamiento de datos', style: titleStyle),
        const SizedBox(height: 8),
        Text(
          'Utilizamos tus datos personales para las siguientes finalidades:',
          style: bodyStyle,
        ),
        const SizedBox(height: 8),
        _buildBullet(
          context,
          'Gestionar el registro, autenticación y uso de tu cuenta en la aplicación.',
        ),
        _buildBullet(
          context,
          'Permitir y registrar los alquileres de sombrillas, incluyendo inicio, fin, '
          'estaciones involucradas y estado de las sombrillas.',
        ),
        _buildBullet(
          context,
          'Procesar y almacenar tus reportes, calificaciones y comentarios sobre el servicio.',
        ),
        _buildBullet(
          context,
          'Mejorar el funcionamiento de la aplicación, analizar patrones de uso y realizar '
          'optimización de rutas, estaciones y disponibilidad de sombrillas.',
        ),
        _buildBullet(
          context,
          'Cumplir con obligaciones legales y responder a requerimientos de autoridades competentes, '
          'cuando así lo exija la normativa aplicable.',
        ),
        const SizedBox(height: 16),

        // 4. Almacenamiento
        Text(
          '4. Almacenamiento y conservación de la información',
          style: titleStyle,
        ),
        const SizedBox(height: 8),
        Text(
          'Tus datos pueden almacenarse tanto de forma local en tu dispositivo como en servidores '
          'remotos utilizados por el backend de la aplicación. Los datos se conservarán durante el '
          'tiempo necesario para cumplir con las finalidades descritas o mientras mantengas activa tu cuenta.',
          style: bodyStyle,
        ),
        const SizedBox(height: 16),

        // 5. Seguridad
        Text('5. Seguridad de la información', style: titleStyle),
        const SizedBox(height: 8),
        Text(
          'Implementamos medidas razonables de seguridad para proteger la información que tratamos, '
          'incluyendo controles de acceso, cifrado en tránsito y buenas prácticas de desarrollo seguro. '
          'Sin embargo, ningún sistema es completamente invulnerable y no podemos garantizar seguridad absoluta.',
          style: bodyStyle,
        ),
        const SizedBox(height: 16),

        // 6. Compartir datos
        Text('6. Compartir datos con terceros', style: titleStyle),
        const SizedBox(height: 8),
        Text(
          'No vendemos tus datos personales. Podremos compartirlos únicamente cuando sea estrictamente necesario para:',
          style: bodyStyle,
        ),
        const SizedBox(height: 8),
        _buildBullet(
          context,
          'Proveer servicios tecnológicos de infraestructura, almacenamiento o análisis, bajo acuerdos de confidencialidad.',
        ),
        _buildBullet(
          context,
          'Cumplir requerimientos legales, órdenes judiciales o solicitudes de autoridades competentes.',
        ),
        const SizedBox(height: 16),

        // 7. Derechos
        Text('7. Derechos del usuario sobre sus datos', style: titleStyle),
        const SizedBox(height: 8),
        Text(
          'Como titular de los datos, puedes ejercer, en los términos de la normativa aplicable, los siguientes derechos:',
          style: bodyStyle,
        ),
        const SizedBox(height: 8),
        _buildBullet(
          context,
          'Acceder a la información personal que tenemos sobre ti.',
        ),
        _buildBullet(
          context,
          'Solicitar la actualización o rectificación de tus datos.',
        ),
        _buildBullet(
          context,
          'Solicitar la supresión de tus datos cuando sea procedente.',
        ),
        _buildBullet(
          context,
          'Retirar tu consentimiento para el tratamiento de datos, cuando el tratamiento se base en dicho consentimiento.',
        ),
        const SizedBox(height: 16),

        // 8. Offline
        Text(
          '8. Manejo de datos en modo sin conexión (offline)',
          style: titleStyle,
        ),
        const SizedBox(height: 8),
        Text(
          'La aplicación puede almacenar temporalmente cierta información en tu dispositivo para permitir el uso en modo sin conexión, '
          'por ejemplo, historial de alquileres recientes o reportes pendientes de envío. Estos datos se sincronizan con el servidor cuando '
          'vuelvas a tener conexión y se procurará eliminarlos del almacenamiento local cuando ya no sean necesarios.',
          style: bodyStyle,
        ),
        const SizedBox(height: 16),

        // 9. Modificaciones
        Text('9. Modificaciones a estos términos', style: titleStyle),
        const SizedBox(height: 8),
        Text(
          'Podremos actualizar estos términos y condiciones para reflejar cambios en la aplicación, en la forma en que tratamos tus datos '
          'o en la normativa aplicable. Cuando haya cambios relevantes, te informaremos a través de la aplicación y se te podrá solicitar '
          'que aceptes nuevamente los términos actualizados.',
          style: bodyStyle,
        ),
        const SizedBox(height: 16),

        // 10. Contacto
        Text('10. Contacto', style: titleStyle),
        const SizedBox(height: 8),
        Text(
          'Si tienes dudas o comentarios sobre estos términos y condiciones o sobre el tratamiento de tus datos personales, '
          'puedes contactarnos a través de los canales de soporte indicados dentro de la aplicación.',
          style: bodyStyle,
        ),
        const SizedBox(height: 24),
        Text(
          'Al continuar utilizando la aplicación, declaras que has leído, comprendido y aceptado estos términos y condiciones.',
          style: bodyStyle,
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildBullet(BuildContext context, String text) {
    final bodyStyle = Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  '),
          Expanded(child: Text(text, style: bodyStyle)),
        ],
      ),
    );
  }
}

class TermsAndConditionsStorage {
  const TermsAndConditionsStorage._();

  static Future<bool> hasAcceptedLatestTerms() async {
    final prefs = await SharedPreferences.getInstance();
    final acceptedVersion = prefs.getInt(kTermsAcceptedVersionKey) ?? 0;
    return acceptedVersion >= kCurrentTermsVersion;
  }
}
