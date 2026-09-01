import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/schedule_controller.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/pressable.dart';
import '../widgets/section_header.dart';

/// Секция «Таймер сна»: одноразовое автоотключение ленты через заданный срок.
class SleepTimerSection extends StatefulWidget {
  const SleepTimerSection({super.key});

  @override
  State<SleepTimerSection> createState() => _SleepTimerSectionState();
}

class _SleepTimerSectionState extends State<SleepTimerSection> {
  Timer? _ticker;

  static const _presets = <(String, Duration)>[
    ('15 мин', Duration(minutes: 15)),
    ('30 мин', Duration(minutes: 30)),
    ('1 час', Duration(hours: 1)),
    ('2 часа', Duration(hours: 2)),
  ];

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '$h ч ${m.toString().padLeft(2, '0')} мин';
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final sched = context.watch<ScheduleController>();
    final remaining = sched.sleepRemaining;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader('Таймер сна'),
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: remaining == null
              ? Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final (label, d) in _presets)
                      Pressable(
                        onTap: () => sched.startSleep(d),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 9),
                          decoration: BoxDecoration(
                            color: AppColors.glassStrong,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.hairline),
                          ),
                          child: Text(
                            label,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                  ],
                )
              : Row(
                  children: [
                    const Icon(Icons.bedtime_rounded,
                        size: 20, color: AppColors.accentSoft),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Выключится через',
                            style: TextStyle(
                                color: AppColors.textFaint, fontSize: 12),
                          ),
                          Text(
                            _fmt(remaining),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Pressable(
                      onTap: sched.cancelSleep,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: AppColors.danger.withValues(alpha: 0.4)),
                        ),
                        child: const Text(
                          'Отменить',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
