import 'package:chromify/state/openrgb_controller.dart';
import 'package:chromify/state/prefs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<Prefs> _newPrefs() async {
  SharedPreferences.setMockInitialValues({});
  return Prefs(await SharedPreferences.getInstance());
}

void main() {
  group('OpenRgbController', () {
    test('изначально отключён, без сохранённого адреса — порт по умолчанию 6742', () async {
      final ctrl = OpenRgbController(await _newPrefs());
      expect(ctrl.state, OpenRgbConnectionState.disconnected);
      expect(ctrl.isConnected, isFalse);
      expect(ctrl.lastHost, isEmpty);
      expect(ctrl.lastPort, 6742);
    });

    test('applyColor ничего не делает и не бросает, пока не подключено', () async {
      final ctrl = OpenRgbController(await _newPrefs());
      expect(
        () => ctrl.applyColor(0, 10, const Color(0xFFFF0000)),
        returnsNormally,
      );
      expect(ctrl.state, OpenRgbConnectionState.disconnected);
    });

    test('connect с недостижимым адресом переводит в failed с текстом ошибки', () async {
      final ctrl = OpenRgbController(await _newPrefs());
      await ctrl.connect('127.0.0.1', 1); // порт 1: соединение будет отклонено
      expect(ctrl.state, OpenRgbConnectionState.failed);
      expect(ctrl.error, isNotNull);
      expect(ctrl.isConnected, isFalse);
    });
  });
}
