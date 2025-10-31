import 'dart:async';
import 'dart:isolate';
import 'dart:io';

enum ConnectivityStatus { online, captive, offline }

class ConnectivityService {
  final Duration probeInterval;

  final List<String> probeUrls;

  Isolate? _isolate;
  ReceivePort? _receivePort;
  SendPort? _sendPort;

  final _controller = StreamController<ConnectivityStatus>.broadcast();
  Stream<ConnectivityStatus> get stream => _controller.stream;

  ConnectivityService({
    this.probeInterval = const Duration(seconds: 5),
    this.probeUrls = const [
      'http://connectivitycheck.gstatic.com/generate_204',
      'http://clients3.google.com/generate_204',
    ],
  });

  Future<void> start() async {
    if (_isolate != null) return;

    _receivePort = ReceivePort();
    _isolate = await Isolate.spawn(_connectivityIsolate, _receivePort!.sendPort);

    _sendPort = await _receivePort!.first as SendPort;

    _sendPort!.send({
      'type': 'config',
      'intervalMs': probeInterval.inMilliseconds,
      'urls': probeUrls,
    });

    final updates = ReceivePort();
    _sendPort!.send({'type': 'listen', 'port': updates.sendPort});

    updates.listen((msg) {
      if (msg is String) {
        switch (msg) {
          case 'online':
            _controller.add(ConnectivityStatus.online);
            break;
          case 'captive':
            _controller.add(ConnectivityStatus.captive);
            break;
          default:
            _controller.add(ConnectivityStatus.offline);
        }
      }
    });
  }

  Future<void> pingNow() async {
    _sendPort?.send({'type': 'ping'});
  }

  void setInterval(Duration interval) {
    _sendPort?.send({
      'type': 'set_interval',
      'intervalMs': interval.inMilliseconds,
    });
  }

  Future<void> dispose() async {
    _sendPort?.send({'type': 'stop'});
    _receivePort?.close();
    _controller.close();
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
  }
}

Future<void> _connectivityIsolate(SendPort mainSendPort) async {
  final controlPort = ReceivePort();
  mainSendPort.send(controlPort.sendPort);

  Duration interval = const Duration(seconds: 5);
  List<String> urls = const [
    'http://connectivitycheck.gstatic.com/generate_204',
    'http://clients3.google.com/generate_204',
  ];

  SendPort? updatesPort;
  Timer? timer;

  Future<void> tick() async {
    try {
      for (final u in urls) {
        final status = await _probeUrl(u, timeout: const Duration(seconds: 3));
        if (status == 204) {
          updatesPort?.send('online');
          return;
        } else if (status != -1) {
          updatesPort?.send('captive');
          return;
        }
      }
      updatesPort?.send('offline');
    } catch (_) {
      updatesPort?.send('offline');
    }
  }

  controlPort.listen((msg) async {
    if (msg is Map && msg['type'] == 'config') {
      interval = Duration(milliseconds: msg['intervalMs'] as int);
      urls = (msg['urls'] as List).cast<String>();

      timer?.cancel();
      timer = Timer.periodic(interval, (_) => tick());
      unawaited(tick());
    } else if (msg is Map && msg['type'] == 'listen') {
      updatesPort = msg['port'] as SendPort;
    } else if (msg is Map && msg['type'] == 'set_interval') {
      interval = Duration(milliseconds: msg['intervalMs'] as int);
      timer?.cancel();
      timer = Timer.periodic(interval, (_) => tick());
    } else if (msg is Map && msg['type'] == 'ping') {
      unawaited(tick());
    } else if (msg is Map && msg['type'] == 'stop') {
      timer?.cancel();
      controlPort.close();
    }
  });
}

Future<int> _probeUrl(
    String url, {
      Duration timeout = const Duration(seconds: 3),
    }) async {
  final uri = Uri.parse(url);
  final client = HttpClient()..connectionTimeout = timeout;
  try {
    final req = await client.getUrl(uri).timeout(timeout);
    req.followRedirects = false;
    final res = await req.close().timeout(timeout);
    return res.statusCode;
  } catch (_) {
    return -1;
  } finally {
    client.close(force: true);
  }
}
