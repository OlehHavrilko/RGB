import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgb_controller/state/led_preset.dart';
import 'package:rgb_controller/state/led_state.dart';

void main() {
  group('LedState сериализация', () {
    test('round-trip сохраняет все поля', () {
      const state = LedState(
        power: true,
        color: Color(0xFF123456),
        brightness: 42,
        mode: LedMode.white,
        warm: 30,
        effectId: 0x8B,
        effectSpeed: 77,
      );
      final restored = LedState.fromJson(state.toJson());
      expect(restored, state);
    });

    test('encode/decode через строку', () {
      const state = LedState(color: Color(0xFF00FF88), brightness: 10);
      expect(LedState.tryDecode(state.encode()), state);
    });

    test('неизвестный режим откатывается к color', () {
      final restored = LedState.fromJson({'mode': 'strobe', 'brightness': 50});
      expect(restored.mode, LedMode.color);
      expect(restored.brightness, 50);
    });

    test('битые/отсутствующие поля заменяются значениями по умолчанию', () {
      final restored = LedState.fromJson({
        'power': 'yes',
        'color': 'red',
        'brightness': 999,
        'warm': -5,
        'effectSpeed': null,
      });
      const d = LedState();
      expect(restored.power, false);
      expect(restored.color, d.color);
      expect(restored.brightness, 100); // clamp к верхней границе
      expect(restored.warm, 0); // clamp к нижней границе
      expect(restored.effectSpeed, d.effectSpeed);
    });

    test('tryDecode на мусоре возвращает null', () {
      expect(LedState.tryDecode('не json'), isNull);
      expect(LedState.tryDecode('[1,2,3]'), isNull);
    });
  });

  group('LedPreset', () {
    LedPreset sample() => const LedPreset(
          id: 'abc',
          name: 'Вечер',
          state: LedState(color: Color(0xFFFF8800), brightness: 65),
        );

    test('round-trip через encode/decode', () {
      final decoded = LedPreset.decode(sample().encode());
      expect(decoded, isNotNull);
      expect(decoded!.id, 'abc');
      expect(decoded.name, 'Вечер');
      expect(decoded.state, sample().state);
    });

    test('fromJson отклоняет запись без id/name/state', () {
      expect(LedPreset.fromJson({'name': 'x', 'state': {}}), isNull);
      expect(LedPreset.fromJson({'id': 'x', 'state': {}}), isNull);
      expect(LedPreset.fromJson({'id': 'x', 'name': 'y'}), isNull);
      expect(LedPreset.fromJson({'id': '', 'name': 'y', 'state': {}}), isNull);
    });

    test('decode на мусоре возвращает null', () {
      expect(LedPreset.decode('{'), isNull);
      expect(LedPreset.decode('42'), isNull);
    });
  });
}
