import 'package:chromify/l10n/app_locale.dart';
import 'package:chromify/l10n/locale_controller.dart';
import 'package:chromify/state/prefs.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<Prefs> _newPrefs() async {
  SharedPreferences.setMockInitialValues({});
  return Prefs(await SharedPreferences.getInstance());
}

void main() {
  group('LocaleController', () {
    test('без сохранённого выбора использует локаль системы', () async {
      final controller = LocaleController(
        await _newPrefs(),
        systemLocale: AppLocale.en,
      );
      expect(controller.locale, AppLocale.en);
    });

    test('setLocale меняет локаль, сохраняет в Prefs и оповещает', () async {
      final prefs = await _newPrefs();
      final controller =
          LocaleController(prefs, systemLocale: AppLocale.en);
      var notified = false;
      controller.addListener(() => notified = true);

      controller.setLocale(AppLocale.ru);

      expect(controller.locale, AppLocale.ru);
      expect(notified, isTrue);
      expect(prefs.localeCode, 'ru');
    });

    test('повторная установка того же значения не оповещает', () async {
      final controller = LocaleController(
        await _newPrefs(),
        systemLocale: AppLocale.en,
      );
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.setLocale(AppLocale.en); // уже en
      expect(notifications, 0);

      controller.setLocale(AppLocale.ru);
      expect(notifications, 1);
    });

    test('toggle переключает на противоположный язык', () async {
      final controller = LocaleController(
        await _newPrefs(),
        systemLocale: AppLocale.ru,
      );

      controller.toggle();
      expect(controller.locale, AppLocale.en);

      controller.toggle();
      expect(controller.locale, AppLocale.ru);
    });

    test('сохранённый пользователем выбор переживает пересоздание', () async {
      final prefs = await _newPrefs();
      final first = LocaleController(prefs, systemLocale: AppLocale.en);
      first.setLocale(AppLocale.ru);

      final second = LocaleController(prefs, systemLocale: AppLocale.en);

      expect(second.locale, AppLocale.ru);
    });
  });
}
