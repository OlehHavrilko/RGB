import 'elk_endpoints.dart';

/// Устройство, найденное при сканировании.
class DiscoveredDevice {
  DiscoveredDevice({
    required this.id,
    required this.name,
    required this.rssi,
    DateTime? seenAt,
  }) : seenAt = seenAt ?? DateTime.now();

  final String id;
  final String name;
  final int rssi;
  final DateTime seenAt;

  bool get isSupported => ElkEndpoints.looksSupported(name);

  /// Имя для отображения, если у устройства нет собственного BLE-имени.
  /// Языконезависимый fallback — локализованную подпись «Без имени»/
  /// «No name» показывает сам UI (см. `AppStrings.withoutName`).
  String get displayName => name.isEmpty ? id : name;

  DiscoveredDevice copyWith({String? name, int? rssi, DateTime? seenAt}) {
    return DiscoveredDevice(
      id: id,
      name: name ?? this.name,
      rssi: rssi ?? this.rssi,
      seenAt: seenAt ?? this.seenAt,
    );
  }
}
