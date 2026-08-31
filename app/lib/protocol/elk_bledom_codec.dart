import 'dart:typed_data';

/// Кодек протокола BLE-контроллера **ELK-BLEDOM**.
///
/// Каждая команда — ровно 9 байт вида
/// `7E 00 <cmd> <p1> <p2> <p3> <p4> 00 EF`.
/// Отправляются в write-характеристику `fff3` без подтверждения
/// (write without response).
///
/// Класс не зависит от Flutter и полностью покрыт unit-тестами
/// (`test/protocol/elk_bledom_codec_test.dart`).
class ElkBledomCodec {
  ElkBledomCodec._();

  static const int _start = 0x7E;
  static const int _end = 0xEF;

  /// Собрать кадр команды. Все параметры приводятся к диапазону байта.
  static Uint8List _frame(int cmd, int p1, int p2, int p3, int p4) {
    return Uint8List.fromList([
      _start,
      0x00,
      cmd & 0xFF,
      p1 & 0xFF,
      p2 & 0xFF,
      p3 & 0xFF,
      p4 & 0xFF,
      0x00,
      _end,
    ]);
  }

  static int _clamp(int v, int lo, int hi) =>
      v < lo ? lo : (v > hi ? hi : v);

  /// Питание ленты.
  ///
  /// Вкл:  `7E 00 04 F0 00 01 FF 00 EF`
  /// Выкл: `7E 00 04 00 00 00 FF 00 EF`
  static Uint8List power(bool on) => on
      ? _frame(0x04, 0xF0, 0x00, 0x01, 0xFF)
      : _frame(0x04, 0x00, 0x00, 0x00, 0xFF);

  /// Статический цвет RGB. Каждый канал 0..255.
  ///
  /// `7E 00 05 03 RR GG BB 00 EF`
  static Uint8List color(int r, int g, int b) => _frame(
        0x05,
        0x03,
        _clamp(r, 0, 255),
        _clamp(g, 0, 255),
        _clamp(b, 0, 255),
      );

  /// Яркость в процентах 0..100.
  ///
  /// `7E 00 01 XX 00 00 00 00 EF`
  static Uint8List brightness(int percent) =>
      _frame(0x01, _clamp(percent, 0, 100), 0x00, 0x00, 0x00);

  /// Режим белого свечения: [warmPercent] 0..100, холодный = 100 - тёплый.
  ///
  /// `7E 00 05 02 WW CC 00 00 EF`
  static Uint8List white(int warmPercent) {
    final warm = _clamp(warmPercent, 0, 100);
    return _frame(0x05, 0x02, warm, 100 - warm, 0x00);
  }

  /// Встроенный эффект по идентификатору (обычно 0x80..0x9C).
  ///
  /// `7E 00 03 MM 03 00 00 00 EF`
  static Uint8List effect(int id) =>
      _frame(0x03, id & 0xFF, 0x03, 0x00, 0x00);

  /// Скорость проигрывания эффекта в процентах 0..100.
  ///
  /// `7E 00 02 SS 00 00 00 00 EF`
  static Uint8List effectSpeed(int percent) =>
      _frame(0x02, _clamp(percent, 0, 100), 0x00, 0x00, 0x00);

  /// Синхронизация внутренних часов контроллера (для таймеров, этап 2).
  ///
  /// `7E 00 83 HH MM SS WW 00 EF`, где WW — день недели (1=Пн ... 7=Вс).
  static Uint8List syncTime(DateTime now) {
    final weekday = now.weekday; // 1..7, Dart: Пн=1
    return Uint8List.fromList([
      _start,
      0x00,
      0x83,
      now.hour & 0xFF,
      now.minute & 0xFF,
      now.second & 0xFF,
      weekday & 0xFF,
      0x00,
      _end,
    ]);
  }
}
