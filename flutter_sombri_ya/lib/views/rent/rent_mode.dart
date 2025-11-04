enum RentMode { qr, nfc }

extension RentModeX on RentMode {
  static RentMode from(dynamic v) {
    if (v is RentMode) return v;
    final s = (v ?? '').toString().toLowerCase();
    return s == 'nfc' ? RentMode.nfc : RentMode.qr;
  }

  String get asArg => this == RentMode.nfc ? 'nfc' : 'qr';
}
