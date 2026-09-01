import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:chromify/protocol/status_parser.dart';

void main() {
  Uint8List bytes(String s) => Uint8List.fromList(
        [for (final p in s.split(' ')) int.parse(p, radix: 16)],
      );

  group('StatusParser', () {
    test('разбирает статус с питанием и цветом', () {
      final st = StatusParser.parse(bytes('7E 01 F0 FF 80 00 64 00 EF'));
      expect(st, isNotNull);
      expect(st!.power, true);
      expect(st.r, 0xFF);
      expect(st.g, 0x80);
      expect(st.b, 0x00);
      expect(st.brightness, 100);
    });

    test('распознаёт выключенное состояние', () {
      final st = StatusParser.parse(bytes('7E 01 24 00 00 00 00 00 EF'));
      expect(st!.power, false);
    });

    test('отбрасывает пакет без рамки', () {
      expect(StatusParser.parse(bytes('01 02 03 04 05 06 07 08')), isNull);
    });

    test('отбрасывает пакет неверного типа', () {
      expect(
        StatusParser.parse(bytes('7E 05 03 FF 00 00 00 00 EF')),
        isNull,
      );
    });

    test('слишком короткий пакет — null', () {
      expect(StatusParser.parse(bytes('7E 01 F0')), isNull);
    });

    test('яркость больше 100 отбрасывается', () {
      final st = StatusParser.parse(bytes('7E 01 F0 10 20 30 C8 00 EF'));
      expect(st!.brightness, isNull);
    });
  });
}
