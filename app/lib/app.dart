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

class RgbControllerApp extends StatelessWidget {
  const RgbControllerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RGB Control',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      scrollBehavior: _AppScrollBehavior(),
      home: const ScanScreen(),
    );
  }
}
