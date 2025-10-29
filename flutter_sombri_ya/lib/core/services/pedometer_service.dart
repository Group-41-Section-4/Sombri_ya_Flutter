import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

class PedometerService {
  static final PedometerService _instance = PedometerService._internal();
  factory PedometerService() => _instance;
  PedometerService._internal();

  final ValueNotifier<int> sessionSteps = ValueNotifier(0);
  final ValueNotifier<bool> isTracking = ValueNotifier(false);

  StreamSubscription<StepCount>? _stepSubscription;
  int _sessionStartSteps = -1;
  int _currentSteps = 0;

  static const double kmPerStep = 0.000762;

  Future<bool> _requestPermission() async {
    final status = await Permission.activityRecognition.request();
    if (status.isGranted) {
      return true;
    } else {
      print("Error Pedometer: Permiso de 'Activity Recognition' denegado.");
      return false;
    }
  }

  void startListening() async {
    if (isTracking.value) return;
    final hasPermission = await _requestPermission();
    if (!hasPermission) {
      return;
    }

    print("PedometerService: Iniciando escucha de pasos...");
    _sessionStartSteps = -1;
    _currentSteps = 0;
    sessionSteps.value = 0;
    isTracking.value = true;

    _stepSubscription = Pedometer.stepCountStream.listen(
      (StepCount event) {
        if (_sessionStartSteps == -1) {
          _sessionStartSteps = event.steps;
        }
        _currentSteps = event.steps;

        final stepsInThisSession = _sessionStartSteps == -1
            ? 0
            : _currentSteps - _sessionStartSteps;
        sessionSteps.value = stepsInThisSession < 0 ? 0 : stepsInThisSession;
      },
      onError: (error) {
        print("Error en PedometerService: $error");
        stopAndGetDistanceKm();
      },
      cancelOnError: true,
    );
  }

  double stopAndGetDistanceKm() {
    print("PedometerService: Deteniendo escucha de pasos...");
    _stepSubscription?.cancel();
    _stepSubscription = null;
    isTracking.value = false;

    final int finalSteps = sessionSteps.value;

    _sessionStartSteps = -1;
    _currentSteps = 0;
    sessionSteps.value = 0;

    if (finalSteps <= 0) return 0.0;
    return finalSteps * kmPerStep;
  }
}
