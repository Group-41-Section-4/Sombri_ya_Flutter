import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sombri_ya/data/models/payment_card_model.dart';
import 'payment_event.dart';
import 'payment_state.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  PaymentBloc() : super(const PaymentState()) {
    on<LoadPaymentMethods>(_onLoadPaymentMethods);
    on<SelectPaymentMethod>(_onSelectPaymentMethod);
  }

  Future<void> _onLoadPaymentMethods(
    LoadPaymentMethods event,
    Emitter<PaymentState> emit,
  ) async {
    emit(state.copyWith(status: PaymentStatus.loading));
    try {
      final List<PaymentCardModel> cards = [
        PaymentCardModel(
          lastFourDigits: '9876',
          cardHolder: 'Nombre Ejemplo',
          expiryDate: '08/27',
          cardColor: const Color.fromARGB(255, 140, 5, 195),
          brand: 'NU',
        ),
        PaymentCardModel(
          lastFourDigits: '5678',
          cardHolder: 'Nombre Ejemplo',
          expiryDate: '10/25',
          cardColor: const Color.fromARGB(255, 140, 0, 0),
          brand: 'Mastercard',
        ),
        PaymentCardModel(
          lastFourDigits: '1234',
          cardHolder: 'Nombre Ejemplo',
          expiryDate: '12/26',
          cardColor: const Color.fromARGB(255, 20, 35, 145),
          brand: 'VISA',
        ),
      ];

      emit(
        state.copyWith(
          status: PaymentStatus.success,
          cards: cards,
          currentIndex: 0,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: PaymentStatus.failure, error: e.toString()));
    }
  }

  void _onSelectPaymentMethod(
    SelectPaymentMethod event,
    Emitter<PaymentState> emit,
  ) {
    final newIndex = event.newIndex.clamp(0, state.cards.length - 1);
    emit(state.copyWith(currentIndex: newIndex));
  }
}
