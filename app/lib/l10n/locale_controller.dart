import 'package:flutter/widgets.dart';

import '../state/prefs.dart';
import 'app_locale.dart';

/// Текущий язык интерфейса. Пользовательский выбор сохраняется в [Prefs];
/// пока пользователь ничего не выбрал — язык берётся из локали системы.
class LocaleController extends ChangeNotifier {
  LocaleController(this._prefs, {required AppLocale systemLocale})
      : _locale = AppLocale.values.asNameMap()[_prefs.localeCode] ??
            systemLocale;

  final Prefs _prefs;
  AppLocale _locale;

  AppLocale get locale => _locale;

  void setLocale(AppLocale value) {
    if (_locale == value) return;
    _locale = value;
    _prefs.setLocaleCode(value.name);
    notifyListeners();
  }

  void toggle() => setLocale(_locale.other);

  static LocaleController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<_LocaleControllerScope>();
    assert(scope != null, 'LocaleController.of() called outside of scope');
    return scope!.controller;
  }
}

/// Прокидывает [LocaleController] вниз по дереву и перестраивает
/// подписчиков при смене языка — используется `AppStrings.of`.
class LocaleControllerScope extends StatefulWidget {
  const LocaleControllerScope({
    super.key,
    required this.controller,
    required this.child,
  });

  final LocaleController controller;
  final Widget child;

  @override
  State<LocaleControllerScope> createState() => _LocaleControllerScopeState();
}

class _LocaleControllerScopeState extends State<LocaleControllerScope> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChange);
  }

  @override
  void didUpdateWidget(LocaleControllerScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onChange);
      widget.controller.addListener(_onChange);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return _LocaleControllerScope(
      controller: widget.controller,
      locale: widget.controller.locale,
      child: widget.child,
    );
  }
}

class _LocaleControllerScope extends InheritedWidget {
  const _LocaleControllerScope({
    required this.controller,
    required this.locale,
    required super.child,
  });

  final LocaleController controller;
  final AppLocale locale;

  @override
  bool updateShouldNotify(_LocaleControllerScope oldWidget) =>
      oldWidget.locale != locale;
}
