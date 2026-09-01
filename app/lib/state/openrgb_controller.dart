import 'dart:async';

import 'package:flutter/material.dart';

import '../openrgb/openrgb_client.dart';
import 'prefs.dart';

enum OpenRgbConnectionState { disconnected, connecting, connected, failed }

/// Состояние экрана «ПК»: подключение к OpenRGB SDK Server и отправка
/// сплошного цвета на одно устройство. См. предупреждение в
/// `OpenRgbClient` — протокол не проверялся против реального сервера.
class OpenRgbController extends ChangeNotifier {
  OpenRgbController(this._prefs) : _client = OpenRgbClient();

  final Prefs _prefs;
  final OpenRgbClient _client;

  String get lastHost => _prefs.openRgbHost ?? '';
  int get lastPort => _prefs.openRgbPort ?? 6742;

  OpenRgbConnectionState _state = OpenRgbConnectionState.disconnected;
  String? _error;
  int _controllerCount = 0;

  OpenRgbConnectionState get state => _state;
  String? get error => _error;
  int get controllerCount => _controllerCount;
  bool get isConnected => _state == OpenRgbConnectionState.connected;

  Future<void> connect(String host, int port) async {
    _state = OpenRgbConnectionState.connecting;
    _error = null;
    notifyListeners();
    try {
      await _client.connect(host, port);
      _client.setClientName('Chromify');
      _controllerCount = await _client.requestControllerCount();
      _state = OpenRgbConnectionState.connected;
      await _prefs.setOpenRgbEndpoint(host, port);
    } catch (e) {
      await _client.disconnect();
      _state = OpenRgbConnectionState.failed;
      _error = e.toString();
    }
    notifyListeners();
  }

  Future<void> disconnect() async {
    await _client.disconnect();
    _state = OpenRgbConnectionState.disconnected;
    _controllerCount = 0;
    notifyListeners();
  }

  void applyColor(int deviceIndex, int ledCount, Color color) {
    if (!isConnected) return;
    _client.setSolidColor(
      deviceIndex,
      ledCount,
      ((color.r * 255).round(), (color.g * 255).round(), (color.b * 255).round()),
    );
  }

  @override
  void dispose() {
    unawaited(_client.disconnect());
    super.dispose();
  }
}
