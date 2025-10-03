import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'rent_strategy.dart';

class QrRentStrategy implements RentStrategy {
  final Function(String code)? onCodeScanned;

  QrRentStrategy({this.onCodeScanned});

  @override
  Future<void> rent() async {
    debugPrint("Opening QR Scanner...");
  }

  void handleBarCode(BarcodeCapture capture, BuildContext context) {
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;
      if(code != null) {
        debugPrint("Código QR detectado: $code");

        onCodeScanned?.call(code);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Sombrilla rentada con QR: $code"),)
        );
      }
    }
  } 
}