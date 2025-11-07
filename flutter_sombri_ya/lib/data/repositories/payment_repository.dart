import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/payment_card_model.dart';

class PaymentRepository {
  static const _kCacheKey = 'payment_cards_lru_cache';
  static const _kCacheCapacity = 5;

  static final List<PaymentCardModel> _mockCards = [
    const PaymentCardModel(
      lastFourDigits: '9876',
      cardHolder: 'Nombre Ejemplo',
      expiryDate: '08/27',
      cardColor: Color.fromARGB(255, 140, 5, 195),
      brand: 'NU',
    ),
    const PaymentCardModel(
      lastFourDigits: '5678',
      cardHolder: 'Nombre Ejemplo',
      expiryDate: '10/25',
      cardColor: Color.fromARGB(255, 140, 0, 0),
      brand: 'Mastercard',
    ),
    const PaymentCardModel(
      lastFourDigits: '1234',
      cardHolder: 'Nombre Ejemplo',
      expiryDate: '12/26',
      cardColor: Color.fromARGB(255, 20, 35, 145),
      brand: 'VISA',
    ),
  ];

  Future<List<PaymentCardModel>> _loadCache() async {
    final prefs = await SharedPreferences.getInstance();
    final rawJson = prefs.getString(_kCacheKey);
    if (rawJson == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(rawJson);
      return jsonList
          .map(
            (json) => PaymentCardModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      debugPrint('[PaymentRepo] Error cargando caché de pagos: $e');
      await _saveCache([]);
      return [];
    }
  }

  Future<void> _saveCache(List<PaymentCardModel> cards) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = cards.map((card) => card.toJson()).toList();
    await prefs.setString(_kCacheKey, jsonEncode(jsonList));
  }

  Future<List<PaymentCardModel>> getAllPaymentMethods() async {
    final allCards = [..._mockCards];
    final cachedCards = await _loadCache();

    final Set<String> uniqueCards = {};
    final List<PaymentCardModel> finalCards = [];

    String cardKey(PaymentCardModel card) =>
        '${card.brand}_${card.lastFourDigits}';

    for (final card in cachedCards) {
      final key = cardKey(card);
      if (!uniqueCards.contains(key)) {
        finalCards.add(card);
        uniqueCards.add(key);
      }
    }

    for (final card in allCards) {
      final key = cardKey(card);
      if (!uniqueCards.contains(key)) {
        finalCards.add(card);
        uniqueCards.add(key);
      }
    }

    return finalCards;
  }

  Future<void> markCardAsUsed(PaymentCardModel usedCard) async {
    final cachedCards = await _loadCache();

    final List<PaymentCardModel> newCacheList = List.from(cachedCards);

    newCacheList.removeWhere((card) => card == usedCard);

    newCacheList.insert(0, usedCard);

    final List<PaymentCardModel> lruList = newCacheList.length > _kCacheCapacity
        ? newCacheList.sublist(0, _kCacheCapacity)
        : newCacheList;
    await _saveCache(lruList);
  }
}
