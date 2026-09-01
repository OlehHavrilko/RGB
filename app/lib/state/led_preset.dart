import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'led_state.dart';

/// Именованный снимок состояния ленты, который пользователь может сохранить
/// и применить одним нажатием.
@immutable
class LedPreset {
  const LedPreset({
    required this.id,
    required this.name,
    required this.state,
  });

  final String id;
  final String name;
  final LedState state;

  LedPreset copyWith({String? name, LedState? state}) => LedPreset(
        id: id,
        name: name ?? this.name,
        state: state ?? this.state,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'state': state.toJson(),
      };

  /// Возвращает `null`, если объект не похож на пресет.
  static LedPreset? fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final state = json['state'];
    if (id is! String || id.isEmpty) return null;
    if (name is! String || name.isEmpty) return null;
    if (state is! Map) return null;
    return LedPreset(
      id: id,
      name: name,
      state: LedState.fromJson(state.cast<String, dynamic>()),
    );
  }

  String encode() => jsonEncode(toJson());

  static LedPreset? decode(String raw) {
    try {
      final obj = jsonDecode(raw);
      return obj is Map ? fromJson(obj.cast<String, dynamic>()) : null;
    } catch (_) {
      return null;
    }
  }
}
