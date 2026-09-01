import 'package:flutter_test/flutter_test.dart';
import 'package:chromify/protocol/elk_bledom_codec.dart';

/// Ожидаемые байты сверены с несколькими независимыми реверс-инжинирингами
/// протокола ELK-BLEDOM.
void main() {
  List<int> hex(String s) => [
        for (final p in s.split(' ')) int.parse(p, radix: 16),
      ];

  group('ElkBledomCodec', () {
    test('питание включить', () {
      expect(ElkBledomCodec.power(true), hex('7E 00 04 F0 00 01 FF 00 EF'));
    });

    test('питание выключить', () {
      expect(ElkBledomCodec.power(false), hex('7E 00 04 00 00 00 FF 00 EF'));
    });

    test('цвет RGB', () {
      expect(
        ElkBledomCodec.color(0x11, 0x22, 0x33),
        hex('7E 00 05 03 11 22 33 00 EF'),
      );
    });

    test('цвет — каналы клампятся в 0..255', () {
      expect(
        ElkBledomCodec.color(-10, 300, 128),
        hex('7E 00 05 03 00 FF 80 00 EF'),
      );
    });

    test('яркость в процентах', () {
      expect(ElkBledomCodec.brightness(50), hex('7E 00 01 32 00 00 00 00 EF'));
      expect(ElkBledomCodec.brightness(0), hex('7E 00 01 00 00 00 00 00 EF'));
      expect(ElkBledomCodec.brightness(100), hex('7E 00 01 64 00 00 00 00 EF'));
    });

    test('яркость клампится в 0..100', () {
      expect(ElkBledomCodec.brightness(250), hex('7E 00 01 64 00 00 00 00 EF'));
      expect(ElkBledomCodec.brightness(-5), hex('7E 00 01 00 00 00 00 00 EF'));
    });

    test('белый: тёплый + холодный = 100', () {
      expect(ElkBledomCodec.white(70), hex('7E 00 05 02 46 1E 00 00 EF'));
      expect(ElkBledomCodec.white(0), hex('7E 00 05 02 00 64 00 00 EF'));
      expect(ElkBledomCodec.white(100), hex('7E 00 05 02 64 00 00 00 EF'));
    });

    test('встроенный эффект', () {
      expect(ElkBledomCodec.effect(0x87), hex('7E 00 03 87 03 00 00 00 EF'));
    });

    test('скорость эффекта', () {
      expect(ElkBledomCodec.effectSpeed(25), hex('7E 00 02 19 00 00 00 00 EF'));
      expect(ElkBledomCodec.effectSpeed(999), hex('7E 00 02 64 00 00 00 00 EF'));
    });

    test('синхронизация времени', () {
      final t = DateTime(2026, 8, 31, 13, 5, 9);
      final frame = ElkBledomCodec.syncTime(t);
      expect(frame.sublist(0, 6), hex('7E 00 83 0D 05 09'));
      expect(frame[6], t.weekday); // день недели, Пн=1..Вс=7
      expect(frame.sublist(7), hex('00 EF'));
    });

    test('все кадры ровно 9 байт и обрамлены 7E .. EF', () {
      final frames = [
        ElkBledomCodec.power(true),
        ElkBledomCodec.color(1, 2, 3),
        ElkBledomCodec.brightness(42),
        ElkBledomCodec.white(33),
        ElkBledomCodec.effect(0x90),
        ElkBledomCodec.effectSpeed(60),
        ElkBledomCodec.syncTime(DateTime(2026)),
      ];
      for (final f in frames) {
        expect(f.length, 9);
        expect(f.first, 0x7E);
        expect(f.last, 0xEF);
      }
    });
  });
}
