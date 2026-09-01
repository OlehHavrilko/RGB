import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/daily_schedule.dart';
import '../../state/schedule_controller.dart';
import '../theme/app_colors.dart';
import '../widgets/ambient_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/pressable.dart';

const _dayLabels = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

/// Экран ежедневных расписаний включения/выключения ленты.
class SchedulesScreen extends StatelessWidget {
  const SchedulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sched = context.watch<ScheduleController>();
    final items = sched.schedules;

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
                    Text(
                      'Расписание',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? const _Empty()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => _ScheduleTile(item: items[i]),
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addDialog(context, sched),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Добавить'),
      ),
    );
  }

  Future<void> _addDialog(
      BuildContext context, ScheduleController sched) async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: now,
      helpText: 'Время срабатывания',
    );
    if (picked == null || !context.mounted) return;
    final turnOn = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgElevated,
        title: const Text('Что сделать?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Выключить'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Включить'),
          ),
        ],
      ),
    );
    if (turnOn == null) return;
    await sched.addSchedule(
      minuteOfDay: picked.hour * 60 + picked.minute,
      turnOn: turnOn,
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  const _ScheduleTile({required this.item});

  final DailySchedule item;

  @override
  Widget build(BuildContext context) {
    final sched = context.read<ScheduleController>();
    final dim = !item.enabled;

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Opacity(
                opacity: dim ? 0.4 : 1,
                child: Row(
                  children: [
                    Icon(
                      item.turnOn
                          ? Icons.wb_incandescent_rounded
                          : Icons.power_settings_new_rounded,
                      size: 20,
                      color: item.turnOn
                          ? AppColors.accentSoft
                          : AppColors.textFaint,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      item.timeLabel,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      item.turnOn ? 'включить' : 'выключить',
                      style: const TextStyle(
                        color: AppColors.textFaint,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Switch(
                value: item.enabled,
                activeThumbColor: AppColors.accent,
                onChanged: (_) => sched.toggleSchedule(item.id),
              ),
              Pressable(
                onTap: () => sched.deleteSchedule(item.id),
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.delete_outline_rounded,
                      size: 20, color: AppColors.textFaint),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Opacity(
            opacity: dim ? 0.4 : 1,
            child: Wrap(
              spacing: 8,
              children: [
                for (var d = 1; d <= 7; d++)
                  _DayToggle(
                    label: _dayLabels[d - 1],
                    active: item.days.contains(d),
                    onTap: () {
                      final next = {...item.days};
                      if (!next.remove(d)) next.add(d);
                      if (next.isEmpty) return;
                      sched.updateSchedule(item.copyWith(days: next));
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DayToggle extends StatelessWidget {
  const _DayToggle({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 34,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.accent.withValues(alpha: 0.22) : null,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? AppColors.accent : AppColors.hairline,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? AppColors.textPrimary : AppColors.textFaint,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.schedule_rounded,
              size: 56, color: AppColors.textFaint),
          const SizedBox(height: 16),
          Text('Нет расписаний',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          const Text(
            'Добавьте автоматическое включение\nили выключение по времени',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textFaint, height: 1.5),
          ),
        ],
      ),
    );
  }
}
