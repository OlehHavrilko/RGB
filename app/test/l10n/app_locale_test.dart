import 'package:chromify/l10n/app_locale.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppLocale', () {
    test('fromLanguageCode("ru") даёт русский', () {
      expect(AppLocale.fromLanguageCode('ru'), AppLocale.ru);
    });

    test('fromLanguageCode на любом другом коде даёт английский', () {
      expect(AppLocale.fromLanguageCode('en'), AppLocale.en);
      expect(AppLocale.fromLanguageCode('de'), AppLocale.en);
      expect(AppLocale.fromLanguageCode(null), AppLocale.en);
      expect(AppLocale.fromLanguageCode(''), AppLocale.en);
    });

    test('other переключает между ru и en', () {
      expect(AppLocale.ru.other, AppLocale.en);
      expect(AppLocale.en.other, AppLocale.ru);
    });

    test('toLocale отдаёт правильный языковой код', () {
      expect(AppLocale.ru.toLocale().languageCode, 'ru');
      expect(AppLocale.en.toLocale().languageCode, 'en');
    });
  });
}
