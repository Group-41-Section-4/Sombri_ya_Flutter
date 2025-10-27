import 'package:equatable/equatable.dart';
import 'package:flutter_sombri_ya/data/models/payment_card_model.dart';

enum PaymentStatus { initial, loading, success, failure }

class PaymentState extends Equatable {
  final PaymentStatus status;
  final List<PaymentCardModel> cards;
  final int currentIndex;
  final String? error;

  const PaymentState({
    this.status = PaymentStatus.initial,
    this.cards = const [],
    this.currentIndex = 0,
    this.error,
  });

  PaymentState copyWith({
    PaymentStatus? status,
    List<PaymentCardModel>? cards,
    int? currentIndex,
    String? error,
  }) {
    return PaymentState(
      status: status ?? this.status,
      cards: cards ?? this.cards,
      currentIndex: currentIndex ?? this.currentIndex,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, cards, currentIndex, error];
}
