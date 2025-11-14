import 'voice_intent.dart';

String _normalize(String s) {
  var out = s.toLowerCase();
  const withAccents = 'áéíóúüñ';
  const withoutAccents = 'aeiouun';
  for (var i = 0; i < withAccents.length; i++) {
    out = out.replaceAll(withAccents[i], withoutAccents[i]);
  }
  return out.trim();
}

// helper pequeño para no repetir contains en todo lado
bool _containsAny(String text, List<String> patterns) {
  for (final p in patterns) {
    if (text.contains(p)) return true;
  }
  return false;
}

VoiceIntent parseIntent(String raw) {
  final p = _normalize(raw);

  // ====== NUEVOS: MENÚ, PERFIL, NOTIFICACIONES ======
  final hasMenu = _containsAny(p, [
    ' menu',         // espacio antes para evitar cosas raras
    'menu ',         // o espacio después
    'menú',          // por si acaso
    'ir al menu',
    'ir a menu',
    'abrir menu',
    'abrir el menu',
    'opciones',
  ]);

  final hasProfile = _containsAny(p, [
    'perfil',
    'mi perfil',
    'mi cuenta',
    'cuenta',
    'datos personales',
  ]);

  final hasNotif = _containsAny(p, [
    'notificacion',
    'notificaciones',
    'ir a notificacion',
    'ir a las notificaciones',
    'ir a notificaciones',
    'ver notificaciones',
    'mis notificaciones',
    'mis mensajes',
    'alertas',
    'alerta',
    'avisos',
  ]);

  // 👉 Priorizar comandos de navegación si aparecen
  if (hasMenu) return VoiceIntent.openMenu;
  if (hasProfile) return VoiceIntent.openProfile;
  if (hasNotif) return VoiceIntent.openNotifications;

  // ====== LO QUE YA TENÍAS: RENTAR / DEVOLVER ======
  final hasRentar = _containsAny(p, [
    'rentar',
    'alquilar',
    'arrendar',
    'alquiler',
  ]);

  final hasSombr = _containsAny(p, [
    'sombrilla',
    'paraguas',
    'umbrella',
  ]);

  final hasNfc = _containsAny(p, [
    'nfc',
    'ene efe ce',
  ]);

  final hasQr = _containsAny(p, [
    'qr',
    'codigo qr',
    'c0digo qr', 
  ]);

  final hasDev = _containsAny(p, [
    'devolver',
    'retornar',
    'regresar',
  ]);

  if (p == 'nfc') return VoiceIntent.rentNFC;
  if (p == 'qr') return VoiceIntent.rentQR;

  if (hasDev) return VoiceIntent.returnUmbrella;

  if ((hasRentar || hasSombr) && hasQr) return VoiceIntent.rentQR;
  if ((hasRentar || hasSombr) && hasNfc) return VoiceIntent.rentNFC;

  if (hasRentar || hasSombr) return VoiceIntent.rentDefault;

  return VoiceIntent.none;
}
