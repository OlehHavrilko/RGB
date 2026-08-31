import 'dart:typed_data';

/// Разобранный статус-пакет от контроллера (характеристика `fff4`).
///
/// Разные прошивки ELK-BLEDOM шлют статус по-разному и не всегда; поэтому
/// парсер работает по принципу best-effort, а поля — опциональные.
class ElkStatus {
  const ElkStatus({this.power, this.r, this.g, this.b, this.brightness});

  final bool? power;
  final int? r;
  final int? g;
  final int? b;
  final int? brightness;

  @override
  String toString() =>
      'ElkStatus(power: $power, rgb: ($r,$g,$b), brightness: $brightness)';
}

class StatusParser {
  StatusParser._();

  /// Ожидаемый формат: `7E <type> <power> <r> <g> <b> <bright%> .. EF`.
  /// Возвращает `null`, если пакет не похож на статус.
  static ElkStatus? parse(Uint8List data) {
    if (data.length < 8) return null;
    if (data.first != 0x7E || data.last != 0xEF) return null;

    // type == 0x01 — обновление состояния.
    if (data[1] != 0x01) return null;

    bool? power;
    final p = data[2];
    if (p == 0x23 || p == 0xF0 || p == 0x01) power = true;
    if (p == 0x24 || p == 0x00) power = false;

    final r = data[3];
    final g = data[4];
    final b = data[5];
    final bright = data[6];

    return ElkStatus(
      power: power,
      r: r,
      g: g,
      b: b,
      brightness: bright <= 100 ? bright : null,
    );
  }
}
