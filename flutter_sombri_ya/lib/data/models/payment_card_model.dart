// payment_card_model.dart

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class PaymentCardModel extends Equatable {
  final String lastFourDigits;
  final String cardHolder;
  final String expiryDate;
  final Color cardColor;
  final String brand;

  const PaymentCardModel({
    required this.lastFourDigits,
    required this.cardHolder,
    required this.expiryDate,
    required this.cardColor,
    required this.brand,
  });

  Map<String, dynamic> toJson() => {
    'lastFourDigits': lastFourDigits,
    'cardHolder': cardHolder,
    'expiryDate': expiryDate,
    'cardColor': cardColor.value,
    'brand': brand,
  };

  factory PaymentCardModel.fromJson(Map<String, dynamic> json) {
    return PaymentCardModel(
      lastFourDigits: json['lastFourDigits'] as String,
      cardHolder: json['cardHolder'] as String,
      expiryDate: json['expiryDate'] as String,
      cardColor: Color(json['cardColor'] as int),
      brand: json['brand'] as String,
    );
  }

  @override
  List<Object?> get props => [
    lastFourDigits,
    cardHolder,
    expiryDate,
    brand,
    cardColor,
  ];
}
