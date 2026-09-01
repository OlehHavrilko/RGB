import 'dart:async';

import 'package:flutter/foundation.dart';

import '../ble/ble_device.dart';
import '../ble/ble_service.dart';

/// Виды ошибок скана — без готового текста, чтобы UI мог локализовать его
/// сам (см. `AppStrings`). [ScanErrorKind.startFailed] несёт техническую
/// деталь в [ScanController.errorDetail] (не локализуется — это текст
/// исключения платформы).
enum ScanErrorKind { noPermission, bluetoothOff, startFailed }

/// Состояние экрана поиска устройств.
class ScanController extends ChangeNotifier {
  ScanController(this._ble) {
    _availabilitySub = _ble.availabilityChanges.listen((a) {
      _availability = a;
      notifyListeners();
    });
    _resultsSub = _ble.scanResults.listen(_onResult);
    _refreshAvailability();
  }

  final BleService _ble;
  StreamSubscription<BleAvailability>? _availabilitySub;
  StreamSubscription<DiscoveredDevice>? _resultsSub;
  Timer? _pruneTimer;

  final Map<String, DiscoveredDevice> _devices = {};
  BleAvailability _availability = BleAvailability.unknown;
  bool _scanning = false;
  ScanErrorKind? _errorKind;
  String? _errorDetail;

  BleAvailability get availability => _availability;
  bool get isScanning => _scanning;
  ScanErrorKind? get errorKind => _errorKind;

  /// Техническая деталь для [ScanErrorKind.startFailed] (текст исключения
  /// платформы) — `null` для остальных видов ошибок.
  String? get errorDetail => _errorDetail;

  /// Поддерживаемые контроллеры сверху, затем — по убыванию уровня сигнала.
  List<DiscoveredDevice> get devices {
    final list = _devices.values.toList()
      ..sort((a, b) {
        if (a.isSupported != b.isSupported) return a.isSupported ? -1 : 1;
        return b.rssi.compareTo(a.rssi);
      });
    return list;
  }

  Future<void> _refreshAvailability() async {
    _availability = await _ble.currentAvailability();
    notifyListeners();
  }

  void _onResult(DiscoveredDevice device) {
    if (device.name.isEmpty && !_devices.containsKey(device.id)) return;
    final existing = _devices[device.id];
    _devices[device.id] = device.name.isEmpty && existing != null
        ? existing.copyWith(rssi: device.rssi, seenAt: DateTime.now())
        : device;
    notifyListeners();
  }

  Future<void> toggleScan() => _scanning ? stopScan() : startScan();

  Future<void> startScan() async {
    _errorKind = null;
    _errorDetail = null;
    await _refreshAvailability();
    if (_availability != BleAvailability.ready) {
      final ok = await _ble.ensurePermissions();
      await _refreshAvailability();
      if (!ok && _availability == BleAvailability.unauthorized) {
        _errorKind = ScanErrorKind.noPermission;
        notifyListeners();
        return;
      }
      if (_availability == BleAvailability.poweredOff) {
        _errorKind = ScanErrorKind.bluetoothOff;
        notifyListeners();
        return;
      }
    }

    try {
      await _ble.startScan();
      _scanning = true;
      _pruneTimer?.cancel();
      _pruneTimer =
          Timer.periodic(const Duration(seconds: 3), (_) => _pruneStale());
      notifyListeners();
    } catch (e) {
      _errorKind = ScanErrorKind.startFailed;
      _errorDetail = '$e';
      _scanning = false;
      notifyListeners();
    }
  }

  Future<void> stopScan() async {
    await _ble.stopScan();
    _scanning = false;
    _pruneTimer?.cancel();
    notifyListeners();
  }

  void _pruneStale() {
    final now = DateTime.now();
    final before = _devices.length;
    _devices.removeWhere(
      (_, d) => !d.isSupported && now.difference(d.seenAt).inSeconds > 12,
    );
    if (_devices.length != before) notifyListeners();
  }

  void clear() {
    _devices.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _availabilitySub?.cancel();
    _resultsSub?.cancel();
    _pruneTimer?.cancel();
    unawaited(_ble.stopScan());
    super.dispose();
  }
}
