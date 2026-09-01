import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'ui/scan/scan_screen.dart';
import 'ui/theme/app_theme.dart';

/// Разрешаем прокрутку мышью и трекпадом на десктопе.
class _AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

class ChromifyApp extends StatelessWidget {
  const ChromifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chromify',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      scrollBehavior: _AppScrollBehavior(),
      home: const ScanScreen(),
    );
  }
}
