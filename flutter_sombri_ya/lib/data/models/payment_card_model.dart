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

  @override
  List<Object?> get props => [lastFourDigits, cardHolder, expiryDate, brand];
}
