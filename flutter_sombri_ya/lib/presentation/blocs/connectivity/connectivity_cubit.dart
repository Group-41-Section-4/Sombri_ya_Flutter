import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/connectivity/connectivity_service.dart';

class ConnectivityCubit extends Cubit<ConnectivityStatus> {
  final ConnectivityService _service;
  StreamSubscription<ConnectivityStatus>? _sub;

  ConnectivityCubit(this._service) : super(ConnectivityStatus.offline);

  Future<void> start() async {
    await _service.start();
    await _sub?.cancel();
    _sub = _service.stream.listen(
          (status) => emit(status),
      onError: (_) => emit(ConnectivityStatus.offline),
      cancelOnError: false,
    );
  }

  Future<void> retry() async {
    await _service.pingNow();
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    await _service.dispose();
    return super.close();
  }
}
