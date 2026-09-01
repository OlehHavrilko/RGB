import 'package:chromify/l10n/app_locale.dart';
import 'package:chromify/l10n/app_strings.dart';
import 'package:chromify/protocol/effect_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const ru = AppStrings(AppLocale.ru);
  const en = AppStrings(AppLocale.en);

  group('AppStrings — базовые строки', () {
    test('простые геттеры переключаются по языку', () {
      expect(ru.cancel, 'Отмена');
      expect(en.cancel, 'Cancel');
      expect(ru.presets, 'Пресеты');
      expect(en.presets, 'Presets');
    });

    test('строки с параметрами подставляют значения на обоих языках', () {
      expect(ru.presetDefaultName(3), 'Пресет 3');
      expect(en.presetDefaultName(3), 'Preset 3');
      expect(ru.connectedOfKnown(2, 5), 'Подключено: 2 из 5');
      expect(en.connectedOfKnown(2, 5), 'Connected: 2 of 5');
    });

    test('dayLabels даёт 7 подписей на нужном языке', () {
      expect(ru.dayLabels, ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс']);
      expect(en.dayLabels, ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']);
    });
  });

  group('AppStrings.willSaveSceneState — русское склонение', () {
    test('1 устройство → «устройства» (родительный падеж)', () {
      expect(ru.willSaveSceneState(1, 'Лента'),
          contains('1 устройства'));
    });

    test('2, 3, 4 → «устройств» кроме особых случаев', () {
      expect(ru.willSaveSceneState(2, 'x'), contains('2 устройств'));
    });

    test('11 → «устройств» (исключение из общего правила)', () {
      expect(ru.willSaveSceneState(11, 'x'), contains('11 устройств'));
    });

    test('21 → «устройства» (11 — исключение, 21 — нет)', () {
      expect(ru.willSaveSceneState(21, 'x'), contains('21 устройства'));
    });

    test('английская версия использует простую форму device/devices', () {
      expect(en.willSaveSceneState(1, 'Strip'), contains('1 device'));
      expect(en.willSaveSceneState(2, 'Strip'), contains('2 devices'));
    });
  });

  group('AppStrings.effectName', () {
    test('на русском возвращает исходное имя без изменений', () {
      expect(ru.effectName('Плавный красный'), 'Плавный красный');
    });

    test('на английском переводит', () {
      expect(en.effectName('Плавный красный'), 'Fade red');
    });

    test('неизвестное имя на английском откатывается к исходному', () {
      expect(en.effectName('Совершенно новый эффект'), 'Совершенно новый эффект');
    });

    test('весь каталог эффектов имеет перевод на английский', () {
      for (final effect in kEffectCatalog) {
        final translated = en.effectName(effect.name);
        expect(translated, isNot(equals(effect.name)),
            reason: '"${effect.name}" не переведён на английский');
      }
    });
  });
}
