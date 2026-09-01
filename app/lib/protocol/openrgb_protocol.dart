import 'dart:convert';
import 'dart:typed_data';

/// Кодек сетевого протокола **OpenRGB SDK** (TCP, порт по умолчанию 6742).
///
/// Значения ниже (magic-заголовок, номера пакетов, формат `UpdateLEDs`)
/// сверены с исходниками OpenRGB (`NetworkProtocol.h`,
/// `RGBController.cpp`/`RGBController_Network.cpp`), но реального
/// OpenRGB SDK Server для сквозной проверки не было — количество
/// светодиодов на устройство приложение поэтому не вычитывает из ответа
/// сервера, а получает от пользователя вручную (см. `OpenRgbController`).
///
/// Класс не зависит от Flutter/dart:io и полностью покрыт unit-тестами.
class OpenRgbProtocol {
  OpenRgbProtocol._();

  static const int headerSize = 16;
  static const List<int> _magic = [0x4F, 0x52, 0x47, 0x42]; // "ORGB"

  static const int packetIdRequestControllerCount = 0;
  static const int packetIdRequestControllerData = 1;
  static const int packetIdRequestProtocolVersion = 40;
  static const int packetIdSetClientName = 50;
  static const int packetIdUpdateLeds = 1050;

  /// Заголовок пакета: `"ORGB"` + device_id(u32) + packet_id(u32) +
  /// data_size(u32), всё little-endian — итого 16 байт.
  static Uint8List header({
    required int deviceId,
    required int packetId,
    required int dataSize,
  }) {
    final b = ByteData(headerSize);
    for (var i = 0; i < 4; i++) {
      b.setUint8(i, _magic[i]);
    }
    b.setUint32(4, deviceId, Endian.little);
    b.setUint32(8, packetId, Endian.little);
    b.setUint32(12, dataSize, Endian.little);
    return b.buffer.asUint8List();
  }

  /// Разбирает заголовок ответа. `null`, если magic не совпал или байт
  /// меньше 16.
  static ({int deviceId, int packetId, int dataSize})? decodeHeader(
    Uint8List bytes,
  ) {
    if (bytes.length < headerSize) return null;
    for (var i = 0; i < 4; i++) {
      if (bytes[i] != _magic[i]) return null;
    }
    final b = ByteData.sublistView(bytes, 0, headerSize);
    return (
      deviceId: b.getUint32(4, Endian.little),
      packetId: b.getUint32(8, Endian.little),
      dataSize: b.getUint32(12, Endian.little),
    );
  }

  /// Тело пакета `SET_CLIENT_NAME` — имя клиента, обязательно с нулевым
  /// байтом на конце (сервер требует C-строку).
  static Uint8List clientNamePayload(String name) {
    final bytes = utf8.encode(name);
    final out = Uint8List(bytes.length + 1);
    out.setRange(0, bytes.length, bytes);
    return out; // последний байт уже 0 (Uint8List инициализируется нулями).
  }

  /// Тело пакета `REQUEST_PROTOCOL_VERSION` — версия протокола клиента.
  static Uint8List protocolVersionRequestPayload(int clientVersion) {
    final b = ByteData(4)..setUint32(0, clientVersion, Endian.little);
    return b.buffer.asUint8List();
  }

  /// Версия протокола сервера из ответа на `REQUEST_PROTOCOL_VERSION`.
  static int? decodeProtocolVersion(Uint8List data) {
    if (data.length < 4) return null;
    return ByteData.sublistView(data, 0, 4).getUint32(0, Endian.little);
  }

  /// Число контроллеров из ответа на `REQUEST_CONTROLLER_COUNT`.
  static int? decodeControllerCount(Uint8List data) {
    if (data.length < 4) return null;
    return ByteData.sublistView(data, 0, 4).getUint32(0, Endian.little);
  }

  /// Тело пакета `RGBCONTROLLER_UPDATELEDS`:
  /// `data_size(u32) + num_colors(u16) + RGBColor[num_colors]`, где
  /// `RGBColor` — 4 байта `R G B 0x00` (little-endian `0x00BBGGRR`).
  static Uint8List updateLedsPayload(List<(int r, int g, int b)> colors) {
    final colorBytes = 4 * colors.length;
    final dataSize = 4 + 2 + colorBytes; // сам себя + count + цвета
    final out = ByteData(4 + 2 + colorBytes);
    out.setUint32(0, dataSize, Endian.little);
    out.setUint16(4, colors.length, Endian.little);
    var offset = 6;
    for (final (r, g, b) in colors) {
      out.setUint8(offset, r & 0xFF);
      out.setUint8(offset + 1, g & 0xFF);
      out.setUint8(offset + 2, b & 0xFF);
      out.setUint8(offset + 3, 0x00);
      offset += 4;
    }
    return out.buffer.asUint8List();
  }
}
