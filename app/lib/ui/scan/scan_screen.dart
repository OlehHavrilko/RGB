import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../ble/ble_connection.dart';
import '../../ble/ble_device.dart';
import '../../ble/ble_service.dart';
import '../../state/device_controller.dart';
import '../../state/devices_manager.dart';
import '../../state/known_device.dart';
import '../../state/scan_controller.dart';
import '../control/control_screen.dart';
import '../theme/app_colors.dart';
import '../theme/motion.dart';
import '../widgets/ambient_background.dart';
import '../widgets/app_page_transition.dart';
import '../widgets/glass_card.dart';
import '../widgets/pressable.dart';
import '../widgets/signal_bars.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScanController>().startScan();
    });
  }

  Future<void> _openControl(String deviceId) async {
    if (!mounted) return;
    await Navigator.of(context).push(
      FadeThroughPageRoute<void>(page: ControlScreen(deviceId: deviceId)),
    );
  }

  Future<void> _connectAndOpen(DiscoveredDevice device) async {
    final scan = context.read<ScanController>();
    unawaited(context.read<DevicesManager>().connect(device));
    await scan.stopScan();
    await _openControl(device.id);
    // Вернулись с экрана управления — возобновляем поиск, иначе список пуст.
    if (mounted) scan.startScan();
  }

  Future<void> _connectKnownAndOpen(String id) async {
    unawaited(context.read<DevicesManager>().connectKnown(id));
    await _openControl(id);
  }

  Future<void> _forget(KnownDevice device) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgElevated,
        title: Text('Забыть «${device.name}»?'),
        content: const Text(
          'Устройство отключится и пропадёт из списка «Мои устройства».',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Забыть'),
          ),
        ],
      ),
    );
    if (ok ?? false) await context.read<DevicesManager>().forget(device.id);
  }

  @override
  Widget build(BuildContext context) {
    final scan = context.watch<ScanController>();
    final manager = context.watch<DevicesManager>();
    final known = manager.knownDevices;
    final knownIds = known.map((d) => d.id).toSet();
    final discovered =
        scan.devices.where((d) => !knownIds.contains(d.id)).toList();

    return Scaffold(
      body: AmbientBackground(
        glow: AppColors.accent,
        intensity: 0.6,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                child: _Header(
                  connectedCount:
                      known.where((d) => manager.controllerFor(d.id).isConnected).length,
                  knownCount: known.length,
                ),
              ),
              if (scan.availability == BleAvailability.poweredOff ||
                  scan.availability == BleAvailability.unauthorized ||
                  scan.error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 4),
                  child: _Notice(
                    text: scan.error ??
                        (scan.availability == BleAvailability.poweredOff
                            ? 'Включите Bluetooth в системе'
                            : 'Нет доступа к Bluetooth'),
                  ),
                ),
              Expanded(
                child: known.isEmpty && discovered.isEmpty
                    ? _EmptyState(scanning: scan.isScanning)
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                        children: [
                          if (known.isNotEmpty) ...[
                            const _SectionLabel('Мои устройства'),
                            const SizedBox(height: 10),
                            for (var i = 0; i < known.length; i++)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _KnownDeviceTile(
                                  device: known[i],
                                  ctrl: manager.controllerFor(known[i].id),
                                  onTap: () =>
                                      _connectKnownAndOpen(known[i].id),
                                  onForget: () => _forget(known[i]),
                                )
                                    .animate()
                                    .fadeIn(
                                        duration: Motion.base,
                                        delay: (40 * i).ms)
                                    .slideY(
                                        begin: 0.15, curve: Motion.standard),
                              ),
                            const SizedBox(height: 8),
                          ],
                          if (discovered.isNotEmpty || known.isNotEmpty) ...[
                            const _SectionLabel('Поблизости'),
                            const SizedBox(height: 10),
                          ],
                          for (var i = 0; i < discovered.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _DeviceTile(
                                device: discovered[i],
                                onTap: () => _connectAndOpen(discovered[i]),
                              )
                                  .animate()
                                  .fadeIn(
                                      duration: Motion.base,
                                      delay: (40 * i).ms)
                                  .slideY(
                                      begin: 0.15, curve: Motion.standard),
                            ),
                          if (discovered.isEmpty && known.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                scan.isScanning
                                    ? 'Ищем ещё…'
                                    : 'Больше устройств не найдено',
                                style: const TextStyle(
                                    color: AppColors.textFaint, fontSize: 13),
                              ),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _ScanButton(
        scanning: scan.isScanning,
        onTap: scan.toggleScan,
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.connectedCount, required this.knownCount});

  final int connectedCount;
  final int knownCount;

  @override
  Widget build(BuildContext context) {
    final String subtitle;
    if (knownCount == 0) {
      subtitle = 'Найдите свой контроллер подсветки';
    } else if (connectedCount == 0) {
      subtitle = 'Известно устройств: $knownCount';
    } else {
      subtitle = 'Подключено: $connectedCount из $knownCount';
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Устройства',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 32),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textFaint,
          fontWeight: FontWeight.w700,
          fontSize: 12,
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}

/// Плитка уже известного устройства: показывает живой статус соединения
/// ([ctrl.linkState]) и позволяет открыть управление или забыть устройство
/// долгим нажатием.
class _KnownDeviceTile extends StatelessWidget {
  const _KnownDeviceTile({
    required this.device,
    required this.ctrl,
    required this.onTap,
    required this.onForget,
  });

  final KnownDevice device;
  final DeviceController ctrl;
  final VoidCallback onTap;
  final VoidCallback onForget;

  ({Color color, String label}) _statusFor(BuildContext context) {
    switch (ctrl.linkState) {
      case LinkState.connected:
        return (color: AppColors.success, label: 'Подключено');
      case LinkState.connecting:
      case LinkState.discovering:
        return (color: AppColors.accent, label: 'Подключение…');
      case LinkState.reconnecting:
        return (color: AppColors.accentSoft, label: 'Переподключение…');
      case LinkState.failed:
        return (color: AppColors.danger, label: 'Ошибка связи');
      case LinkState.disconnected:
        return (color: AppColors.textFaint, label: 'Отключено');
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _statusFor(context);
    return Pressable(
      onTap: onTap,
      onLongPress: onForget,
      borderRadius: BorderRadius.circular(24),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ctrl.led.power
                    ? ctrl.led.displayColor
                    : AppColors.glassStrong,
                boxShadow: ctrl.led.power
                    ? [
                        BoxShadow(
                          color: ctrl.led.displayColor.withValues(alpha: 0.5),
                          blurRadius: 12,
                        ),
                      ]
                    : null,
              ),
              child: const Icon(Icons.lightbulb_outline,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.name.isEmpty ? 'Без имени' : device.name,
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: status.color,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        status.label,
                        style: TextStyle(
                          color: status.color,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textFaint),
          ],
        ),
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  const _DeviceTile({required this.device, required this.onTap});

  final DiscoveredDevice device;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: device.isSupported
                      ? AppColors.scanPulse
                      : const [AppColors.textFaint, AppColors.textFaint],
                ),
              ),
              child: const Icon(Icons.lightbulb_outline,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.displayName,
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    device.isSupported ? 'ELK-BLEDOM · поддерживается' : 'BLE-устройство',
                    style: const TextStyle(
                      color: AppColors.textFaint,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            SignalBars(rssi: device.rssi),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.scanning});

  final bool scanning;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulseRing(active: scanning),
          const SizedBox(height: 28),
          Text(
            scanning ? 'Ищем устройства…' : 'Поиск остановлен',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          const Text(
            'Убедитесь, что контроллер запитан\nи находится рядом',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textFaint, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _PulseRing extends StatelessWidget {
  const _PulseRing({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: 74,
      height: 74,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: AppColors.scanPulse),
      ),
      child: const Icon(Icons.bluetooth_searching, color: Colors.white),
    );
    if (!active) return dot;
    return dot
        .animate(onPlay: (c) => c.repeat())
        .scaleXY(begin: 1, end: 1.14, duration: 1200.ms, curve: Curves.easeInOut)
        .then()
        .scaleXY(begin: 1.14, end: 1, duration: 1200.ms, curve: Curves.easeInOut);
  }
}

class _ScanButton extends StatelessWidget {
  const _ScanButton({required this.scanning, required this.onTap});

  final bool scanning;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(colors: AppColors.scanPulse),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.45),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(scanning ? Icons.stop_rounded : Icons.wifi_tethering,
                color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              scanning ? 'Остановить' : 'Искать заново',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
