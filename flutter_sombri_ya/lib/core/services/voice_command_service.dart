import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceCommandService {
  final stt.SpeechToText _stt = stt.SpeechToText();
  bool _available = false;

  Future<bool> _ensureMicPermission() async {
    final status = await Permission.microphone.status;
    if (status.isGranted) return true;
    final res = await Permission.microphone.request();
    return res.isGranted;
  }

  Future<bool> init({String localeId = 'es_CO'}) async {
    final hasPerm = await _ensureMicPermission();
    if (!hasPerm) return false;

    _available = await _stt.initialize(
      onError: (e) {
      },
      onStatus: (s) {
      },
      debugLogging: false,
    );
    return _available;
  }

  Future<bool> start({
    required void Function(String) onResult,
    String localeId = 'es_CO',
    Duration listenFor = const Duration(seconds: 6),
    bool partialResults = false,
  }) async {
    if (!_available) return false;

    return await _stt.listen(
      localeId: localeId,
      listenFor: listenFor,
      partialResults: partialResults,
      cancelOnError: true,
      onResult: (res) {
        final t = res.recognizedWords.trim();
        if (t.isNotEmpty) onResult(t);
      },
    );
  }

  Future<void> stop() async => _stt.stop();
  Future<void> cancel() async => _stt.cancel();
  bool get isListening => _stt.isListening;
}
