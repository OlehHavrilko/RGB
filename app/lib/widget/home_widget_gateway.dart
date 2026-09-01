import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';
import 'package:provider/provider.dart';

import '../state/devices_manager.dart';
import 'home_widget_service.dart';
import 'widget_launch_handler.dart';

/// Инициализирует виджет главного экрана Android: держит его данные в
/// актуальном состоянии ([HomeWidgetService]) и обрабатывает открытие
/// приложения тапом по виджету ([handleWidgetLaunch]) — как при запуске
/// «холодным» тапом, так и когда приложение уже было открыто.
class HomeWidgetGateway extends StatefulWidget {
  const HomeWidgetGateway({required this.child, super.key});

  final Widget child;

  @override
  State<HomeWidgetGateway> createState() => _HomeWidgetGatewayState();
}

class _HomeWidgetGatewayState extends State<HomeWidgetGateway> {
  HomeWidgetService? _service;
  StreamSubscription<Uri?>? _clickSub;

  @override
  void initState() {
    super.initState();
    final manager = context.read<DevicesManager>();
    _service = HomeWidgetService(manager);
    _clickSub = HomeWidget.widgetClicked.listen((uri) => _handle(uri));
    unawaited(_handleInitialLaunch(manager));
  }

  Future<void> _handleInitialLaunch(DevicesManager manager) async {
    final uri = await HomeWidget.initiallyLaunchedFromHomeWidget();
    if (uri != null) await handleWidgetLaunch(uri, manager);
  }

  void _handle(Uri? uri) {
    if (uri == null) return;
    unawaited(handleWidgetLaunch(uri, context.read<DevicesManager>()));
  }

  @override
  void dispose() {
    unawaited(_clickSub?.cancel());
    _service?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
