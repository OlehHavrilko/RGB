import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:universal_ble/universal_ble.dart';

import 'ble_device.dart';

/// Состояние адаптера Bluetooth в понятных приложению терминах.
enum BleAvailability { unknown, unsupported, unauthorized, poweredOff, ready }

BleAvailability _mapAvailability(AvailabilityState s) {
  switch (s) {
    case AvailabilityState.poweredOn:
      return BleAvailability.ready;
    case AvailabilityState.poweredOff:
    case AvailabilityState.resetting:
      return BleAvailability.poweredOff;
    case AvailabilityState.unauthorized:
      return BleAvailability.unauthorized;
    case AvailabilityState.unsupported:
      return BleAvailability.unsupported;
    case AvailabilityState.unknown:
      return BleAvailability.unknown;
  }
}

/// Сканирование устройств и контроль доступности адаптера.
/// Один экземпляр на всё приложение.
class BleService {
  BleService() {
    UniversalBle.onAvailabilityChange = (state) {
      _availability.add(_mapAvailability(state));
    };
  }

  final _scanResults = StreamController<DiscoveredDevice>.broadcast();
  final _availability = StreamController<BleAvailability>.broadcast();

  bool _isScanning = false;
  bool get isScanning => _isScanning;

  Stream<DiscoveredDevice> get scanResults => _scanResults.stream;
  Stream<BleAvailability> get availabilityChanges => _availability.stream;

  Future<BleAvailability> currentAvailability() async {
    try {
      return _mapAvailability(await UniversalBle.getBluetoothAvailabilityState());
    } catch (e) {
      debugPrint('BLE availability error: $e');
      return BleAvailability.unknown;
    }
  }

  /// Запросить рантайм-разрешения (актуально для Android; на Windows — no-op).
  Future<bool> ensurePermissions() async {
    try {
      if (await UniversalBle.hasPermissions()) return true;
      await UniversalBle.requestPermissions();
      return await UniversalBle.hasPermissions();
    } catch (e) {
      debugPrint('BLE permission error: $e');
      return false;
    }
  }

  Future<void> startScan() async {
    if (_isScanning) return;
    _isScanning = true;
    UniversalBle.onScanResult = (device) {
      final name = device.name ?? device.rawName ?? '';
      _scanResults.add(
        DiscoveredDevice(
          id: device.deviceId,
          name: name,
          rssi: device.rssi ?? -100,
        ),
      );
    };
    try {
      await UniversalBle.startScan(
        scanFilter: ScanFilter(withServices: const []),
      );
    } catch (e) {
      _isScanning = false;
      rethrow;
    }
  }

  Future<void> stopScan() async {
    if (!_isScanning) return;
    _isScanning = false;
    UniversalBle.onScanResult = null;
    try {
      await UniversalBle.stopScan();
    } catch (e) {
      debugPrint('BLE stopScan error: $e');
    }
  }

  void dispose() {
    unawaited(stopScan());
    _scanResults.close();
    _availability.close();
  }
}
