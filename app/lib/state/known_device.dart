import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Устройство, с которым приложение когда-либо соединялось: сохраняется,
/// чтобы предлагать его в списке «Мои устройства» без нового скана.
@immutable
class KnownDevice {
  const KnownDevice({required this.id, required this.name});

  final String id;
  final String name;

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  static KnownDevice? fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    if (id is! String || id.isEmpty) return null;
    return KnownDevice(id: id, name: name is String ? name : '');
  }

  String encode() => jsonEncode(toJson());

  static KnownDevice? decode(String raw) {
    try {
      final obj = jsonDecode(raw);
      return obj is Map ? fromJson(obj.cast<String, dynamic>()) : null;
    } catch (_) {
      return null;
    }
  }
}
