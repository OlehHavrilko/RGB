import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../state/daily_schedule.dart';
import '../../state/schedule_controller.dart';
import '../../state/sunrise_alarm.dart';
import '../theme/app_colors.dart';
import '../widgets/ambient_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/pressable.dart';
import '../widgets/section_header.dart';

/// Экран ежедневных расписаний включения/выключения ленты и
/// будильников-рассветов.
class SchedulesScreen extends StatelessWidget {
  const SchedulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sched = context.watch<ScheduleController>();
    final items = sched.schedules;
    final alarms = sched.sunriseAlarms;
    final s = AppStrings.of(context);

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
                      s.scheduleTitle,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                  children: [
                    SectionHeader(
                      s.onOffSection,
                      trailing: _AddButton(
                        onTap: () => _addDialog(context, sched),
                      ),
                    ),
                    if (items.isEmpty)
                      _Empty(
                        icon: Icons.schedule_rounded,
                        title: s.noSchedules,
                        text: s.addAutoOnOffHint,
                      )
                    else
                      for (final item in items) ...[
                        _ScheduleTile(item: item),
                        const SizedBox(height: 12),
                      ],
                    const SizedBox(height: 24),
                    SectionHeader(
                      s.sunriseSection,
                      trailing: _AddButton(
                        onTap: () => _addSunriseDialog(context, sched),
                      ),
                    ),
                    if (alarms.isEmpty)
                      _Empty(
                        icon: Icons.wb_twilight_rounded,
                        title: s.noAlarms,
                        text: s.sunriseEmptyHint,
                      )
                    else
                      for (final alarm in alarms) ...[
                        _SunriseTile(alarm: alarm),
                        const SizedBox(height: 12),
                      ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addDialog(
      BuildContext context, ScheduleController sched) async {
    final s = AppStrings.of(context);
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: now,
      helpText: s.triggerTimeHelp,
    );
    if (picked == null || !context.mounted) return;
    final turnOn = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgElevated,
        title: Text(s.whatToDo),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(s.turnOff),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(s.turnOn),
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

  Future<void> _addSunriseDialog(
      BuildContext context, ScheduleController sched) async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: now,
      helpText: AppStrings.of(context).sunriseEndHelp,
    );
    if (picked == null || !context.mounted) return;
    final result = await showDialog<({int duration, int brightness})>(
      context: context,
      builder: (context) => _SunriseSettingsDialog(time: picked),
    );
    if (result == null) return;
    await sched.addSunriseAlarm(
      minuteOfDay: picked.hour * 60 + picked.minute,
      durationMinutes: result.duration,
      targetBrightness: result.brightness,
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.glass,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.hairline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, size: 16, color: AppColors.textPrimary),
            const SizedBox(width: 4),
            Text(
              AppStrings.of(context).add,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Диалог настройки будильника-рассвета: длительность и целевая яркость.
class _SunriseSettingsDialog extends StatefulWidget {
  const _SunriseSettingsDialog({required this.time});

  final TimeOfDay time;

  @override
  State<_SunriseSettingsDialog> createState() =>
      _SunriseSettingsDialogState();
}

class _SunriseSettingsDialogState extends State<_SunriseSettingsDialog> {
  int _duration = 15;
  int _brightness = 80;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return AlertDialog(
      backgroundColor: AppColors.bgElevated,
      title: Text(s.sunriseDialogTitle(widget.time.format(context))),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.durationMinutesLabel(_duration),
              style: const TextStyle(color: AppColors.textFaint)),
          Slider(
            value: _duration.toDouble(),
            min: 5,
            max: 60,
            divisions: 11,
            activeColor: AppColors.accent,
            onChanged: (v) => setState(() => _duration = v.round()),
          ),
          Text(s.targetBrightnessLabel(_brightness),
              style: const TextStyle(color: AppColors.textFaint)),
          Slider(
            value: _brightness.toDouble(),
            min: 10,
            max: 100,
            divisions: 18,
            activeColor: AppColors.accent,
            onChanged: (v) => setState(() => _brightness = v.round()),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(s.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            (duration: _duration, brightness: _brightness),
          ),
          child: Text(s.save),
        ),
      ],
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  const _ScheduleTile({required this.item});

  final DailySchedule item;

  @override
  Widget build(BuildContext context) {
    final sched = context.read<ScheduleController>();
    final s = AppStrings.of(context);
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
                      item.turnOn ? s.turnOnLower : s.turnOffLower,
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
                    label: s.dayLabels[d - 1],
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

class _SunriseTile extends StatelessWidget {
  const _SunriseTile({required this.alarm});

  final SunriseAlarm alarm;

  @override
  Widget build(BuildContext context) {
    final sched = context.read<ScheduleController>();
    final s = AppStrings.of(context);
    final dim = !alarm.enabled;

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
                    const Icon(Icons.wb_twilight_rounded,
                        size: 20, color: AppColors.accentSoft),
                    const SizedBox(width: 12),
                    Text(
                      alarm.timeLabel,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      s.sunriseRampLabel(
                          alarm.durationMinutes, alarm.targetBrightness),
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
                value: alarm.enabled,
                activeThumbColor: AppColors.accent,
                onChanged: (_) => sched.toggleSunriseAlarm(alarm.id),
              ),
              Pressable(
                onTap: () => sched.deleteSunriseAlarm(alarm.id),
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
                    label: s.dayLabels[d - 1],
                    active: alarm.days.contains(d),
                    onTap: () {
                      final next = {...alarm.days};
                      if (!next.remove(d)) next.add(d);
                      if (next.isEmpty) return;
                      sched.updateSunriseAlarm(alarm.copyWith(days: next));
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
  const _Empty({required this.icon, required this.title, required this.text});

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppColors.textFaint),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textFaint, height: 1.5),
          ),
        ],
      ),
    );
  }
}
