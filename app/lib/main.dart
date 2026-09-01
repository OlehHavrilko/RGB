import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'ble/ble_service.dart';
import 'state/devices_manager.dart';
import 'state/prefs.dart';
import 'state/scan_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

  final prefs = await Prefs.load();
  final ble = BleService();

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
      child: const ChromifyApp(),
    ),
  );
}
