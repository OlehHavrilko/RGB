import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'led_state.dart';

/// Состояние одного устройства внутри сцены. Имя устройства сохраняется
/// вместе со снимком (а не берётся из списка известных устройств «на
/// лету»), чтобы сцена оставалась осмысленной, даже если это устройство
/// потом забыли.
@immutable
class SceneEntry {
  const SceneEntry({
    required this.deviceId,
    required this.deviceName,
    required this.state,
  });

  final String deviceId;
  final String deviceName;
  final LedState state;

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'deviceName': deviceName,
        'state': state.toJson(),
      };

  static SceneEntry? fromJson(Map<String, dynamic> json) {
    final deviceId = json['deviceId'];
    final state = json['state'];
    if (deviceId is! String || deviceId.isEmpty) return null;
    if (state is! Map) return null;
    final deviceName = json['deviceName'];
    return SceneEntry(
      deviceId: deviceId,
      deviceName: deviceName is String ? deviceName : '',
      state: LedState.fromJson(state.cast<String, dynamic>()),
    );
  }
}

/// Сцена: именованный снимок состояний **нескольких** устройств сразу —
/// на разных лентах могут быть разные цвета/режимы, применяются одним
/// действием (`DevicesManager.applyScene`).
@immutable
class Scene {
  const Scene({
    required this.id,
    required this.name,
    required this.entries,
  });

  final String id;
  final String name;
  final List<SceneEntry> entries;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'entries': entries.map((e) => e.toJson()).toList(),
      };

  /// Возвращает `null`, если объект не похож на сцену.
  static Scene? fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final rawEntries = json['entries'];
    if (id is! String || id.isEmpty) return null;
    if (name is! String || name.isEmpty) return null;
    if (rawEntries is! List) return null;
    final entries = rawEntries
        .whereType<Map>()
        .map((e) => SceneEntry.fromJson(e.cast<String, dynamic>()))
        .whereType<SceneEntry>()
        .toList();
    if (entries.isEmpty) return null;
    return Scene(id: id, name: name, entries: entries);
  }

  String encode() => jsonEncode(toJson());

  static Scene? decode(String raw) {
    try {
      final obj = jsonDecode(raw);
      return obj is Map ? fromJson(obj.cast<String, dynamic>()) : null;
    } catch (_) {
      return null;
    }
  }
}
