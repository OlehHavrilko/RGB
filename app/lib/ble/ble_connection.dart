import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:universal_ble/universal_ble.dart';

import '../protocol/status_parser.dart';
import 'elk_endpoints.dart';

/// Стадии жизненного цикла соединения с контроллером.
enum LinkState {
  disconnected,
  connecting,
  discovering,
  connected,
  reconnecting,
  failed,
}

/// Управляет одним подключением к ELK-BLEDOM: connect / discover / write,
/// автопереподключение с экспоненциальной задержкой и разбор статус-пакетов.
class ElkConnection {
  ElkConnection(this.deviceId);

  final String deviceId;

  final _state = StreamController<LinkState>.broadcast();
  final _status = StreamController<ElkStatus>.broadcast();

  Stream<LinkState> get stateStream => _state.stream;
  Stream<ElkStatus> get statusStream => _status.stream;

  LinkState _current = LinkState.disconnected;
  LinkState get state => _current;

  String? _writeService;
  String? _writeChar;

  StreamSubscription<bool>? _connSub;
  StreamSubscription<Uint8List>? _notifySub;
  Timer? _reconnectTimer;
  int _attempt = 0;
  bool _manualDisconnect = false;
  bool _disposed = false;

  static const _maxBackoff = Duration(seconds: 20);

  /// Сколько раз пробуем переподключиться, если после connect не удалось
  /// найти характеристику записи (сервис-кэш иногда пуст сразу после connect).
  static const _maxDiscoverRetries = 3;

  void _setState(LinkState s) {
    if (_disposed || _current == s) return;
    _current = s;
    _state.add(s);
  }

  Future<void> connect() async {
    _manualDisconnect = false;
    _reconnectTimer?.cancel();
    await _connSub?.cancel();

    _connSub = UniversalBle.connectionStream(deviceId).listen(_onConnectionChange);

    _setState(_attempt == 0 ? LinkState.connecting : LinkState.reconnecting);
    try {
      await UniversalBle.connect(deviceId, timeout: const Duration(seconds: 20));
    } catch (e) {
      debugPrint('ElkConnection connect error: $e');
      _handleDrop();
    }
  }

  Future<void> _onConnectionChange(bool isConnected) async {
    if (_disposed) return;
    if (isConnected) {
      await _onConnected();
    } else {
      _handleDrop();
    }
  }

  Future<void> _onConnected() async {
    _setState(LinkState.discovering);
    try {
      final services = await UniversalBle.discoverServices(deviceId);
      final write = ElkEndpoints.resolveWrite(services);
      if (write == null) {
        _handleDiscoveryFailure('write characteristic not found');
        return;
      }
      _writeService = write.service;
      _writeChar = write.characteristic;

      final notify = ElkEndpoints.resolveNotify(services);
      if (notify != null) {
        try {
          await UniversalBle.subscribeNotifications(
            deviceId,
            notify.service,
            notify.characteristic,
          );
          await _notifySub?.cancel();
          _notifySub = UniversalBle.characteristicValueStream(
            deviceId,
            notify.characteristic,
          ).listen(_onNotify);
        } catch (e) {
          debugPrint('ElkConnection: notify subscribe failed: $e');
        }
      }

      _attempt = 0;
      _setState(LinkState.connected);
    } catch (e) {
      _handleDiscoveryFailure('discover error: $e');
    }
  }

  /// Discovery не удалась: пока не исчерпан лимит — переподключаемся с
  /// нарастающей задержкой, иначе окончательно [LinkState.failed].
  void _handleDiscoveryFailure(String why) {
    debugPrint('ElkConnection: $why');
    if (_manualDisconnect || _disposed) return;
    if (_attempt >= _maxDiscoverRetries) {
      _setState(LinkState.failed);
      return;
    }
    unawaited(UniversalBle.disconnect(deviceId).catchError((_) {}));
    _setState(LinkState.reconnecting);
    _scheduleReconnect();
  }

  void _onNotify(Uint8List value) {
    final parsed = StatusParser.parse(value);
    if (parsed != null && !_disposed) _status.add(parsed);
  }

  void _handleDrop() {
    _writeService = null;
    _writeChar = null;
    if (_manualDisconnect || _disposed) {
      _setState(LinkState.disconnected);
      return;
    }
    _setState(LinkState.reconnecting);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _attempt++;
    final backoffMs =
        (500 * (1 << (_attempt - 1))).clamp(500, _maxBackoff.inMilliseconds);
    _reconnectTimer = Timer(Duration(milliseconds: backoffMs), () {
      if (!_manualDisconnect && !_disposed) connect();
    });
  }

  /// Отправить 9-байтный кадр команды. Тихо игнорируется, если нет соединения.
  Future<void> sendFrame(Uint8List frame) async {
    final service = _writeService;
    final characteristic = _writeChar;
    if (service == null || characteristic == null) return;
    try {
      await UniversalBle.write(
        deviceId,
        service,
        characteristic,
        frame,
        withoutResponse: true,
      );
    } catch (e) {
      debugPrint('ElkConnection write error: $e');
    }
  }

  Future<void> disconnect() async {
    _manualDisconnect = true;
    _reconnectTimer?.cancel();
    _attempt = 0;
    await _notifySub?.cancel();
    _notifySub = null;
    try {
      await UniversalBle.disconnect(deviceId);
    } catch (e) {
      debugPrint('ElkConnection disconnect error: $e');
    }
    _setState(LinkState.disconnected);
  }

  Future<void> dispose() async {
    _disposed = true;
    _reconnectTimer?.cancel();
    await _connSub?.cancel();
    await _notifySub?.cancel();
    try {
      await UniversalBle.disconnect(deviceId);
    } catch (_) {}
    await _state.close();
    await _status.close();
  }
}
