import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';

import 'package:flutter_sombri_ya/data/models/payment_card_model.dart';
import 'package:flutter_sombri_ya/presentation/blocs/payment/payment_bloc.dart';
import 'package:flutter_sombri_ya/presentation/blocs/payment/payment_event.dart';
import 'package:flutter_sombri_ya/presentation/blocs/payment/payment_state.dart';

class PaymentMethodsPage extends StatelessWidget {
  const PaymentMethodsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PaymentBloc()..add(const LoadPaymentMethods()),
      child: const _PaymentMethodsView(),
    );
  }
}

class _PaymentMethodsView extends StatelessWidget {
  const _PaymentMethodsView();

  void _handleVerticalDrag(
    DragEndDetails details,
    BuildContext context,
    PaymentState state,
  ) {
    final bloc = context.read<PaymentBloc>();

    if (details.primaryVelocity! < 0) {
      bloc.add(SelectPaymentMethod(state.currentIndex + 1));
    }

    if (details.primaryVelocity! > 0) {
      bloc.add(SelectPaymentMethod(state.currentIndex - 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDFD),
      appBar: AppBar(
        title: Text(
          'Métodos de Pago',
          style: GoogleFonts.cormorantGaramond(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF90E0EF),
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline,
              color: Colors.black,
              size: 28,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: BlocBuilder<PaymentBloc, PaymentState>(
        builder: (context, state) {
          if (state.status == PaymentStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == PaymentStatus.failure) {
            return Center(child: Text('Error: ${state.error}'));
          }

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 100.0),
            child: Column(
              children: [
                GestureDetector(
                  onVerticalDragEnd: (details) =>
                      _handleVerticalDrag(details, context, state),
                  child: SizedBox(
                    height: 300,
                    child: Stack(
                      alignment: Alignment.topCenter,
                      children: state.cards
                          .asMap()
                          .entries
                          .map((entry) {
                            final index = entry.key;
                            final card = entry.value;

                            final position = index - state.currentIndex;
                            final top = position * 40.0;
                            final scale = max(
                              1.0 - (position.abs() * 0.1),
                              0.8,
                            );
                            final isTopCard = index == state.currentIndex;

                            return AnimatedPositioned(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              top: top,
                              child: Transform.scale(
                                scale: scale,
                                child: Opacity(
                                  opacity: position.isNegative ? 0.0 : 1.0,
                                  child: GestureDetector(
                                    onTap: isTopCard ? () {} : null,
                                    child: _CreditCardWidget(card: card),
                                  ),
                                ),
                              ),
                            );
                          })
                          .toList()
                          .reversed
                          .toList(),
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    children: [
                      _buildActionButton(
                        text: 'Administrar Métodos',
                        onPressed: () {},
                      ),
                      const SizedBox(height: 15),
                      _buildActionButton(
                        text: 'Pagos Pendientes',
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF005E7C),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 5,
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _CreditCardWidget extends StatelessWidget {
  final PaymentCardModel card;

  const _CreditCardWidget({required this.card});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.85,
      height: 200,
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: card.cardColor,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                card.brand.toUpperCase(),
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.memory,
                color: Color.fromARGB(255, 212, 212, 212),
                size: 40,
              ),
              const Spacer(),
              Text(
                '**** **** **** ${card.lastFourDigits}',
                style: GoogleFonts.spaceMono(
                  color: Colors.white,
                  fontSize: 18,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    card.cardHolder,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  Text(
                    card.expiryDate,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
