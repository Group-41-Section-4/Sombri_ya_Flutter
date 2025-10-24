import 'dart:typed_data';
import 'package:nfc_manager/nfc_manager.dart';

typedef UidCallback = Future<void> Function(String uid);

String bytesToHex(Uint8List bytes) => bytes
    .map((b) => b.toRadixString(16).padLeft(2, '0'))
    .join(':')
    .toUpperCase();

class NfcService {
  Future<bool> isAvailable() => NfcManager.instance.isAvailable();

  Future<void> startUidSession(UidCallback onUid) async {
    await NfcManager.instance.startSession(
      pollingOptions: {NfcPollingOption.iso14443},
      onDiscovered: (NfcTag tag) async {
        try {
          final uid = _extractUid(tag.data);
          if (uid == null) throw Exception('No se pudo detectar UID');
          await onUid(uid);
        } catch (_) {
          // dejamos que la capa superior gestione errores
        } finally {
          await stopSession();
        }
      },
    );
  }

  Future<void> stopSession() => NfcManager.instance.stopSession();

  String? _extractUid(Map<dynamic, dynamic> tagData) {
    Uint8List? id;

    Uint8List? _coerce(dynamic raw) {
      if (raw is Uint8List) return raw;
      if (raw is List) return Uint8List.fromList(raw.cast<int>());
      return null;
    }

    if (tagData.containsKey('nfca')) {
      id ??= _coerce(tagData['nfca']?['identifier']);
    }
    if (id == null && tagData.containsKey('mifareclassic')) {
      id ??= _coerce(tagData['mifareclassic']?['identifier']);
    }
    if (id == null) {
      for (final entry in tagData.entries) {
        final value = entry.value;
        if (value is Map && value['identifier'] != null) {
          id = _coerce(value['identifier']);
          if (id != null) break;
        }
      }
    }
    return id == null ? null : bytesToHex(id);
  }
}
