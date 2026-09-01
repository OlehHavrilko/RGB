import 'dart:ui';

/// Языки интерфейса, которые понимает `AppStrings`.
enum AppLocale {
  ru('ru'),
  en('en');

  const AppLocale(this.languageCode);

  final String languageCode;

  Locale toLocale() => Locale(languageCode);

  /// Из кода языка системы — 'ru' даёт русский, всё остальное английский
  /// (более безопасный универсальный выбор по умолчанию, чем русский).
  static AppLocale fromLanguageCode(String? code) =>
      code == 'ru' ? AppLocale.ru : AppLocale.en;

  AppLocale get other => this == AppLocale.ru ? AppLocale.en : AppLocale.ru;
}
