import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'ble/ble_service.dart';
import 'l10n/app_locale.dart';
import 'l10n/locale_controller.dart';
import 'state/devices_manager.dart';
import 'state/prefs.dart';
import 'state/scan_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

  final prefs = await Prefs.load();
  final ble = BleService();
  final systemLocale = AppLocale.fromLanguageCode(
    PlatformDispatcher.instance.locale.languageCode,
  );
  final localeController = LocaleController(prefs, systemLocale: systemLocale);

  runApp(
    MultiProvider(
      providers: [
        Provider<BleService>.value(value: ble),
        Provider<Prefs>.value(value: prefs),
        ChangeNotifierProvider<ScanController>(
          create: (_) => ScanController(ble),
        ),
        ChangeNotifierProvider<DevicesManager>(
          create: (_) => DevicesManager(prefs),
        ),
      ],
      child: LocaleControllerScope(
        controller: localeController,
        child: const ChromifyApp(),
      ),
    ),
  );
}
