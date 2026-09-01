import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../state/device_controller.dart';
import '../../state/devices_manager.dart';
import '../../state/led_state.dart';
import '../../state/schedule_controller.dart';
import '../theme/app_colors.dart';
import '../theme/motion.dart';
import '../widgets/ambient_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/pressable.dart';
import '../widgets/section_header.dart';
import 'brightness_slider.dart';
import 'color_wheel.dart';
import 'connection_banner.dart';
import 'effects_section.dart';
import '../schedules/schedules_screen.dart';
import '../widgets/app_page_transition.dart';
import 'mode_switcher.dart';
import 'power_orb.dart';
import 'presets_section.dart';
import 'rgb_sliders.dart';
import 'sleep_timer_section.dart';
import 'white_tab.dart';

/// Экран управления конкретным устройством, найденным по [deviceId].
///
/// Оборачивает поддерево в провайдеры конкретных [DeviceController] и
/// [ScheduleController] из [DevicesManager] — все дочерние секции
/// (пресеты, таймер сна, расписания) продолжают читать их через обычный
/// `context.watch`, не зная о многодевайсности.
class ControlScreen extends StatelessWidget {
  const ControlScreen({super.key, required this.deviceId});

  final String deviceId;

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<DevicesManager>();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<DeviceController>.value(
          value: manager.controllerFor(deviceId),
        ),
        ChangeNotifierProvider<ScheduleController>.value(
          value: manager.scheduleFor(deviceId),
        ),
      ],
      child: const _ControlScreenBody(),
    );
  }
}

/// Применяет [action] к [ctrl] и, если включён режим синхронизации
/// ([DevicesManager.syncEnabled]), зеркалит его на все остальные
/// подключённые устройства.
void _apply(
  BuildContext context,
  DeviceController ctrl,
  void Function(DeviceController target) action,
) {
  action(ctrl);
  context.read<DevicesManager>().broadcastFrom(ctrl, action);
}

class _ControlScreenBody extends StatelessWidget {
  const _ControlScreenBody();

  static const _quickColors = [
    Color(0xFFFF3B30),
    Color(0xFFFF9F0A),
    Color(0xFFFFD60A),
    Color(0xFF30D158),
    Color(0xFF32ADE6),
    Color(0xFF5E5CE6),
    Color(0xFFBF5AF2),
    Color(0xFFFF375F),
    Color(0xFFFFFFFF),
  ];

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<DeviceController>();
    final led = ctrl.led;
    final glow = led.power ? led.displayColor : AppColors.bgElevated;

    return Scaffold(
      body: AmbientBackground(
        glow: glow,
        intensity: led.power ? 1 : 0.25,
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Column(
                    children: [
                      _TopBar(ctrl: ctrl),
                      const SizedBox(height: 12),
                      ConnectionBanner(
                        state: ctrl.linkState,
                        deviceName: ctrl.id,
                        onReconnect: ctrl.reconnect,
                        onDisconnect: () {
                          ctrl.disconnect();
                          Navigator.of(context).maybePop();
                        },
                      ),
                      const SizedBox(height: 28),
                      _PowerArea(
                        on: led.power,
                        glow: led.displayColor,
                        onToggle: () =>
                            _apply(context, ctrl, (c) => c.togglePower()),
                      ),
                      const SizedBox(height: 28),
                      ModeSwitcher(
                        mode: led.mode,
                        onChanged: (m) =>
                            _apply(context, ctrl, (c) => c.setMode(m)),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: AnimatedSize(
                    duration: Motion.base,
                    curve: Motion.standard,
                    alignment: Alignment.topCenter,
                    child: AnimatedSwitcher(
                      duration: Motion.base,
                      switchInCurve: Motion.standard,
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SizeTransition(
                          sizeFactor: anim,
                          child: child,
                        ),
                      ),
                      child: _ModePanel(
                        key: ValueKey(led.mode),
                        ctrl: ctrl,
                        led: led,
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const PresetsSection(),
                      const SizedBox(height: 20),
                      SectionHeader(AppStrings.of(context).brightness),
                      GlassCard(
                        child: BrightnessSlider(
                          value: led.brightness,
                          tint: led.displayColor,
                          onChanged: (v) =>
                              _apply(context, ctrl, (c) => c.setBrightness(v)),
                          onChangeEnd: (v) => _apply(context, ctrl,
                              (c) => c.setBrightness(v, commit: true)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const SleepTimerSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.ctrl});

  final DeviceController ctrl;

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<DevicesManager>();
    final otherConnected =
        manager.connectedSessions.where((s) => s.id != ctrl.id).length;

    return Row(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ctrl.name,
                style: Theme.of(context).textTheme.headlineSmall,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                AppStrings.of(context).controlLedStrip,
                style: const TextStyle(
                    color: AppColors.textFaint,
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        if (otherConnected > 0)
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: _SyncToggle(
              enabled: manager.syncEnabled,
              otherConnected: otherConnected,
              onTap: () => manager.setSyncEnabled(!manager.syncEnabled),
            ),
          ),
        Pressable(
          onTap: () => Navigator.of(context).push(
            FadeThroughPageRoute<void>(page: const SchedulesScreen()),
          ),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.glass,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.hairline),
            ),
            child: const Icon(Icons.schedule_rounded,
                color: AppColors.textPrimary, size: 20),
          ),
        ),
      ],
    );
  }
}

/// Переключатель режима синхронизации: пока активен, изменения на этом
/// устройстве (цвет/эффект/яркость/питание) зеркалятся на все остальные
/// подключённые ленты.
class _SyncToggle extends StatelessWidget {
  const _SyncToggle({
    required this.enabled,
    required this.otherConnected,
    required this.onTap,
  });

  final bool enabled;
  final int otherConnected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Tooltip(
      message: enabled ? s.syncOnTooltip : s.syncOffTooltip,
      child: Pressable(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: Motion.base,
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: enabled
                ? AppColors.accent.withValues(alpha: 0.22)
                : AppColors.glass,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: enabled
                  ? AppColors.accent.withValues(alpha: 0.6)
                  : AppColors.hairline,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                enabled ? Icons.sync_rounded : Icons.sync_disabled_rounded,
                size: 18,
                color:
                    enabled ? AppColors.accent : AppColors.textFaint,
              ),
              if (enabled) ...[
                const SizedBox(width: 6),
                Text(
                  '+$otherConnected',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PowerArea extends StatelessWidget {
  const _PowerArea({
    required this.on,
    required this.glow,
    required this.onToggle,
  });

  final bool on;
  final Color glow;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PowerOrb(on: on, glow: glow, onTap: onToggle),
        const SizedBox(height: 14),
        AnimatedDefaultTextStyle(
          duration: Motion.base,
          style: TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: on ? AppColors.textPrimary : AppColors.textFaint,
          ),
          child: Text(on ? AppStrings.of(context).on : AppStrings.of(context).off),
        ),
      ],
    );
  }
}

class _ModePanel extends StatelessWidget {
  const _ModePanel({super.key, required this.ctrl, required this.led});

  final DeviceController ctrl;
  final LedState led;

  @override
  Widget build(BuildContext context) {
    switch (led.mode) {
      case LedMode.color:
        return _ColorPanel(ctrl: ctrl, led: led);
      case LedMode.white:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(AppStrings.of(context).whiteLight),
            GlassCard(
              child: WhiteTab(
                warm: led.warm,
                onChanged: (v) =>
                    _apply(context, ctrl, (c) => c.setWhite(v)),
                onChangeEnd: (v) => _apply(
                    context, ctrl, (c) => c.setWhite(v, commit: true)),
              ),
            ),
          ],
        );
      case LedMode.effect:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(AppStrings.of(context).effectsMode),
            GlassCard(
              child: EffectsSection(
                selectedId: led.effectId,
                speed: led.effectSpeed,
                onSelect: (id) =>
                    _apply(context, ctrl, (c) => c.selectEffect(id)),
                onSpeed: (v) =>
                    _apply(context, ctrl, (c) => c.setEffectSpeed(v)),
                onSpeedEnd: (v) => _apply(
                    context, ctrl, (c) => c.setEffectSpeed(v, commit: true)),
              ),
            ),
          ],
        );
    }
  }
}

class _ColorPanel extends StatelessWidget {
  const _ColorPanel({required this.ctrl, required this.led});

  final DeviceController ctrl;
  final LedState led;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(AppStrings.of(context).colorMode),
        GlassCard(
          child: Column(
            children: [
              Center(
                child: ColorWheel(
                  color: led.color,
                  size: 250,
                  onChanged: (color) =>
                      _apply(context, ctrl, (c) => c.setColor(color)),
                  onChangeEnd: (color) => _apply(
                      context, ctrl, (c) => c.setColor(color, commit: true)),
                ),
              ),
              const SizedBox(height: 22),
              RgbSliders(
                color: led.color,
                onChanged: (color) =>
                    _apply(context, ctrl, (c) => c.setColor(color)),
                onChangeEnd: (color) => _apply(
                    context, ctrl, (c) => c.setColor(color, commit: true)),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final c in _ControlScreenBody._quickColors)
                    Pressable(
                      onTap: () => _apply(
                          context, ctrl, (t) => t.setColor(c, commit: true)),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _isSelected(led.color, c)
                                ? Colors.white
                                : AppColors.hairline,
                            width: _isSelected(led.color, c) ? 3 : 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: Motion.base);
  }

  bool _isSelected(Color a, Color b) =>
      (a.r - b.r).abs() < 0.02 &&
      (a.g - b.g).abs() < 0.02 &&
      (a.b - b.b).abs() < 0.02;
}
