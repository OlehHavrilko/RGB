import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../state/device_controller.dart';
import '../../state/led_preset.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/pressable.dart';
import '../widgets/section_header.dart';

/// Секция «Пресеты»: лента чипов с сохранёнными режимами.
/// Тап — применить, долгое нажатие — удалить (с подтверждением).
class PresetsSection extends StatelessWidget {
  const PresetsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<DeviceController>();
    final presets = ctrl.presets;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          'Пресеты',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (presets.isNotEmpty) ...[
                _IconGhostButton(
                  icon: Icons.ios_share_rounded,
                  tooltip: 'Скопировать пресеты в буфер обмена',
                  onTap: () => _exportToClipboard(context, ctrl),
                ),
                const SizedBox(width: 6),
              ],
              _IconGhostButton(
                icon: Icons.content_paste_go_rounded,
                tooltip: 'Импортировать пресеты из буфера обмена',
                onTap: () => _importFromClipboard(context, ctrl),
              ),
              const SizedBox(width: 6),
              Pressable(
                onTap: () => _saveDialog(context, ctrl),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.glass,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.hairline),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded,
                          size: 16, color: AppColors.textPrimary),
                      SizedBox(width: 4),
                      Text(
                        'Сохранить',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: presets.isEmpty
              ? const _EmptyHint()
              : SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: presets.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (_, i) => _PresetChip(
                      preset: presets[i],
                      onApply: () => ctrl.applyPreset(presets[i]),
                      onDelete: () => _confirmDelete(context, ctrl, presets[i]),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _saveDialog(BuildContext context, DeviceController ctrl) async {
    final controller = TextEditingController(
      text: 'Пресет ${ctrl.presets.length + 1}',
    );
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgElevated,
        title: const Text('Новый пресет'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 24,
          decoration: const InputDecoration(hintText: 'Название'),
          onSubmitted: (v) => Navigator.of(context).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name != null && name.trim().isNotEmpty) {
      await ctrl.saveCurrentAsPreset(name);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    DeviceController ctrl,
    LedPreset preset,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgElevated,
        title: Text('Удалить «${preset.name}»?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (ok ?? false) await ctrl.deletePreset(preset.id);
  }

  Future<void> _exportToClipboard(
    BuildContext context,
    DeviceController ctrl,
  ) async {
    await Clipboard.setData(ClipboardData(text: ctrl.exportPresetsJson()));
    if (!context.mounted) return;
    _showSnack(context, 'Пресеты скопированы в буфер обмена');
  }

  Future<void> _importFromClipboard(
    BuildContext context,
    DeviceController ctrl,
  ) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.isEmpty) {
      if (!context.mounted) return;
      _showSnack(context, 'В буфере обмена нет данных');
      return;
    }
    final added = await ctrl.importPresetsJson(text);
    if (!context.mounted) return;
    _showSnack(
      context,
      added > 0
          ? 'Добавлено пресетов: $added'
          : 'Не удалось распознать пресеты в буфере обмена',
    );
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

/// Маленькая кнопка-иконка без фона для действий в шапке секции.
class _IconGhostButton extends StatelessWidget {
  const _IconGhostButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Pressable(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.glass,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.hairline),
          ),
          child: Icon(icon, size: 16, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.preset,
    required this.onApply,
    required this.onDelete,
  });

  final LedPreset preset;
  final VoidCallback onApply;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final swatch = preset.state.displayColor;
    return Pressable(
      onTap: onApply,
      onLongPress: onDelete,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.glassStrong,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.hairline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: swatch,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: swatch.withValues(alpha: 0.6),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              preset.name,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.bookmark_border_rounded,
            size: 18, color: AppColors.textFaint),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Настройте цвет или эффект и нажмите «Сохранить»',
            style: TextStyle(color: AppColors.textFaint, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
