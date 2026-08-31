import 'package:universal_ble/universal_ble.dart';

/// Известные GATT-адреса ELK-BLEDOM и логика их поиска после подключения.
class ElkEndpoints {
  ElkEndpoints._();

  /// Рабочий сервис управления (в рекламе устройство отдаёт 0x7777,
  /// но команды принимает сервис из семейства 0xfff0).
  static const String serviceUuid = 'fff0';

  /// Характеристика записи команд (write without response).
  static const String writeUuid = 'fff3';

  /// Характеристика уведомлений о состоянии (есть не на всех прошивках).
  static const String notifyUuid = 'fff4';

  /// Имя, по которому опознаётся контроллер в результатах сканирования.
  static const String deviceNamePrefix = 'ELK-BLEDOM';

  static bool _uuidContains(String uuid, String short) =>
      uuid.toLowerCase().contains(short.toLowerCase());

  /// Найти пару (service, characteristic) для записи команд.
  ///
  /// Сначала пробуем каноничные `fff0/fff3`, затем — любой сервис `fffX`
  /// с характеристикой, поддерживающей запись без ответа.
  static ({String service, String characteristic})? resolveWrite(
    List<BleService> services,
  ) {
    for (final s in services) {
      if (!_uuidContains(s.uuid, 'fff0')) continue;
      for (final c in s.characteristics) {
        if (_uuidContains(c.uuid, writeUuid)) {
          return (service: s.uuid, characteristic: c.uuid);
        }
      }
    }
    for (final s in services) {
      if (!_uuidContains(s.uuid, 'fff')) continue;
      for (final c in s.characteristics) {
        final writable = c.properties.contains(
              CharacteristicProperty.writeWithoutResponse,
            ) ||
            c.properties.contains(CharacteristicProperty.write);
        if (writable) {
          return (service: s.uuid, characteristic: c.uuid);
        }
      }
    }
    return null;
  }

  /// Найти характеристику уведомлений о состоянии, если она есть.
  static ({String service, String characteristic})? resolveNotify(
    List<BleService> services,
  ) {
    for (final s in services) {
      for (final c in s.characteristics) {
        final canNotify = c.properties.contains(CharacteristicProperty.notify) ||
            c.properties.contains(CharacteristicProperty.indicate);
        if (canNotify && _uuidContains(c.uuid, notifyUuid)) {
          return (service: s.uuid, characteristic: c.uuid);
        }
      }
    }
    for (final s in services) {
      if (!_uuidContains(s.uuid, 'fff')) continue;
      for (final c in s.characteristics) {
        final canNotify = c.properties.contains(CharacteristicProperty.notify) ||
            c.properties.contains(CharacteristicProperty.indicate);
        if (canNotify) {
          return (service: s.uuid, characteristic: c.uuid);
        }
      }
    }
    return null;
  }

  /// Похоже ли устройство на поддерживаемый контроллер.
  static bool looksSupported(String? name) {
    if (name == null) return false;
    return name.toUpperCase().contains('ELK-BLEDOM') ||
        name.toUpperCase().contains('ELK-BLE') ||
        name.toUpperCase().contains('LEDBLE') ||
        name.toUpperCase().contains('MELK');
  }
}
