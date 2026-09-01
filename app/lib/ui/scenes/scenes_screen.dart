import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/devices_manager.dart';
import '../../state/scene.dart';
import '../theme/app_colors.dart';
import '../widgets/ambient_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/pressable.dart';

/// Экран сцен: именованные снимки состояний нескольких устройств сразу —
/// на разных лентах могут быть разные цвета/режимы, применяются одним
/// нажатием.
class ScenesScreen extends StatelessWidget {
  const ScenesScreen({super.key});

  Future<void> _saveDialog(BuildContext context, DevicesManager manager) async {
    final connected = manager.connectedSessions;
    final controller = TextEditingController(
      text: 'Сцена ${manager.scenes.length + 1}',
    );
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgElevated,
        title: const Text('Новая сцена'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              maxLength: 24,
              decoration: const InputDecoration(hintText: 'Название'),
              onSubmitted: (v) => Navigator.of(context).pop(v),
            ),
            Text(
              'Сохранит текущее состояние ${connected.length} '
              '${_deviceWord(connected.length)}: '
              '${connected.map((c) => c.name).join(', ')}',
              style: const TextStyle(color: AppColors.textFaint, fontSize: 12),
            ),
          ],
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
      await manager.saveScene(name, connected.map((c) => c.id));
    }
  }

  String _deviceWord(int n) {
    final mod10 = n % 10, mod100 = n % 100;
    return mod10 == 1 && mod100 != 11 ? 'устройства' : 'устройств';
  }

  Future<void> _confirmDelete(
    BuildContext context,
    DevicesManager manager,
    Scene scene,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgElevated,
        title: Text('Удалить «${scene.name}»?'),
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
    if (ok ?? false) await manager.deleteScene(scene.id);
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<DevicesManager>();
    final scenes = manager.scenes;
    final canSave = manager.connectedSessions.isNotEmpty;

    return Scaffold(
      body: AmbientBackground(
        glow: AppColors.accent,
        intensity: 0.5,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 20, 8),
                child: Row(
                  children: [
                    Pressable(
                      onTap: () => Navigator.of(context).maybePop(),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.glass,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.hairline),
                        ),
                        child: const Icon(Icons.chevron_left_rounded,
                            color: AppColors.textPrimary),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text('Сцены',
                          style: Theme.of(context).textTheme.headlineSmall),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: scenes.isEmpty
                    ? const _EmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                        itemCount: scenes.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, i) => _SceneTile(
                          scene: scenes[i],
                          onApply: () {
                            manager.applyScene(scenes[i].id);
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(SnackBar(
                                content:
                                    Text('Сцена «${scenes[i].name}» применена'),
                              ));
                          },
                          onDelete: () =>
                              _confirmDelete(context, manager, scenes[i]),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Pressable(
        onTap: canSave ? () => _saveDialog(context, manager) : null,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: canSave
                ? const LinearGradient(colors: AppColors.scanPulse)
                : null,
            color: canSave ? null : AppColors.glassStrong,
            border: canSave
                ? null
                : Border.all(color: AppColors.hairline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded,
                  color: canSave ? Colors.white : AppColors.textFaint,
                  size: 20),
              const SizedBox(width: 8),
              Text(
                'Сохранить текущее',
                style: TextStyle(
                  color: canSave ? Colors.white : AppColors.textFaint,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SceneTile extends StatelessWidget {
  const _SceneTile({
    required this.scene,
    required this.onApply,
    required this.onDelete,
  });

  final Scene scene;
  final VoidCallback onApply;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onApply,
      onLongPress: onDelete,
      borderRadius: BorderRadius.circular(24),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: Stack(
                children: [
                  for (var i = 0; i < scene.entries.length && i < 3; i++)
                    Positioned(
                      left: i * 10.0,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: scene.entries[i].state.power
                              ? scene.entries[i].state.displayColor
                              : AppColors.glassStrong,
                          border:
                              Border.all(color: AppColors.bg, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scene.name,
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    scene.entries.map((e) => e.deviceName).join(', '),
                    style: const TextStyle(
                      color: AppColors.textFaint,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.play_circle_outline_rounded,
                color: AppColors.textFaint),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome_rounded,
                size: 48, color: AppColors.textFaint),
            const SizedBox(height: 20),
            Text('Сцен пока нет', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text(
              'Настройте цвета на нескольких подключённых лентах и нажмите '
              '«Сохранить текущее» — сцена запомнит их все и применит одним '
              'нажатием.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textFaint, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
