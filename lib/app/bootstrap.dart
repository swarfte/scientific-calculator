import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

import 'dart:async';
import 'dart:io';
import 'package:window_manager/window_manager.dart';
import 'windows_state_store.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    await windowManager.ensureInitialized();
    final savedState = await WindowStateStorage.load();
    final windowOptions = WindowOptions(
      size: savedState?.size ?? const Size(400, 700),
      center: savedState == null,
      minimumSize: const Size(400, 700),
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      if (savedState != null) {
        await windowManager.setBounds(savedState.bounds);
        if (savedState.isMaximized) {
          await windowManager.maximize();
        }
      }
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const ProviderScope(child: ScientificCalculatorApp()));
}
