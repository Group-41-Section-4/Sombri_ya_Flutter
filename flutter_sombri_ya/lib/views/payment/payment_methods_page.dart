import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "Métodos de Pago",
          style: GoogleFonts.cormorantGaramond(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFF90E0EF),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: BlocConsumer<PaymentBloc, PaymentState>(
        listener: (context, state) {
          if (state.status == PaymentStatus.success &&
              state.currentIndex == 0) {}
        },
        builder: (context, state) {
          if (state.status == PaymentStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == PaymentStatus.failure) {
            return Center(child: Text('Error al cargar: ${state.error}'));
          }

          if (state.cards.isEmpty) {
            return const Center(
              child: Text('No hay métodos de pago guardados.'),
            );
          }

          final int cardCount = state.cards.length;
          final PageController pageController = PageController(
            viewportFraction: 0.8,
            initialPage: state.currentIndex,
          );

          return Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: pageController,
                  itemCount: cardCount,
                  onPageChanged: (newIndex) {
                    context.read<PaymentBloc>().add(
                      SelectPaymentMethod(newIndex),
                    );
                  },
                  itemBuilder: (context, index) {
                    final card = state.cards[index];
                    return AnimatedBuilder(
                      animation: pageController,
                      builder: (context, child) {
                        double scale = 1.0;
                        if (pageController.position.haveDimensions) {
                          scale = pageController.page! - index;
                          scale = (1 - (scale.abs() * 0.2)).clamp(0.8, 1.0);
                        }
                        return Transform.scale(
                          scale: scale,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 30,
                            ),
                            child: _PaymentCardItem(
                              card: card,
                              isSelected: index == state.currentIndex,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              Text(
                state.currentIndex == 0
                    ? 'Tarjeta más usada (MRU)'
                    : 'Tarjeta seleccionada',
                style: GoogleFonts.montserrat(
                  color: state.currentIndex == 0
                      ? Colors.green.shade700
                      : Colors.grey,
                  fontSize: 16,
                  fontWeight: state.currentIndex == 0
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(cardCount, (index) {
                  return Container(
                    width: 8.0,
                    height: 8.0,
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == state.currentIndex
                          ? state.cards[index].cardColor
                          : Colors.grey.shade300,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: state.cards[state.currentIndex].cardColor,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    final selectedCard = state.cards[state.currentIndex];
                    context.read<PaymentBloc>().add(
                      SelectPaymentMethod(state.currentIndex),
                    );

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Tarjeta **** ${selectedCard.lastFourDigits} marcada como MRU (Most Recently Used).',
                        ),
                        duration: const Duration(seconds: 2),
                        backgroundColor: selectedCard.cardColor,
                      ),
                    );
                  },
                  child: Text(
                    'USAR ESTA TARJETA EN LA PRÓXIMA RENTA',
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }
}

// Widget de Tarjeta de Crédito (ajustado para la animación)
class _PaymentCardItem extends StatelessWidget {
  final PaymentCardModel card;
  final bool isSelected; // Para el indicador visual

  const _PaymentCardItem({required this.card, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: card.cardColor,
        borderRadius: BorderRadius.circular(15.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              isSelected ? 0.6 : 0.3,
            ), // Más sombra si está seleccionada
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: isSelected
            ? Border.all(
                color: Colors.white,
                width: 3,
              ) // Indicador visual de selección
            : null,
      ),
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
    );
  }
}
