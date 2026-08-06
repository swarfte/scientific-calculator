import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'theme_settings.dart';
import 'windows_state.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  final isDesktop = Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  if (isDesktop) {
    await windowManager.ensureInitialized();

    /*
     * loadValidated() 不只是載入資料，還會檢查：
     *
     * 1. 上次使用的螢幕是否仍然存在
     * 2. 視窗是否仍位於任何可見螢幕之內
     * 3. 視窗大小是否超過目前顯示器的可用範圍
     * 4. 視窗是否被 macOS Dock 或 menu bar 擋住
     */
    final savedState = await WindowStateStorage.loadValidated();

    final windowOptions = WindowOptions(
      size: savedState?.size ?? const Size(400, 700),

      // 找不到有效的舊位置時，在主螢幕置中。
      center: savedState == null,

      minimumSize: const Size(400, 700),
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      if (savedState != null) {
        // 先還原普通狀態時的位置和大小。
        await windowManager.setBounds(savedState.bounds);

        // 再還原最大化狀態。
        if (savedState.isMaximized) {
          await windowManager.maximize();
        }
      }

      await windowManager.show();
      await windowManager.focus();
    });
  }

  // 預先載入主題偏好，讓第一個畫面就套用上次選擇的主題，避免啟動閃爍。
  final initialThemePreference = await ThemeSettingsStorage.load();

  runApp(
    ProviderScope(
      overrides: [
        initialThemePreferenceProvider
            .overrideWith((ref) => initialThemePreference),
      ],
      child: WindowStateObserver(child: ScientificCalculatorApp()),
    ),
  );
}
