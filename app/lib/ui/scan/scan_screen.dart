import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../ble/ble_device.dart';
import '../../ble/ble_service.dart';
import '../../state/device_controller.dart';
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

  void _openControl(DiscoveredDevice device) {
    context.read<DeviceController>().connectTo(device);
    context.read<ScanController>().stopScan();
    Navigator.of(context).push(
      FadeThroughPageRoute<void>(page: const ControlScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scan = context.watch<ScanController>();
    final devices = scan.devices;

    return Scaffold(
      body: AmbientBackground(
        glow: AppColors.accent,
        intensity: 0.6,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 20, 24, 8),
                child: _Header(),
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
                child: devices.isEmpty
                    ? _EmptyState(scanning: scan.isScanning)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                        itemCount: devices.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final d = devices[i];
                          return _DeviceTile(
                            device: d,
                            onTap: () => _openControl(d),
                          )
                              .animate()
                              .fadeIn(duration: Motion.base, delay: (40 * i).ms)
                              .slideY(begin: 0.15, curve: Motion.standard);
                        },
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
  const _Header();

  @override
  Widget build(BuildContext context) {
    final last = context.select<DeviceController, String?>(
      (c) => c.lastKnownDeviceName,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Устройства',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 32),
        ),
        const SizedBox(height: 4),
        Text(
          last == null
              ? 'Найдите свой контроллер подсветки'
              : 'Последнее: $last',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
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
