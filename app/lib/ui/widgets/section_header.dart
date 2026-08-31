import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Заголовок секции на экране управления.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textFaint,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 1.4,
            ),
          ),
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}
