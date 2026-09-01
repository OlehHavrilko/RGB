import 'package:chromify/state/device_controller.dart';
import 'package:chromify/state/prefs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<DeviceController> _newController({String id = 'AA:BB:CC:DD:EE:FF'}) async {
  SharedPreferences.setMockInitialValues({});
  return DeviceController(Prefs(await SharedPreferences.getInstance()), id: id);
}

void main() {
  group('DeviceController экспорт/импорт пресетов', () {
    test('экспорт пустого списка даёт пустой JSON-массив', () async {
      final ctrl = await _newController();
      expect(ctrl.exportPresetsJson(), '[]');
    });

    test('round-trip: экспорт → импорт в другой контроллер', () async {
      final source = await _newController();
      await source.saveCurrentAsPreset('Вечер');
      source.setColor(const Color(0xFF00FF88), commit: true);
      await source.saveCurrentAsPreset('Ночь');
      final json = source.exportPresetsJson();

      final target = await _newController();
      final added = await target.importPresetsJson(json);

      expect(added, 2);
      expect(target.presets.map((p) => p.name), ['Вечер', 'Ночь']);
    });

    test('повторный импорт того же JSON не перезаписывает, а добавляет копии',
        () async {
      final ctrl = await _newController();
      await ctrl.saveCurrentAsPreset('Пресет');
      final json = ctrl.exportPresetsJson();

      final added = await ctrl.importPresetsJson(json);

      expect(added, 1);
      expect(ctrl.presets.length, 2);
      expect(ctrl.presets.map((p) => p.id).toSet().length, 2,
          reason: 'id импортированной копии должен отличаться от исходного');
    });

    test('мусор в буфере не добавляет пресетов', () async {
      final ctrl = await _newController();
      expect(await ctrl.importPresetsJson('не json'), 0);
      expect(await ctrl.importPresetsJson('{"id":"x"}'), 0);
      expect(await ctrl.importPresetsJson('[1,2,3]'), 0);
      expect(ctrl.presets, isEmpty);
    });
  });
}
