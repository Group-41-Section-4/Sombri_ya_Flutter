
abstract class RentStrategy{
  Future<void> rent(); // Future -> Operación asincrónica; void -> no devuelve anda
}

class RentContext {
  RentStrategy _strategy;

  RentContext(this._strategy);

  RentStrategy get strategy => _strategy;
  set strategy(RentStrategy strategy) {
    _strategy = strategy;
  }

  Future<void> rent() async {
    await _strategy.rent();
  }
}