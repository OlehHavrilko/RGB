import 'package:flutter/material.dart';

import '../../ble/ble_connection.dart';
import '../theme/app_colors.dart';
import '../theme/motion.dart';
import '../widgets/pressable.dart';

class ConnectionBanner extends StatelessWidget {
  const ConnectionBanner({
    super.key,
    required this.state,
    required this.deviceName,
    required this.onReconnect,
    required this.onDisconnect,
  });

  final LinkState state;
  final String deviceName;
  final VoidCallback onReconnect;
  final VoidCallback onDisconnect;

  ({Color color, String label, bool spinner}) get _visual {
    switch (state) {
      case LinkState.connected:
        return (color: AppColors.success, label: 'Подключено', spinner: false);
      case LinkState.connecting:
        return (color: AppColors.accent, label: 'Подключение…', spinner: true);
      case LinkState.discovering:
        return (color: AppColors.accent, label: 'Настройка…', spinner: true);
      case LinkState.reconnecting:
        return (
          color: AppColors.accentSoft,
          label: 'Переподключение…',
          spinner: true
        );
      case LinkState.failed:
        return (color: AppColors.danger, label: 'Ошибка связи', spinner: false);
      case LinkState.disconnected:
        return (color: AppColors.textFaint, label: 'Отключено', spinner: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = _visual;
    final showReconnect =
        state == LinkState.failed || state == LinkState.disconnected;

    return AnimatedContainer(
      duration: Motion.base,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: v.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: v.color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: v.spinner
                ? CircularProgressIndicator(strokeWidth: 2, color: v.color)
                : Icon(Icons.circle, size: 10, color: v.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  v.label,
                  style: TextStyle(
                    color: v.color,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                Text(
                  deviceName,
                  style: const TextStyle(
                    color: AppColors.textFaint,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (showReconnect)
            Pressable(
              onTap: onReconnect,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: v.color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Ещё раз',
                  style: TextStyle(
                    color: v.color,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            )
          else
            Pressable(
              onTap: onDisconnect,
              borderRadius: BorderRadius.circular(14),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.link_off_rounded,
                    size: 18, color: AppColors.textFaint),
              ),
            ),
        ],
      ),
    );
  }
}
