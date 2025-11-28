import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/help_model.dart';

class HelpRepository {
  static const _cacheKey = 'help_cache_v1';

  Future<(List<FaqItem>, List<TutorialItem>)> fetchFromServer() async {
    // CAMBIAR API REAL
    await Future.delayed(const Duration(milliseconds: 800));

    final faqs = [
      FaqItem(
        question: '¿Qué métodos de pago tienen disponibles?',
        answer: 'Actualmente recomendamos las tarjetas y pagos en efectivo.',
      ),
      FaqItem(
        question: '¿Qué hago si olvidé mi contraseña?',
        answer:
            'Puedes recuperar tu cuenta desde la sección "Perfil" en el menú.',
      ),
    ];

    final tutorials = [
      TutorialItem(title: 'Reservar una sombrilla'),
      TutorialItem(title: 'Agregar métodos de pago'),
      TutorialItem(title: 'Agregar amigos a una reserva'),
    ];

    return (faqs, tutorials);
  }

  Future<(List<FaqItem>, List<TutorialItem>)?> loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_cacheKey);
    if (jsonStr == null) return null;

    final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
    final faqs = (decoded['faqs'] as List<dynamic>)
        .map((e) => FaqItem.fromJson(e as Map<String, dynamic>))
        .toList();
    final tutorials = (decoded['tutorials'] as List<dynamic>)
        .map((e) => TutorialItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return (faqs, tutorials);
  }

  Future<void> saveToCache(
      List<FaqItem> faqs, List<TutorialItem> tutorials) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode({
      'faqs': faqs.map((e) => e.toJson()).toList(),
      'tutorials': tutorials.map((e) => e.toJson()).toList(),
    });
    await prefs.setString(_cacheKey, jsonStr);
  }
}
