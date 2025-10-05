import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'rent_strategy.dart';

class NfcRentStrategy implements RentStrategy {
  @override
  Future<void> rent() async {
    try{
      NFCTag tag = await FlutterNfcKit.poll();
      await Future.delayed(const Duration(seconds: 1));

      await FlutterNfcKit.finish();
    }
    catch (e) {
      print("Error NFC: $e");
    }

    await Future.delayed(const Duration(seconds: 2));

  }
}