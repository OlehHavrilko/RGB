import 'dart:async';

/// Ограничитель частоты отправки: не чаще одного вызова в [interval],
/// при этом гарантированно доставляет последний запрошенный вызов.
class Debouncer {
  Debouncer(this.interval);

  final Duration interval;
  Timer? _timer;
  DateTime _lastRun = DateTime.fromMillisecondsSinceEpoch(0);
  void Function()? _pending;

  void call(void Function() action) {
    final now = DateTime.now();
    final sinceLast = now.difference(_lastRun);
    if (sinceLast >= interval && _timer == null) {
      _lastRun = now;
      action();
      return;
    }
    _pending = action;
    _timer ??= Timer(interval - sinceLast, _flush);
  }

  void _flush() {
    _timer = null;
    final action = _pending;
    _pending = null;
    if (action != null) {
      _lastRun = DateTime.now();
      action();
    }
  }

  /// Немедленно выполнить отложенное действие (например, на отпускание слайдера).
  void flushNow() {
    _timer?.cancel();
    _flush();
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    _pending = null;
  }
}
