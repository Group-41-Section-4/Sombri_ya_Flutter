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

VoiceIntent parseIntent(String raw) {
  final p = _normalize(raw);

  final hasRentar = RegExp(
    r'\b(rentar|alquilar|arrendar|alquiler)\b',
  ).hasMatch(p);
  final hasSombr = RegExp(r'\b(sombrilla|paraguas|umbrella)\b').hasMatch(p);
  final hasNfc = RegExp(r'\b(nfc|ene efe ce)\b').hasMatch(p);
  final hasQr = RegExp(r'\b(qr|codigo qr|c[oó]digo qr)\b').hasMatch(p);
  final hasDev = RegExp(r'\b(devolver|retornar|regresar)\b').hasMatch(p);

  if (RegExp(r'^\s*nfc\s*$').hasMatch(p)) return VoiceIntent.rentNFC;
  if (RegExp(r'^\s*qr\s*$').hasMatch(p)) return VoiceIntent.rentQR;

  if (hasDev) return VoiceIntent.returnUmbrella;

  if ((hasRentar || hasSombr) && hasQr) return VoiceIntent.rentQR;
  if ((hasRentar || hasSombr) && hasNfc) return VoiceIntent.rentNFC;

  if (hasRentar || hasSombr) return VoiceIntent.rentDefault;

  return VoiceIntent.none;
}
