/// Каталог встроенных эффектов ELK-BLEDOM.
///
/// Идентификатор [id] уходит в команду `7E 00 03 <id> 03 00 00 00 EF`.
/// [previewColors] — набор ARGB-значений для градиента-превью в интерфейсе
/// (0xFFRRGGBB), логика контроллера от них не зависит.
class LedEffect {
  const LedEffect({
    required this.id,
    required this.name,
    required this.previewColors,
  });

  final int id;
  final String name;
  final List<int> previewColors;
}

const int _red = 0xFFFF1F1F;
const int _green = 0xFF29E05B;
const int _blue = 0xFF2F7BFF;
const int _yellow = 0xFFFFD23F;
const int _cyan = 0xFF23E0D4;
const int _magenta = 0xFFE039C6;
const int _white = 0xFFF2F2F2;

const List<int> _rainbow = [
  _red,
  _yellow,
  _green,
  _cyan,
  _blue,
  _magenta,
  _red,
];

/// Порядок и подписи соответствуют прошивке большинства ELK-BLEDOM.
const List<LedEffect> kEffectCatalog = [
  LedEffect(id: 0x80, name: 'Плавный красный', previewColors: [0xFF3A0000, _red]),
  LedEffect(id: 0x81, name: 'Плавный зелёный', previewColors: [0xFF003A12, _green]),
  LedEffect(id: 0x82, name: 'Плавный синий', previewColors: [0xFF001B3A, _blue]),
  LedEffect(id: 0x83, name: 'Плавный жёлтый', previewColors: [0xFF3A2E00, _yellow]),
  LedEffect(id: 0x84, name: 'Плавный голубой', previewColors: [0xFF003A36, _cyan]),
  LedEffect(id: 0x85, name: 'Плавный пурпурный', previewColors: [0xFF2E0029, _magenta]),
  LedEffect(id: 0x86, name: 'Плавный белый', previewColors: [0xFF2A2A2A, _white]),
  LedEffect(id: 0x87, name: 'Плавная радуга', previewColors: _rainbow),
  LedEffect(id: 0x88, name: 'Смена: красный-зелёный', previewColors: [_red, _green]),
  LedEffect(id: 0x89, name: 'Смена: красный-синий', previewColors: [_red, _blue]),
  LedEffect(id: 0x8A, name: 'Смена: зелёный-синий', previewColors: [_green, _blue]),
  LedEffect(id: 0x8B, name: 'Смена: 7 цветов', previewColors: _rainbow),
  LedEffect(id: 0x8C, name: 'Плавная смена RGB', previewColors: [_red, _green, _blue]),
  LedEffect(id: 0x8D, name: 'Плавная смена RGBW', previewColors: [_red, _green, _blue, _white]),
  LedEffect(id: 0x8E, name: 'Плавная смена 7 цветов', previewColors: _rainbow),
  LedEffect(id: 0x8F, name: 'Мигание красным', previewColors: [0xFF120000, _red]),
  LedEffect(id: 0x90, name: 'Мигание зелёным', previewColors: [0xFF001206, _green]),
  LedEffect(id: 0x91, name: 'Мигание синим', previewColors: [0xFF000912, _blue]),
  LedEffect(id: 0x92, name: 'Мигание жёлтым', previewColors: [0xFF121000, _yellow]),
  LedEffect(id: 0x93, name: 'Мигание голубым', previewColors: [0xFF001211, _cyan]),
  LedEffect(id: 0x94, name: 'Мигание пурпурным', previewColors: [0xFF0F000D, _magenta]),
  LedEffect(id: 0x95, name: 'Мигание белым', previewColors: [0xFF101010, _white]),
  LedEffect(id: 0x96, name: 'Мигание 7 цветами', previewColors: _rainbow),
];

LedEffect? effectById(int? id) {
  if (id == null) return null;
  for (final e in kEffectCatalog) {
    if (e.id == id) return e;
  }
  return null;
}
