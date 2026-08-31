import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../state/device_controller.dart';
import '../../state/led_state.dart';
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
import 'mode_switcher.dart';
import 'power_orb.dart';
import 'rgb_sliders.dart';
import 'white_tab.dart';

class ControlScreen extends StatelessWidget {
  const ControlScreen({super.key});

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
                      _TopBar(deviceName: ctrl.device?.displayName ?? 'Контроллер'),
                      const SizedBox(height: 12),
                      ConnectionBanner(
                        state: ctrl.linkState,
                        deviceName: ctrl.device?.id ?? '',
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
                        onToggle: ctrl.togglePower,
                      ),
                      const SizedBox(height: 28),
                      ModeSwitcher(
                        mode: led.mode,
                        onChanged: ctrl.setMode,
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
                      const SectionHeader('Яркость'),
                      GlassCard(
                        child: BrightnessSlider(
                          value: led.brightness,
                          tint: led.displayColor,
                          onChanged: (v) => ctrl.setBrightness(v),
                          onChangeEnd: (v) =>
                              ctrl.setBrightness(v, commit: true),
                        ),
                      ),
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
  const _TopBar({required this.deviceName});

  final String deviceName;

  @override
  Widget build(BuildContext context) {
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
                deviceName,
                style: Theme.of(context).textTheme.headlineSmall,
                overflow: TextOverflow.ellipsis,
              ),
              const Text(
                'Управление лентой',
                style: TextStyle(
                    color: AppColors.textFaint,
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
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
          child: Text(on ? 'Включено' : 'Выключено'),
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
            const SectionHeader('Белый свет'),
            GlassCard(
              child: WhiteTab(
                warm: led.warm,
                onChanged: (v) => ctrl.setWhite(v),
                onChangeEnd: (v) => ctrl.setWhite(v, commit: true),
              ),
            ),
          ],
        );
      case LedMode.effect:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionHeader('Эффекты'),
            GlassCard(
              child: EffectsSection(
                selectedId: led.effectId,
                speed: led.effectSpeed,
                onSelect: ctrl.selectEffect,
                onSpeed: (v) => ctrl.setEffectSpeed(v),
                onSpeedEnd: (v) => ctrl.setEffectSpeed(v, commit: true),
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
        const SectionHeader('Цвет'),
        GlassCard(
          child: Column(
            children: [
              Center(
                child: ColorWheel(
                  color: led.color,
                  size: 250,
                  onChanged: (c) => ctrl.setColor(c),
                  onChangeEnd: (c) => ctrl.setColor(c, commit: true),
                ),
              ),
              const SizedBox(height: 22),
              RgbSliders(
                color: led.color,
                onChanged: (c) => ctrl.setColor(c),
                onChangeEnd: (c) => ctrl.setColor(c, commit: true),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final c in ControlScreen._quickColors)
                    Pressable(
                      onTap: () => ctrl.setColor(c, commit: true),
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
