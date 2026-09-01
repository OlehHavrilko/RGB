import 'package:chromify/state/led_state.dart';
import 'package:chromify/state/scene.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SceneEntry', () {
    test('round-trip через toJson/fromJson', () {
      const entry = SceneEntry(
        deviceId: 'AA:AA',
        deviceName: 'Лента 1',
        state: LedState(color: Color(0xFF00FF88), brightness: 42),
      );
      final restored = SceneEntry.fromJson(entry.toJson());
      expect(restored, isNotNull);
      expect(restored!.deviceId, 'AA:AA');
      expect(restored.deviceName, 'Лента 1');
      expect(restored.state, entry.state);
    });

    test('fromJson отклоняет запись без deviceId/state', () {
      expect(SceneEntry.fromJson({'deviceName': 'x', 'state': {}}), isNull);
      expect(SceneEntry.fromJson({'deviceId': '', 'state': {}}), isNull);
      expect(SceneEntry.fromJson({'deviceId': 'AA'}), isNull);
    });
  });

  group('Scene', () {
    Scene sample() => const Scene(
          id: 'scene-1',
          name: 'Вечер',
          entries: [
            SceneEntry(
              deviceId: 'AA:AA',
              deviceName: 'Лента 1',
              state: LedState(color: Color(0xFFFF8800)),
            ),
            SceneEntry(
              deviceId: 'BB:BB',
              deviceName: 'Лента 2',
              state: LedState(color: Color(0xFF2222FF), power: true),
            ),
          ],
        );

    test('round-trip через encode/decode', () {
      final decoded = Scene.decode(sample().encode());
      expect(decoded, isNotNull);
      expect(decoded!.id, 'scene-1');
      expect(decoded.name, 'Вечер');
      expect(decoded.entries.length, 2);
      expect(decoded.entries[0].deviceId, 'AA:AA');
      expect(decoded.entries[1].state.power, isTrue);
    });

    test('fromJson отклоняет запись без id/name/entries', () {
      expect(Scene.fromJson({'name': 'x', 'entries': []}), isNull);
      expect(Scene.fromJson({'id': 'x', 'entries': []}), isNull);
      expect(Scene.fromJson({'id': 'x', 'name': 'y'}), isNull);
    });

    test('fromJson отклоняет сцену без валидных записей', () {
      expect(
        Scene.fromJson({'id': 'x', 'name': 'y', 'entries': [1, 2, 'x']}),
        isNull,
      );
    });

    test('decode на мусоре возвращает null', () {
      expect(Scene.decode('{'), isNull);
      expect(Scene.decode('42'), isNull);
    });
  });
}
