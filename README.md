# Chromify

Приложение для управления RGB/ARGB-подсветкой с телефона или ПК. Первый
шаг — управление лентами на BLE-контроллере **ELK-BLEDOM** с Android и
Windows на одном коде (Flutter).

[![CI](https://github.com/OlehHavrilko/RGB/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/OlehHavrilko/RGB/actions/workflows/ci.yml)
[![Android APK](https://github.com/OlehHavrilko/RGB/actions/workflows/android-apk.yml/badge.svg)](https://github.com/OlehHavrilko/RGB/actions/workflows/android-apk.yml)
[![Windows installer](https://github.com/OlehHavrilko/RGB/actions/workflows/windows-installer.yml/badge.svg)](https://github.com/OlehHavrilko/RGB/actions/workflows/windows-installer.yml)
[![Latest release](https://img.shields.io/github/v/release/OlehHavrilko/RGB?label=latest%20release)](https://github.com/OlehHavrilko/RGB/releases/latest)

## Скачать

**[⬇ Последний релиз](https://github.com/OlehHavrilko/RGB/releases/latest)** — `.apk` для Android и `Chromify-Setup-x64.exe` для Windows одним кликом.

Свежее (но без стабильного номера версии) можно взять и прямо из CI:

- **Android** — `.apk` из последнего прогона workflow [Android APK](https://github.com/OlehHavrilko/RGB/actions/workflows/android-apk.yml) (вкладка Artifacts).
- **Windows** — инсталлятор из последнего прогона workflow [Windows installer](https://github.com/OlehHavrilko/RGB/actions/workflows/windows-installer.yml).

## Возможности (кратко)

- Многодевайсность, режим синхронизации и сцены — управление несколькими
  лентами сразу.
- Пресеты, экспорт/импорт, таймер сна, ежедневное расписание,
  будильник-рассвет.
- Локализация RU/EN, виджет главного экрана Android.
- Экспериментальный клиент OpenRGB SDK для ARGB-подсветки ПК (не
  проверялся против реального сервера).

Полное описание возможностей, структура проекта и инструкции по сборке —
в [`app/README.md`](app/README.md). Планы по развитию — в
[`ROADMAP.md`](ROADMAP.md).
