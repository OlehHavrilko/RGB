import 'package:flutter/widgets.dart';

import 'app_locale.dart';
import 'locale_controller.dart';

/// Все строки интерфейса на русском и английском в одном месте — без
/// кодогенерации (`.arb`/`gen-l10n`), просто пара текстов на каждую строку
/// и переключатель по текущему [locale].
class AppStrings {
  const AppStrings(this.locale);

  final AppLocale locale;

  static AppStrings of(BuildContext context) =>
      AppStrings(LocaleController.of(context).locale);

  String _t(String ru, String en) => locale == AppLocale.ru ? ru : en;

  // ─────────────────────────────── общее ────────────────────────────────

  String get cancel => _t('Отмена', 'Cancel');
  String get save => _t('Сохранить', 'Save');
  String get delete => _t('Удалить', 'Delete');
  String get nameHint => _t('Название', 'Name');

  // ─────────────────────────── статус соединения ────────────────────────

  String get statusConnected => _t('Подключено', 'Connected');
  String get statusConnecting => _t('Подключение…', 'Connecting…');
  String get statusDiscovering => _t('Настройка…', 'Setting up…');
  String get statusReconnecting => _t('Переподключение…', 'Reconnecting…');
  String get statusFailed => _t('Ошибка связи', 'Connection error');
  String get statusDisconnected => _t('Отключено', 'Disconnected');
  String get retry => _t('Ещё раз', 'Retry');

  // ────────────────────────────── экран «Устройства» ─────────────────────

  String get devicesTitle => _t('Устройства', 'Devices');
  String get findYourController =>
      _t('Найдите свой контроллер подсветки', 'Find your light controller');
  String knownDevicesCount(int n) =>
      _t('Известно устройств: $n', 'Known devices: $n');
  String connectedOfKnown(int connected, int known) => _t(
      'Подключено: $connected из $known', 'Connected: $connected of $known');
  String get enableBluetooth =>
      _t('Включите Bluetooth в системе', 'Turn on Bluetooth');
  String get noBluetoothAccess =>
      _t('Нет доступа к Bluetooth', 'No Bluetooth access');
  String get scanNoPermission =>
      _t('Нет разрешения на Bluetooth', 'No Bluetooth permission');
  String get scanBluetoothOff => _t('Bluetooth выключен', 'Bluetooth is off');
  String scanStartFailed(String detail) =>
      _t('Не удалось запустить поиск: $detail',
          'Could not start scanning: $detail');
  String get myDevices => _t('Мои устройства', 'My devices');
  String get nearby => _t('Поблизости', 'Nearby');
  String get searchingForMore => _t('Ищем ещё…', 'Searching for more…');
  String get noMoreDevicesFound =>
      _t('Больше устройств не найдено', 'No more devices found');
  String get withoutName => _t('Без имени', 'No name');
  String get searchingDevices =>
      _t('Ищем устройства…', 'Searching for devices…');
  String get searchStopped => _t('Поиск остановлен', 'Search stopped');
  String get makeSureControllerPowered => _t(
      'Убедитесь, что контроллер запитан\nи находится рядом',
      'Make sure the controller is powered\nand nearby');
  String get stopScanning => _t('Остановить', 'Stop');
  String get searchAgain => _t('Искать заново', 'Search again');
  String get elkSupported =>
      _t('ELK-BLEDOM · поддерживается', 'ELK-BLEDOM · supported');
  String get bleDevice => _t('BLE-устройство', 'BLE device');
  String forgetDeviceTitle(String name) =>
      _t('Забыть «$name»?', 'Forget "$name"?');
  String get forgetDeviceBody => _t(
      'Устройство отключится и пропадёт из списка «Мои устройства».',
      'The device will disconnect and disappear from "My devices".');
  String get forget => _t('Забыть', 'Forget');

  // ───────────────────────────── экран управления ───────────────────────

  String get controlLedStrip => _t('Управление лентой', 'Strip control');
  String get brightness => _t('Яркость', 'Brightness');
  String get on => _t('Включено', 'On');
  String get off => _t('Выключено', 'Off');
  String get colorMode => _t('Цвет', 'Color');
  String get whiteMode => _t('Белый', 'White');
  String get effectsMode => _t('Эффекты', 'Effects');
  String get whiteLight => _t('Белый свет', 'White light');
  String get cold => _t('Холодный', 'Cool');
  String get warm => _t('Тёплый', 'Warm');
  String get syncOnTooltip => _t(
      'Синхронизация включена: команды идут на все подключённые устройства',
      'Sync is on: commands go to every connected device');
  String get syncOffTooltip => _t(
      'Включить синхронизацию с остальными подключёнными устройствами',
      'Turn on sync with the other connected devices');

  // ────────────────────────────────── пресеты ────────────────────────────

  String get presets => _t('Пресеты', 'Presets');
  String get copyPresetsTooltip =>
      _t('Скопировать пресеты в буфер обмена', 'Copy presets to clipboard');
  String get pastePresetsTooltip => _t(
      'Импортировать пресеты из буфера обмена', 'Import presets from clipboard');
  String presetDefaultName(int n) => _t('Пресет $n', 'Preset $n');
  String get newPresetTitle => _t('Новый пресет', 'New preset');
  String deletePresetTitle(String name) =>
      _t('Удалить «$name»?', 'Delete "$name"?');
  String get presetsCopied =>
      _t('Пресеты скопированы в буфер обмена', 'Presets copied to clipboard');
  String get clipboardEmpty =>
      _t('В буфере обмена нет данных', 'Clipboard is empty');
  String presetsAdded(int n) => _t('Добавлено пресетов: $n', 'Presets added: $n');
  String get presetsParseFailed => _t('Не удалось распознать пресеты в буфере обмена',
      'Could not read presets from the clipboard');
  String get presetsEmptyHint => _t(
      'Настройте цвет или эффект и нажмите «Сохранить»',
      'Set a color or effect and tap "Save"');

  // ───────────────────────────────── таймер сна ──────────────────────────

  String get sleepTimer => _t('Таймер сна', 'Sleep timer');
  String get turnsOffIn => _t('Выключится через', 'Turns off in');
  String get cancelSleep => _t('Отменить', 'Cancel');
  String get sleep15min => _t('15 мин', '15 min');
  String get sleep30min => _t('30 мин', '30 min');
  String get sleep1h => _t('1 час', '1 h');
  String get sleep2h => _t('2 часа', '2 h');
  String sleepRemainingLong(int hours, String minutes) =>
      _t('$hours ч $minutes мин', '${hours}h ${minutes}m');

  // ──────────────────────────────── расписание ───────────────────────────

  String get scheduleTitle => _t('Расписание', 'Schedule');
  String get onOffSection => _t('Включение / выключение', 'On / off');
  String get noSchedules => _t('Нет расписаний', 'No schedules');
  String get addAutoOnOffHint => _t(
      'Добавьте автоматическое включение\nили выключение по времени',
      'Add an automatic on or off\nby time');
  String get sunriseSection => _t('Будильник-рассвет', 'Sunrise alarm');
  String get noAlarms => _t('Нет будильников', 'No alarms');
  String get sunriseEmptyHint => _t(
      'Лента плавно наберёт яркость к нужному времени вместо резкого включения',
      'The strip will ramp up brightness gently by the target time instead '
          'of switching on abruptly');
  String get triggerTimeHelp => _t('Время срабатывания', 'Trigger time');
  String get whatToDo => _t('Что сделать?', 'What should happen?');
  String get turnOff => _t('Выключить', 'Turn off');
  String get turnOn => _t('Включить', 'Turn on');
  String get sunriseEndHelp =>
      _t('Время окончания рассвета', 'Sunrise end time');
  String get add => _t('Добавить', 'Add');
  String sunriseDialogTitle(String time) =>
      _t('Рассвет к $time', 'Sunrise by $time');
  String durationMinutesLabel(int n) =>
      _t('Длительность: $n мин', 'Duration: $n min');
  String targetBrightnessLabel(int n) =>
      _t('Целевая яркость: $n%', 'Target brightness: $n%');
  String get turnOnLower => _t('включить', 'on');
  String get turnOffLower => _t('выключить', 'off');
  String sunriseRampLabel(int minutes, int percent) =>
      _t('за $minutes мин → $percent%', 'over $minutes min → $percent%');

  static const List<String> _dayLabelsRu = [
    'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс', //
  ];
  static const List<String> _dayLabelsEn = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun', //
  ];
  List<String> get dayLabels =>
      locale == AppLocale.ru ? _dayLabelsRu : _dayLabelsEn;

  // ──────────────────────────────────── сцены ─────────────────────────────

  String get scenesTitle => _t('Сцены', 'Scenes');
  String sceneDefaultName(int n) => _t('Сцена $n', 'Scene $n');
  String get newSceneTitle => _t('Новая сцена', 'New scene');
  String willSaveSceneState(int count, String devicesList) => _t(
      'Сохранит текущее состояние $count ${_deviceWordRu(count)}: $devicesList',
      'Will save the current state of $count ${_deviceWordEn(count)}: '
          '$devicesList');
  String deleteSceneTitle(String name) =>
      _t('Удалить «$name»?', 'Delete "$name"?');
  String sceneApplied(String name) =>
      _t('Сцена «$name» применена', 'Scene "$name" applied');
  String get saveCurrent => _t('Сохранить текущее', 'Save current');
  String get noScenesYet => _t('Сцен пока нет', 'No scenes yet');
  String get noScenesHint => _t(
      'Настройте цвета на нескольких подключённых лентах и нажмите '
          '«Сохранить текущее» — сцена запомнит их все и применит одним '
          'нажатием.',
      'Set colors on several connected strips and tap "Save current" — the '
          'scene will remember all of them and apply with one tap.');

  String _deviceWordRu(int n) {
    final mod10 = n % 10, mod100 = n % 100;
    return mod10 == 1 && mod100 != 11 ? 'устройства' : 'устройств';
  }

  String _deviceWordEn(int n) => n == 1 ? 'device' : 'devices';

  // ───────────────────────────────── эффекты ──────────────────────────────

  static const Map<String, String> _effectNamesEn = {
    'Плавный красный': 'Fade red',
    'Плавный зелёный': 'Fade green',
    'Плавный синий': 'Fade blue',
    'Плавный жёлтый': 'Fade yellow',
    'Плавный голубой': 'Fade cyan',
    'Плавный пурпурный': 'Fade magenta',
    'Плавный белый': 'Fade white',
    'Плавная радуга': 'Fade rainbow',
    'Смена: красный-зелёный': 'Jump red-green',
    'Смена: красный-синий': 'Jump red-blue',
    'Смена: зелёный-синий': 'Jump green-blue',
    'Смена: 7 цветов': 'Jump 7 colors',
    'Плавная смена RGB': 'Fade RGB',
    'Плавная смена RGBW': 'Fade RGBW',
    'Плавная смена 7 цветов': 'Fade 7 colors',
    'Мигание красным': 'Strobe red',
    'Мигание зелёным': 'Strobe green',
    'Мигание синим': 'Strobe blue',
    'Мигание жёлтым': 'Strobe yellow',
    'Мигание голубым': 'Strobe cyan',
    'Мигание пурпурным': 'Strobe magenta',
    'Мигание белым': 'Strobe white',
    'Мигание 7 цветами': 'Strobe 7 colors',
  };

  /// [canonicalName] — русское имя из `kEffectCatalog` (каталог хранит его
  /// как стабильный ключ независимо от текущего языка интерфейса).
  String effectName(String canonicalName) => locale == AppLocale.ru
      ? canonicalName
      : (_effectNamesEn[canonicalName] ?? canonicalName);
}
