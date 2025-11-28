import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'help_event.dart';
import 'help_state.dart';
import '../../../data/repositories/help_repository.dart';

class HelpBloc extends Bloc<HelpEvent, HelpState> {
  final HelpRepository _repository;
  final Connectivity _connectivity;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  HelpBloc({
    HelpRepository? repository,
    Connectivity? connectivity,
  })  : _repository = repository ?? HelpRepository(),
        _connectivity = connectivity ?? Connectivity(),
        super(const HelpState()) {
    on<HelpStarted>(_onStarted);
    on<HelpRefreshed>(_onRefreshed);

    _connectivitySub = _connectivity.onConnectivityChanged.listen((results) {
      final hasNet = results.any((r) => r != ConnectivityResult.none);
      if (hasNet) {
        add(HelpRefreshed());
      }
    });
  }

  Future<void> _onStarted(
      HelpStarted event, Emitter<HelpState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));

    final results = await _connectivity.checkConnectivity();
    final hasNet = results != ConnectivityResult.none;

    if (!hasNet) {
      final cached = await _repository.loadFromCache();
      if (cached != null) {
        final (faqs, tutorials) = cached;
        emit(
          state.copyWith(
            isLoading: false,
            offlineMode: true,
            fromCache: true,
            faqs: faqs,
            tutorials: tutorials,
          ),
        );
      } else {
        emit(
          state.copyWith(
            isLoading: false,
            offlineMode: true,
            error:
                'No hay conexión. Intenta de nuevo cuando tengas internet.',
          ),
        );
      }
      return;
    }

    try {
      final (faqs, tutorials) = await _repository.fetchFromServer();
      await _repository.saveToCache(faqs, tutorials);

      emit(
        state.copyWith(
          isLoading: false,
          offlineMode: false,
          fromCache: false,
          faqs: faqs,
          tutorials: tutorials,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          error: 'Error cargando ayuda. Intenta nuevamente.',
        ),
      );
    }
  }

  Future<void> _onRefreshed(
      HelpRefreshed event, Emitter<HelpState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      final (faqs, tutorials) = await _repository.fetchFromServer();
      await _repository.saveToCache(faqs, tutorials);

      emit(
        state.copyWith(
          isLoading: false,
          offlineMode: false,
          fromCache: false,
          faqs: faqs,
          tutorials: tutorials,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          error: 'No se pudo actualizar la ayuda.',
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _connectivitySub?.cancel();
    return super.close();
  }
}
