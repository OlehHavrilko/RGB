import '../state/devices_manager.dart';

/// Разбирает URI, которым виджет главного экрана Android открыл приложение
/// (`chromify://widget?action=toggle|preset&id=<deviceId>[&preset=<presetId>]`),
/// и выполняет соответствующее действие — без похода в экран управления.
///
/// Тап по виджету всегда открывает приложение (headless-выполнение BLE-команд
/// без открытия UI ненадёжно и не проверялось на реальном железе), но
/// действие применяется сразу же после подключения.
Future<void> handleWidgetLaunch(Uri uri, DevicesManager manager) async {
  if (uri.host != 'widget') return;
  final id = uri.queryParameters['id'];
  final action = uri.queryParameters['action'];
  if (id == null || action == null) return;
  if (!manager.knownDevices.any((d) => d.id == id)) return;

  final ctrl = manager.controllerFor(id);
  if (!ctrl.isConnected) {
    await manager
        .connectKnown(id)
        .timeout(const Duration(seconds: 8), onTimeout: () {});
  }
  if (!ctrl.isConnected) return;

  switch (action) {
    case 'toggle':
      ctrl.togglePower();
    case 'preset':
      final presetId = uri.queryParameters['preset'];
      if (presetId == null) return;
      for (final p in ctrl.presets) {
        if (p.id == presetId) {
          ctrl.applyPreset(p);
          if (!ctrl.led.power) ctrl.setPower(true);
          break;
        }
      }
  }
}
