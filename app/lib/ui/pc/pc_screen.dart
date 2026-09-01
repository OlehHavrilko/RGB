import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../state/openrgb_controller.dart';
import '../control/color_wheel.dart';
import '../theme/app_colors.dart';
import '../widgets/ambient_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/pressable.dart';

/// Экран «ПК» — клиент OpenRGB SDK для управления ARGB-подсветкой
/// компьютера (Фаза 2 роадмапа). Экспериментально: см. предупреждение в
/// `OpenRgbClient` про отсутствие проверки на реальном сервере.
class PcScreen extends StatefulWidget {
  const PcScreen({super.key});

  @override
  State<PcScreen> createState() => _PcScreenState();
}

class _PcScreenState extends State<PcScreen> {
  late final TextEditingController _host;
  late final TextEditingController _port;
  late final TextEditingController _deviceIndex;
  late final TextEditingController _ledCount;
  Color _color = const Color(0xFF2F7BFF);

  @override
  void initState() {
    super.initState();
    final ctrl = context.read<OpenRgbController>();
    _host = TextEditingController(text: ctrl.lastHost);
    _port = TextEditingController(text: ctrl.lastPort.toString());
    _deviceIndex = TextEditingController(text: '0');
    _ledCount = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _host.dispose();
    _port.dispose();
    _deviceIndex.dispose();
    _ledCount.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final port = int.tryParse(_port.text) ?? 6742;
    await context.read<OpenRgbController>().connect(_host.text.trim(), port);
  }

  void _apply() {
    final ctrl = context.read<OpenRgbController>();
    final deviceIndex = int.tryParse(_deviceIndex.text) ?? 0;
    final ledCount = int.tryParse(_ledCount.text) ?? 1;
    ctrl.applyColor(deviceIndex, ledCount, _color);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(AppStrings.of(context).pcColorSent)));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final ctrl = context.watch<OpenRgbController>();

    return Scaffold(
      body: AmbientBackground(
        glow: _color,
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
                      child: Text(s.pcTitle,
                          style: Theme.of(context).textTheme.headlineSmall),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                  children: [
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        s.pcExperimentalNotice,
                        style: const TextStyle(
                            color: AppColors.textFaint, fontSize: 12, height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: _Field(
                                  label: s.pcHost,
                                  controller: _host,
                                  enabled: !ctrl.isConnected,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _Field(
                                  label: s.pcPort,
                                  controller: _port,
                                  enabled: !ctrl.isConnected,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _ConnectButton(
                            state: ctrl.state,
                            onTap: ctrl.isConnected
                                ? () => ctrl.disconnect()
                                : (ctrl.state == OpenRgbConnectionState.connecting
                                    ? null
                                    : () => _connect()),
                          ),
                          if (ctrl.state == OpenRgbConnectionState.connected) ...[
                            const SizedBox(height: 10),
                            Text(
                              s.pcConnected(ctrl.controllerCount),
                              style: const TextStyle(
                                  color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ],
                          if (ctrl.state == OpenRgbConnectionState.failed) ...[
                            const SizedBox(height: 10),
                            Text(
                              s.pcConnectFailed(ctrl.error ?? ''),
                              style: const TextStyle(
                                  color: AppColors.danger, fontSize: 13),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (ctrl.isConnected) ...[
                      const SizedBox(height: 16),
                      GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _Field(
                                    label: s.pcDeviceIndex,
                                    controller: _deviceIndex,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _Field(
                                    label: s.pcLedCount,
                                    controller: _ledCount,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Center(
                              child: ColorWheel(
                                color: _color,
                                onChanged: (c) => setState(() => _color = c),
                                size: 220,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _ApplyButton(color: _color, label: s.pcApply, onTap: _apply),
                          ],
                        ),
                      ),
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
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.enabled = true,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final bool enabled;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textFaint),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.hairline),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _ConnectButton extends StatelessWidget {
  const _ConnectButton({required this.state, required this.onTap});

  final OpenRgbConnectionState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final connected = state == OpenRgbConnectionState.connected;
    final label = connected
        ? s.pcDisconnect
        : (state == OpenRgbConnectionState.connecting ? s.pcConnecting : s.pcConnect);
    return Pressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: connected
              ? null
              : const LinearGradient(colors: AppColors.scanPulse),
          color: connected ? AppColors.glassStrong : null,
          border: connected ? Border.all(color: AppColors.hairline) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: connected ? AppColors.textPrimary : Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _ApplyButton extends StatelessWidget {
  const _ApplyButton({
    required this.color,
    required this.label,
    required this.onTap,
  });

  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
