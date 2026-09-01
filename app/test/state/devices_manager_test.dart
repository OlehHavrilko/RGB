import 'package:chromify/state/devices_manager.dart';
import 'package:chromify/state/prefs.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<Prefs> _newPrefs() async {
  SharedPreferences.setMockInitialValues({});
  return Prefs(await SharedPreferences.getInstance());
}

void main() {
  group('DevicesManager', () {
    test('без сохранённых устройств sessions пуст', () async {
      final manager = DevicesManager(await _newPrefs());
      expect(manager.sessions, isEmpty);
      expect(manager.knownDevices, isEmpty);
    });

    test('восстанавливает сессии для уже известных устройств', () async {
      final prefs = await _newPrefs();
      await prefs.touchKnownDevice('AA:AA', 'Лента 1');
      await prefs.touchKnownDevice('BB:BB', 'Лента 2');

      final manager = DevicesManager(prefs);

      expect(manager.knownDevices.map((d) => d.id), ['BB:BB', 'AA:AA']);
      expect(manager.sessions.map((s) => s.id), ['BB:BB', 'AA:AA']);
      expect(manager.sessions.map((s) => s.name), ['Лента 2', 'Лента 1']);
    });

    test('controllerFor и scheduleFor возвращают один и тот же экземпляр', () async {
      final manager = DevicesManager(await _newPrefs());
      final a = manager.controllerFor('AA:AA', name: 'Лента');
      final b = manager.controllerFor('AA:AA');
      final schedA = manager.scheduleFor('AA:AA');
      final schedB = manager.scheduleFor('AA:AA');

      expect(identical(a, b), isTrue);
      expect(identical(schedA, schedB), isTrue);
    });

    test('каждое устройство держит независимое состояние ленты', () async {
      final manager = DevicesManager(await _newPrefs());
      final a = manager.controllerFor('AA:AA');
      final b = manager.controllerFor('BB:BB');

      a.setPower(true);

      expect(a.led.power, isTrue);
      expect(b.led.power, isFalse);
    });

    test('forget убирает устройство из известных и из sessions', () async {
      final prefs = await _newPrefs();
      await prefs.touchKnownDevice('AA:AA', 'Лента');
      final manager = DevicesManager(prefs);
      expect(manager.knownDevices, isNotEmpty);

      await manager.forget('AA:AA');

      expect(manager.knownDevices, isEmpty);
      expect(manager.sessions, isEmpty);
    });

    test('изменение состояния одного устройства оповещает DevicesManager', () async {
      final manager = DevicesManager(await _newPrefs());
      final ctrl = manager.controllerFor('AA:AA');
      var notified = false;
      manager.addListener(() => notified = true);

      ctrl.setPower(true);

      expect(notified, isTrue);
    });
  });
}
