# RGB Control

Приложение для управления RGB-лентой через BLE-контроллер **ELK-BLEDOM**.
Flutter, один код для Windows и Android. Первый этап — Windows.

## Возможности (этап 1 — ядро)

- Поиск BLE-устройств и подключение, автопереподключение при разрыве.
- Включение / выключение ленты.
- Выбор цвета: HSV-круг + слайдеры R/G/B + быстрые цвета.
- Яркость.
- Режим белого света (тёплый ↔ холодный).
- Встроенные эффекты + регулировка скорости.
- Современный тёмный интерфейс: «стеклянные» карточки, живое свечение фона
  под текущий цвет, анимации переходов и нажатий.

Дальше по плану: микрофон/музыкальная реакция, таймеры и расписание,
пользовательские пресеты, иконка и упаковка, локализация.

## Структура

```
lib/
  protocol/   кодек команд ELK-BLEDOM (чистый Dart, покрыт тестами)
  ble/        обёртка universal_ble: сканирование, соединение, запись
  state/      DeviceController / ScanController (provider + ChangeNotifier)
  ui/         тема, переиспользуемые виджеты, экраны scan/ и control/
test/
  protocol/   unit-тесты кодека и парсера статуса
```

## Разработка в WSL (анализ и тесты)

Flutter SDK установлен в `~/flutter`.

```bash
export PATH="$HOME/flutter/bin:$PATH"
cd ~/work/RGB/app
flutter pub get
flutter analyze
flutter test
```

Можно быстро посмотреть интерфейс в браузере (Web Bluetooth работает
в Chrome/Edge, но основная цель — Windows):

```bash
flutter run -d chrome
```

## Сборка и запуск на Windows

BLE под Windows требует нативной сборки, поэтому её запускают **со стороны
Windows**, а не из WSL.

### Один раз

1. Установить **Visual Studio 2022** с рабочей нагрузкой
   **«Разработка классических приложений на C++» (Desktop development with C++)**.
2. Установить **Flutter SDK для Windows**
   (<https://docs.flutter.dev/get-started/install/windows>) и добавить
   `flutter\bin` в `PATH`.
3. Включить Bluetooth в системе (Параметры → Bluetooth и устройства).
4. Проверка окружения: `flutter doctor` — разделы **Windows** и
   **Visual Studio** должны быть отмечены галочкой.

### Запуск

В PowerShell или Windows Terminal:

```powershell
cd \\wsl.localhost\Ubuntu-24.04\home\oleh\work\RGB\app
flutter config --enable-windows-desktop
flutter pub get
flutter run -d windows
```

Сборка релизного `.exe`:

```powershell
flutter build windows --release
# результат: build\windows\x64\runner\Release\
```

> Проект лежит в файловой системе WSL. Обычно всё работает по пути
> `\\wsl.localhost\...`, но hot reload по сети иногда пропускает изменения —
> тогда нажмите `R` (hot restart) в консоли `flutter run`. Если будут
> странности со сборкой — скопируйте папку `app` на диск `C:` и соберите
> оттуда.

## Как пользоваться

1. Запитать контроллер, включить Bluetooth.
2. Открыть приложение — начнётся поиск. Контроллер появится как
   **ELK-BLEDOM** с пометкой «поддерживается».
3. Нажать на него — откроется экран управления и произойдёт подключение.
4. Кнопка-«шар» — питание. Ниже — режимы: Цвет / Белый / Эффекты и яркость.

## Протокол ELK-BLEDOM (кратко)

- Сервис `0000fff0-…`, характеристика записи `0000fff3-…`, write without response.
- Кадр 9 байт: `7E 00 <cmd> <p1..p4> 00 EF`.
- Питание вкл: `7E 00 04 F0 00 01 FF 00 EF`, выкл: `7E 00 04 00 00 00 FF 00 EF`.
- Цвет: `7E 00 05 03 RR GG BB 00 EF`; яркость: `7E 00 01 XX 00 00 00 00 EF`.
- Белый: `7E 00 05 02 <тёплый> <холодный> 00 00 EF` (сумма = 100).
- Эффект: `7E 00 03 <id> 03 00 00 00 EF`; скорость: `7E 00 02 SS 00 00 00 00 EF`.

Полная таблица и подписи эффектов — в `lib/protocol/`.
