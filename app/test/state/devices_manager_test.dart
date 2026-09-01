import 'package:chromify/state/devices_manager.dart';
import 'package:chromify/state/prefs.dart';
import 'package:flutter/material.dart';
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

    test('syncEnabled по умолчанию выключен и переключается', () async {
      final manager = DevicesManager(await _newPrefs());
      expect(manager.syncEnabled, isFalse);

      var notified = false;
      manager.addListener(() => notified = true);
      manager.setSyncEnabled(true);

      expect(manager.syncEnabled, isTrue);
      expect(notified, isTrue);
    });

    test('повторная установка того же значения syncEnabled не оповещает', () async {
      final manager = DevicesManager(await _newPrefs());
      var notifications = 0;
      manager.addListener(() => notifications++);

      manager.setSyncEnabled(false); // уже false
      expect(notifications, 0);

      manager.setSyncEnabled(true);
      manager.setSyncEnabled(true); // уже true
      expect(notifications, 1);
    });

    test('broadcastFrom ничего не делает при выключенной синхронизации', () async {
      final manager = DevicesManager(await _newPrefs());
      final origin = manager.controllerFor('AA:AA');
      manager.controllerFor('BB:BB');

      var calls = 0;
      manager.broadcastFrom(origin, (_) => calls++);

      expect(calls, 0);
    });

    test(
        'broadcastFrom при включённой синхронизации не трогает несоединённые '
        'устройства (в тестах BLE не подключается по-настоящему)', () async {
      final manager = DevicesManager(await _newPrefs());
      manager.setSyncEnabled(true);
      final origin = manager.controllerFor('AA:AA');
      manager.controllerFor('BB:BB');

      var calls = 0;
      manager.broadcastFrom(origin, (_) => calls++);

      // Ни одно из устройств не в состоянии connected, поэтому рассылка
      // никого не задевает — это и есть ожидаемое поведение guard'а.
      expect(calls, 0);
    });

    test('saveScene снимает состояние указанных устройств и applyScene его возвращает',
        () async {
      final manager = DevicesManager(await _newPrefs());
      final a = manager.controllerFor('AA:AA', name: 'Лента 1');
      final b = manager.controllerFor('BB:BB', name: 'Лента 2');
      a.setColor(const Color(0xFFFF0000), commit: true);
      a.setPower(true);
      b.setColor(const Color(0xFF00FF00), commit: true);
      b.setPower(false);

      await manager.saveScene('Вечер', ['AA:AA', 'BB:BB']);
      expect(manager.scenes, hasLength(1));
      final scene = manager.scenes.single;
      expect(scene.name, 'Вечер');
      expect(scene.entries, hasLength(2));

      // Меняем состояние на другое, потом применяем сцену — должно вернуть,
      // включая питание (a была включена, b — выключена).
      a.setColor(const Color(0xFF0000FF), commit: true);
      a.setPower(false);
      b.setPower(true);
      manager.applyScene(scene.id);

      expect(a.led.color, const Color(0xFFFF0000));
      expect(a.led.power, isTrue);
      expect(b.led.color, const Color(0xFF00FF00));
      expect(b.led.power, isFalse);
    });

    test('saveScene с пустым именем или без известных устройств ничего не создаёт',
        () async {
      final manager = DevicesManager(await _newPrefs());
      manager.controllerFor('AA:AA');

      await manager.saveScene('   ', ['AA:AA']);
      expect(manager.scenes, isEmpty);

      await manager.saveScene('Сцена', ['ZZ:ZZ']); // нет такой сессии
      expect(manager.scenes, isEmpty);
    });

    test('deleteScene убирает сцену', () async {
      final manager = DevicesManager(await _newPrefs());
      manager.controllerFor('AA:AA');
      await manager.saveScene('Сцена', ['AA:AA']);
      final id = manager.scenes.single.id;

      await manager.deleteScene(id);

      expect(manager.scenes, isEmpty);
    });

    test('applyScene на неизвестный id ничего не ломает', () async {
      final manager = DevicesManager(await _newPrefs());
      expect(() => manager.applyScene('нет такой'), returnsNormally);
    });
  });
}
