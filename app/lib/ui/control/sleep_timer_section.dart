import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
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

  static const _presetDurations = <Duration>[
    Duration(minutes: 15),
    Duration(minutes: 30),
    Duration(hours: 1),
    Duration(hours: 2),
  ];

  List<(String, Duration)> _presets(AppStrings s) => [
        (s.sleep15min, _presetDurations[0]),
        (s.sleep30min, _presetDurations[1]),
        (s.sleep1h, _presetDurations[2]),
        (s.sleep2h, _presetDurations[3]),
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

  String _fmt(Duration d, AppStrings s) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final sec = d.inSeconds.remainder(60);
    if (h > 0) return s.sleepRemainingLong(h, m.toString().padLeft(2, '0'));
    return '$m:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final sched = context.watch<ScheduleController>();
    final remaining = sched.sleepRemaining;
    final s = AppStrings.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(s.sleepTimer),
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: remaining == null
              ? Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final (label, d) in _presets(s))
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
                          Text(
                            s.turnsOffIn,
                            style: const TextStyle(
                                color: AppColors.textFaint, fontSize: 12),
                          ),
                          Text(
                            _fmt(remaining, s),
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
                        child: Text(
                          s.cancelSleep,
                          style: const TextStyle(
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
