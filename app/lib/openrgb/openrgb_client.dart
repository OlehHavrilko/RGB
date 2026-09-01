import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import '../protocol/openrgb_protocol.dart';

/// Клиент **OpenRGB SDK** по TCP: подключение к уже запущенному на ПК
/// OpenRGB (SDK Server, порт по умолчанию 6742), проверка связи и отправка
/// сплошного цвета на устройство.
///
/// Не тестировался против реального OpenRGB SDK Server (в песочнице, где
/// это писалось, нет ни Windows/Linux-машины с ARGB-железом, ни запущенного
/// OpenRGB) — байтовый формат заголовка, `SET_CLIENT_NAME`,
/// `REQUEST_CONTROLLER_COUNT` и `RGBCONTROLLER_UPDATELEDS` сверен с
/// исходниками OpenRGB, но `REQUEST_CONTROLLER_DATA` (имя/зоны/светодиоды
/// устройства) сознательно не реализован: это самая вложенная и наименее
/// проверенная часть протокола. Поэтому число светодиодов на устройство
/// приложение сейчас не вычитывает само, а получает от пользователя (см.
/// `OpenRgbController`).
class OpenRgbClient {
  OpenRgbClient();

  Socket? _socket;
  StreamSubscription<Uint8List>? _sub;
  final BytesBuilder _buffer = BytesBuilder(copy: false);
  final _packets =
      StreamController<
        ({int deviceId, int packetId, Uint8List data})
      >.broadcast();

  bool get isConnected => _socket != null;

  Future<void> connect(
    String host,
    int port, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    await disconnect();
    final socket = await Socket.connect(host, port, timeout: timeout);
    _socket = socket;
    _sub = socket.listen(_onData, onError: (_) => disconnect(), onDone: disconnect);
  }

  Future<void> disconnect() async {
    await _sub?.cancel();
    _sub = null;
    final s = _socket;
    _socket = null;
    _buffer.clear();
    await s?.close();
  }

  void _onData(Uint8List chunk) {
    _buffer.add(chunk);
    var bytes = _buffer.toBytes();
    while (bytes.length >= OpenRgbProtocol.headerSize) {
      final hdr = OpenRgbProtocol.decodeHeader(bytes);
      if (hdr == null) {
        // Заголовок не распознан — поток рассинхронизирован, дальше
        // ничего осмысленного из него не собрать.
        bytes = Uint8List(0);
        break;
      }
      final total = OpenRgbProtocol.headerSize + hdr.dataSize;
      if (bytes.length < total) break;
      _packets.add((
        deviceId: hdr.deviceId,
        packetId: hdr.packetId,
        data: bytes.sublist(OpenRgbProtocol.headerSize, total),
      ));
      bytes = bytes.sublist(total);
    }
    _buffer.clear();
    if (bytes.isNotEmpty) _buffer.add(bytes);
  }

  void _send(int deviceId, int packetId, Uint8List payload) {
    final socket = _socket;
    if (socket == null) return;
    socket
      ..add(
        OpenRgbProtocol.header(
          deviceId: deviceId,
          packetId: packetId,
          dataSize: payload.length,
        ),
      )
      ..add(payload);
  }

  Future<Uint8List> _request(
    int deviceId,
    int packetId,
    Uint8List payload, {
    Duration timeout = const Duration(seconds: 5),
  }) {
    final future = _packets.stream
        .firstWhere((p) => p.packetId == packetId && p.deviceId == deviceId)
        .then((p) => p.data)
        .timeout(timeout);
    _send(deviceId, packetId, payload);
    return future;
  }

  /// Представиться серверу — вызывать сразу после подключения.
  void setClientName(String name) {
    _send(
      0,
      OpenRgbProtocol.packetIdSetClientName,
      OpenRgbProtocol.clientNamePayload(name),
    );
  }

  /// Число контроллеров на сервере — заодно проверка, что связь и формат
  /// заголовка совпали с сервером.
  Future<int> requestControllerCount() async {
    final data = await _request(
      0,
      OpenRgbProtocol.packetIdRequestControllerCount,
      Uint8List(0),
    );
    return OpenRgbProtocol.decodeControllerCount(data) ?? 0;
  }

  /// Отправить сплошной цвет на все [ledCount] светодиодов устройства
  /// [deviceId] (индекс контроллера на сервере, начиная с 0).
  void setSolidColor(int deviceId, int ledCount, (int r, int g, int b) rgb) {
    _send(
      deviceId,
      OpenRgbProtocol.packetIdUpdateLeds,
      OpenRgbProtocol.updateLedsPayload(List.filled(ledCount, rgb)),
    );
  }
}
