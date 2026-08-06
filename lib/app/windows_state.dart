import 'dart:async';

import 'package:flutter/material.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import '../core/platform/platform_info.dart';

class WindowStateData {
  const WindowStateData({required this.bounds, required this.isMaximized});

  final Rect bounds;
  final bool isMaximized;

  Size get size => bounds.size;

  WindowStateData copyWith({Rect? bounds, bool? isMaximized}) {
    return WindowStateData(
      bounds: bounds ?? this.bounds,
      isMaximized: isMaximized ?? this.isMaximized,
    );
  }
}

class WindowStateStorage {
  static const _keyX = 'window_x';
  static const _keyY = 'window_y';
  static const _keyWidth = 'window_width';
  static const _keyHeight = 'window_height';
  static const _keyIsMaximized = 'window_is_maximized';

  static const double _minimumWidth = 400;
  static const double _minimumHeight = 700;

  /*
   * 最少保留多少視窗在畫面內。
   *
   * 這樣即使使用者稍微把視窗拖出畫面，也不會錯誤地把它
   * 判斷成無效位置。
   */
  static const double _minimumVisibleWidth = 80;
  static const double _minimumVisibleHeight = 80;

  static final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  /// 只從 SharedPreferences 載入原始資料。
  static Future<WindowStateData?> load() async {
    final x = await _preferences.getDouble(_keyX);
    final y = await _preferences.getDouble(_keyY);
    final width = await _preferences.getDouble(_keyWidth);
    final height = await _preferences.getDouble(_keyHeight);
    final isMaximized = await _preferences.getBool(_keyIsMaximized) ?? false;

    if (x == null || y == null || width == null || height == null) {
      return null;
    }

    // 避免損壞、NaN 或 Infinity 資料產生不可用的視窗。
    if (!x.isFinite ||
        !y.isFinite ||
        !width.isFinite ||
        !height.isFinite ||
        width < _minimumWidth ||
        height < _minimumHeight) {
      return null;
    }

    return WindowStateData(
      bounds: Rect.fromLTWH(x, y, width, height),
      isMaximized: isMaximized,
    );
  }

  /// 載入資料，並根據目前連接的顯示器修正視窗位置。
  static Future<WindowStateData?> loadValidated() async {
    final savedState = await load();

    if (savedState == null) {
      return null;
    }

    try {
      final displays = await screenRetriever.getAllDisplays();

      if (displays.isEmpty) {
        return null;
      }

      final screenBounds = displays
          .map(_getDisplayVisibleBounds)
          .whereType<Rect>()
          .toList();

      if (screenBounds.isEmpty) {
        /*
         * 如果平台沒有回傳 visiblePosition 或 visibleSize，
         * 不冒險使用可能位於螢幕外的位置。
         *
         * 返回 null 後，bootstrap.dart 會把視窗放到主螢幕中央。
         */
        return null;
      }

      final correctedBounds = _correctWindowBounds(
        savedState.bounds,
        screenBounds,
      );

      if (correctedBounds == null) {
        /*
         * 舊視窗與目前所有顯示器都沒有足夠的重疊範圍。
         *
         * 最常見情況：
         * 上次把視窗放在外接螢幕，今次啟動時外接螢幕已拔除。
         */
        return null;
      }

      return savedState.copyWith(bounds: correctedBounds);
    } catch (_) {
      /*
       * screen_retriever 發生平台例外時，返回 null。
       * bootstrap.dart 會安全地使用預設大小並置中。
       */
      return null;
    }
  }

  static Rect? _getDisplayVisibleBounds(Display display) {
    final visiblePosition = display.visiblePosition;
    final visibleSize = display.visibleSize;

    if (visiblePosition == null || visibleSize == null) {
      return null;
    }

    if (!visiblePosition.dx.isFinite ||
        !visiblePosition.dy.isFinite ||
        !visibleSize.width.isFinite ||
        !visibleSize.height.isFinite ||
        visibleSize.width <= 0 ||
        visibleSize.height <= 0) {
      return null;
    }

    return Rect.fromLTWH(
      visiblePosition.dx,
      visiblePosition.dy,
      visibleSize.width,
      visibleSize.height,
    );
  }

  static Rect? _correctWindowBounds(Rect savedBounds, List<Rect> screenBounds) {
    Rect? bestScreen;
    double largestVisibleArea = 0;

    /*
     * 找出與舊視窗重疊面積最大的顯示器。
     *
     * 不使用 x >= 0 或 y >= 0 判斷，因為：
     * 1. 左邊的外接螢幕通常有負數 X
     * 2. 上方的外接螢幕可能有負數 Y
     */
    for (final screen in screenBounds) {
      final intersection = savedBounds.intersect(screen);

      if (intersection.isEmpty) {
        continue;
      }

      final visibleWidth = intersection.width;
      final visibleHeight = intersection.height;

      if (visibleWidth < _minimumVisibleWidth ||
          visibleHeight < _minimumVisibleHeight) {
        continue;
      }

      final visibleArea = visibleWidth * visibleHeight;

      if (visibleArea > largestVisibleArea) {
        largestVisibleArea = visibleArea;
        bestScreen = screen;
      }
    }

    if (bestScreen == null) {
      return null;
    }

    /*
     * 如果視窗比顯示器可用範圍更大，縮小至顯示器範圍。
     *
     * 例如：
     * 上次在大型外接螢幕使用 1400 x 900，
     * 今次只使用較小的 MacBook 顯示器。
     */
    final correctedWidth = savedBounds.width
        .clamp(_minimumWidth, bestScreen.width)
        .toDouble();

    final correctedHeight = savedBounds.height
        .clamp(_minimumHeight, bestScreen.height)
        .toDouble();

    /*
     * 修正位置，確保整個視窗位於顯示器的可用範圍。
     */
    final maximumLeft = bestScreen.right - correctedWidth;
    final maximumTop = bestScreen.bottom - correctedHeight;

    final correctedLeft = savedBounds.left
        .clamp(bestScreen.left, maximumLeft)
        .toDouble();

    final correctedTop = savedBounds.top
        .clamp(bestScreen.top, maximumTop)
        .toDouble();

    return Rect.fromLTWH(
      correctedLeft,
      correctedTop,
      correctedWidth,
      correctedHeight,
    );
  }

  static Future<void> save({
    required Rect bounds,
    required bool isMaximized,
  }) async {
    if (!bounds.left.isFinite ||
        !bounds.top.isFinite ||
        !bounds.width.isFinite ||
        !bounds.height.isFinite) {
      return;
    }

    await Future.wait([
      _preferences.setDouble(_keyX, bounds.left),
      _preferences.setDouble(_keyY, bounds.top),
      _preferences.setDouble(_keyWidth, bounds.width),
      _preferences.setDouble(_keyHeight, bounds.height),
      _preferences.setBool(_keyIsMaximized, isMaximized),
    ]);
  }

  /// 清除已儲存的視窗資料。
  ///
  /// 可用於加入「重設視窗位置」功能。
  static Future<void> clear() async {
    await Future.wait([
      _preferences.remove(_keyX),
      _preferences.remove(_keyY),
      _preferences.remove(_keyWidth),
      _preferences.remove(_keyHeight),
      _preferences.remove(_keyIsMaximized),
    ]);
  }
}

/// 包住現有 App，負責監聽及儲存桌面視窗狀態。
class WindowStateObserver extends StatefulWidget {
  const WindowStateObserver({required this.child, super.key});

  final Widget child;

  @override
  State<WindowStateObserver> createState() => _WindowStateObserverState();
}

class _WindowStateObserverState extends State<WindowStateObserver>
    with WindowListener {
  Timer? _saveTimer;

  // 最後一個非最大化狀態的視窗範圍。
  Rect? _lastNormalBounds;

  @override
  void initState() {
    super.initState();

    if (PlatformInfo.isDesktop) {
      windowManager.addListener(this);
      unawaited(_captureInitialBounds());
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

    _saveTimer = Timer(const Duration(milliseconds: 500), () {
      unawaited(_saveWindowState());
    });
  }

  Future<void> _saveWindowState() async {
    if (!PlatformInfo.isDesktop) {
      return;
    }

    final isMaximized = await windowManager.isMaximized();

    /*
     * 最大化時，不把最大化後的 bounds 覆蓋普通視窗 bounds。
     *
     * 否則使用者下次取消最大化時，可能無法回到原本的
     * 視窗位置和大小。
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
     * 取消最大化後，系統需要少量時間恢復普通 bounds。
     * 交由 500ms debounce 後讀取。
     */
    _scheduleSave();
  }

  @override
  void onWindowClose() {
    _saveTimer?.cancel();
    unawaited(_saveWindowState());
  }

  @override
  void dispose() {
    _saveTimer?.cancel();

    if (PlatformInfo.isDesktop) {
      windowManager.removeListener(this);
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
