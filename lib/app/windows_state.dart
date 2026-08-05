import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

class WindowStateData {
  const WindowStateData({required this.bounds, required this.isMaximized});

  final Rect bounds;
  final bool isMaximized;

  Size get size => bounds.size;
}

class WindowStateStorage {
  static const _keyX = 'window_x';
  static const _keyY = 'window_y';
  static const _keyWidth = 'window_width';
  static const _keyHeight = 'window_height';
  static const _keyIsMaximized = 'window_is_maximized';

  static final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  static Future<WindowStateData?> load() async {
    final x = await _preferences.getDouble(_keyX);
    final y = await _preferences.getDouble(_keyY);
    final width = await _preferences.getDouble(_keyWidth);
    final height = await _preferences.getDouble(_keyHeight);
    final isMaximized = await _preferences.getBool(_keyIsMaximized) ?? false;

    if (x == null || y == null || width == null || height == null) {
      return null;
    }

    // 避免損壞或異常資料產生不可用的視窗。
    if (!x.isFinite ||
        !y.isFinite ||
        !width.isFinite ||
        !height.isFinite ||
        width < 300 ||
        height < 200) {
      return null;
    }

    return WindowStateData(
      bounds: Rect.fromLTWH(x, y, width, height),
      isMaximized: isMaximized,
    );
  }

  static Future<void> save({
    required Rect bounds,
    required bool isMaximized,
  }) async {
    await Future.wait([
      _preferences.setDouble(_keyX, bounds.left),
      _preferences.setDouble(_keyY, bounds.top),
      _preferences.setDouble(_keyWidth, bounds.width),
      _preferences.setDouble(_keyHeight, bounds.height),
      _preferences.setBool(_keyIsMaximized, isMaximized),
    ]);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainWindow(),
    );
  }
}

class MainWindow extends StatefulWidget {
  const MainWindow({super.key});

  @override
  State<MainWindow> createState() => _MainWindowState();
}

class _MainWindowState extends State<MainWindow> with WindowListener {
  Timer? _saveTimer;

  // 最後一個非最大化狀態的視窗範圍。
  Rect? _lastNormalBounds;

  @override
  void initState() {
    super.initState();

    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      windowManager.addListener(this);
      _captureInitialBounds();
    }
  }

  Future<void> _captureInitialBounds() async {
    final isMaximized = await windowManager.isMaximized();

    if (!isMaximized) {
      _lastNormalBounds = await windowManager.getBounds();
    }
  }

  void _scheduleSave() {
    _saveTimer?.cancel();

    _saveTimer = Timer(const Duration(milliseconds: 500), _saveWindowState);
  }

  Future<void> _saveWindowState() async {
    final isMaximized = await windowManager.isMaximized();

    /*
     * 最大化時，不應直接把最大化後的螢幕大小覆蓋原本的正常大小。
     * 否則下一次取消最大化時，可能失去使用者原本的視窗大小。
     */
    if (!isMaximized) {
      _lastNormalBounds = await windowManager.getBounds();
    }

    final bounds = _lastNormalBounds;

    if (bounds == null) {
      return;
    }

    await WindowStateStorage.save(bounds: bounds, isMaximized: isMaximized);
  }

  @override
  void onWindowMove() {
    _scheduleSave();
  }

  @override
  void onWindowResize() {
    _scheduleSave();
  }

  @override
  void onWindowMaximize() {
    _scheduleSave();
  }

  @override
  void onWindowUnmaximize() {
    /*
     * 取消最大化之後，系統需要少量時間恢復正常 bounds。
     * 交給 debounce timer 稍後讀取即可。
     */
    _scheduleSave();
  }

  @override
  void onWindowClose() {
    _saveTimer?.cancel();
    _saveWindowState();
  }

  @override
  void dispose() {
    _saveTimer?.cancel();

    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      windowManager.removeListener(this);
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Window Position Example')),
      body: const Center(
        child: Text(
          '移動或調整視窗大小後，\n'
          '關閉並重新開啟程式進行測試。',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
