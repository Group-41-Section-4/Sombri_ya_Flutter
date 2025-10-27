import 'package:pedometer/pedometer.dart';

class PedometerService {
  static final PedometerService _instance = PedometerService._internal();
  factory PedometerService() => _instance;
  PedometerService._internal();

  Stream<StepCount>? _stepStream;
  int _sessionStartSteps = 0;
  int _currentSteps = 0;

  static const double kmPerStep = 0.000762;

  void startListening() {
    _stepStream = Pedometer.stepCountStream;
    _stepStream
        ?.listen((StepCount event) {
          if (_sessionStartSteps == 0) {
            _sessionStartSteps = event.steps;
          }
          _currentSteps = event.steps;
        })
        .onError((error) {
          print("Error en PedometerService: $error");
          _sessionStartSteps = 0;
        });
  }

  double stopAndGetDistanceKm() {
    if (_sessionStartSteps == 0) {
      return 0.0;
    }

    final int sessionSteps = _currentSteps - _sessionStartSteps;

    _sessionStartSteps = 0;
    _currentSteps = 0;
    _stepStream = null;

    if (sessionSteps <= 0) return 0.0;

    final double distanceKm = sessionSteps * kmPerStep;
    return distanceKm;
  }
}
