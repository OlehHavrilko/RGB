import 'dart:async';

import 'package:home_widget/home_widget.dart';

import '../state/devices_manager.dart';

/// Имя нативного `AppWidgetProvider` на Android — должно совпадать с
/// `android/app/src/main/kotlin/.../ChromifyWidgetProvider.kt`.
const androidWidgetProviderName = 'ChromifyWidgetProvider';

/// Держит виджет главного экрана Android в актуальном состоянии: имя,
/// питание, цвет и до двух пресетов активного устройства (предпочитаем
/// подключённое, иначе — первое известное) — чтобы можно было включить/
/// выключить ленту или применить пресет одним тапом с рабочего стола.
class HomeWidgetService {
  HomeWidgetService(this._manager) {
    _manager.addListener(_onManagerChanged);
    unawaited(_onManagerChanged());
  }

  final DevicesManager _manager;

  Future<void> _onManagerChanged() async {
    final sessions = _manager.sessions;
    if (sessions.isEmpty) {
      await HomeWidget.saveWidgetData('device_known', false);
      await HomeWidget.updateWidget(androidName: androidWidgetProviderName);
      return;
    }

    var active = sessions.first;
    for (final s in sessions) {
      if (s.isConnected) {
        active = s;
        break;
      }
    }

    final presets = active.presets;
    await HomeWidget.saveWidgetData('device_known', true);
    await HomeWidget.saveWidgetData('device_id', active.id);
    await HomeWidget.saveWidgetData('device_name', active.name);
    await HomeWidget.saveWidgetData('device_connected', active.isConnected);
    await HomeWidget.saveWidgetData('device_power', active.led.power);
    await HomeWidget.saveWidgetData(
      'device_color',
      active.led.displayColor.toARGB32(),
    );
    for (var i = 0; i < 2; i++) {
      if (i < presets.length) {
        await HomeWidget.saveWidgetData('preset_${i}_id', presets[i].id);
        await HomeWidget.saveWidgetData(
          'preset_${i}_color',
          presets[i].state.displayColor.toARGB32(),
        );
      } else {
        await HomeWidget.saveWidgetData<String>('preset_${i}_id', null);
      }
    }
    await HomeWidget.updateWidget(androidName: androidWidgetProviderName);
  }

  void dispose() => _manager.removeListener(_onManagerChanged);
}
