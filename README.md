# Chromify

Приложение для управления RGB/ARGB-подсветкой с телефона или ПК. Первый
шаг — управление лентами на BLE-контроллере **ELK-BLEDOM** с Android и
Windows на одном коде (Flutter).

[![CI](https://github.com/OlehHavrilko/RGB/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/OlehHavrilko/RGB/actions/workflows/ci.yml)
[![Android APK](https://github.com/OlehHavrilko/RGB/actions/workflows/android-apk.yml/badge.svg)](https://github.com/OlehHavrilko/RGB/actions/workflows/android-apk.yml)
[![Windows installer](https://github.com/OlehHavrilko/RGB/actions/workflows/windows-installer.yml/badge.svg)](https://github.com/OlehHavrilko/RGB/actions/workflows/windows-installer.yml)

## Скачать

- **Android** — `.apk` из последнего прогона workflow [Android APK](https://github.com/OlehHavrilko/RGB/actions/workflows/android-apk.yml) (вкладка Artifacts) или из [Releases](https://github.com/OlehHavrilko/RGB/releases), если собран релизный тег.
- **Windows** — инсталлятор `Chromify-Setup-x64.exe` из последнего прогона workflow [Windows installer](https://github.com/OlehHavrilko/RGB/actions/workflows/windows-installer.yml) или из [Releases](https://github.com/OlehHavrilko/RGB/releases).

## Возможности (кратко)

- Многодевайсность, режим синхронизации и сцены — управление несколькими
  лентами сразу.
- Пресеты, экспорт/импорт, таймер сна, ежедневное расписание,
  будильник-рассвет.
- Локализация RU/EN.

Полное описание возможностей, структура проекта и инструкции по сборке —
в [`app/README.md`](app/README.md). Планы по развитию — в
[`ROADMAP.md`](ROADMAP.md).
