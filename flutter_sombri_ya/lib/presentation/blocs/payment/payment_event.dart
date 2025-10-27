import 'package:equatable/equatable.dart';

abstract class PaymentEvent extends Equatable {
  const PaymentEvent();
  @override
  List<Object> get props => [];
}

class LoadPaymentMethods extends PaymentEvent {
  const LoadPaymentMethods();
}

class SelectPaymentMethod extends PaymentEvent {
  final int newIndex;
  const SelectPaymentMethod(this.newIndex);
  @override
  List<Object> get props => [newIndex];
}
