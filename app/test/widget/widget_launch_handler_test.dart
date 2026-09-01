import 'package:chromify/state/devices_manager.dart';
import 'package:chromify/state/prefs.dart';
import 'package:chromify/widget/widget_launch_handler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<Prefs> _newPrefs() async {
  SharedPreferences.setMockInitialValues({});
  return Prefs(await SharedPreferences.getInstance());
}

void main() {
  group('handleWidgetLaunch', () {
    test('игнорирует URI с чужим host', () async {
      final manager = DevicesManager(await _newPrefs());
      await handleWidgetLaunch(
        Uri.parse('chromify://other?action=toggle&id=AA:AA'),
        manager,
      );
      // Не бросает и не создаёт сессию для несуществующего устройства.
      expect(manager.sessions, isEmpty);
    });

    test('игнорирует URI без action или id', () async {
      final manager = DevicesManager(await _newPrefs());
      await handleWidgetLaunch(
        Uri.parse('chromify://widget?action=toggle'),
        manager,
      );
      await handleWidgetLaunch(
        Uri.parse('chromify://widget?id=AA:AA'),
        manager,
      );
      expect(manager.sessions, isEmpty);
    });

    test('игнорирует неизвестное устройство', () async {
      final manager = DevicesManager(await _newPrefs());
      await handleWidgetLaunch(
        Uri.parse('chromify://widget?action=toggle&id=AA:AA'),
        manager,
      );
      expect(manager.sessions, isEmpty);
    });
  });
}
