import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sombri_ya/data/models/payment_card_model.dart';
import '../../../data/repositories/payment_repository.dart';
import 'payment_event.dart';
import 'payment_state.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final PaymentRepository _repo;

  PaymentBloc({PaymentRepository? repo})
    : _repo = repo ?? PaymentRepository(),
      super(const PaymentState()) {
    on<LoadPaymentMethods>(_onLoadPaymentMethods);
    on<SelectPaymentMethod>(_onSelectPaymentMethod);
  }

  Future<void> _onLoadPaymentMethods(
    LoadPaymentMethods event,
    Emitter<PaymentState> emit,
  ) async {
    emit(state.copyWith(status: PaymentStatus.loading));
    try {
      final List<PaymentCardModel> cards = await _repo.getAllPaymentMethods();
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

  Future<void> _onSelectPaymentMethod(
    SelectPaymentMethod event,
    Emitter<PaymentState> emit,
  ) async {
    int newIndex = event.newIndex;

    if (newIndex < 0 || newIndex >= state.cards.length) {
      newIndex = 0;
    }

    if (newIndex != state.currentIndex) {
      emit(state.copyWith(currentIndex: newIndex));
      return;
    }

    final selectedCard = state.cards[newIndex];
    await _repo.markCardAsUsed(selectedCard);
    await _onLoadPaymentMethods(const LoadPaymentMethods(), emit);
  }
}
