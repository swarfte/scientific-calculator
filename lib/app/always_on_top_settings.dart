import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

/// 視窗「永遠置頂」(always on top / pin) 偏好是否已開啟。
///
/// 沿用 [WindowStateStorage] 與 [ThemeSettingsStorage] 的
/// `SharedPreferencesAsync` + Riverpod `Notifier` 模式。
class AlwaysOnTopStorage {
  static const _key = 'window_always_on_top';
  static final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  /// 載入已儲存的偏好；未儲存時回傳 `false`。
  static Future<bool> load() async {
    final value = await _preferences.getBool(_key);
    return value ?? false;
  }

  static Future<void> save(bool value) {
    return _preferences.setBool(_key, value);
  }
}

/// 目前是否為桌面平台（Web / 行動裝置不支援 always on top）。
final isDesktopPlatformProvider = Provider<bool>((ref) {
  return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
});

/// 初始 always-on-top 偏好。
///
/// 在 `bootstrap()` 中以從 SharedPreferences 載入的值覆寫，讓第一個畫面就
/// 套用正確的釘選狀態。
final initialAlwaysOnTopProvider = Provider<bool>((ref) => false);

/// always-on-top 狀態。
///
/// 讀取 [initialAlwaysOnTopProvider] 作為初始值；[toggle] / [set] 同步更新
/// state，再套用到桌面視窗並非同步寫入 [AlwaysOnTopStorage]。
class AlwaysOnTopNotifier extends Notifier<bool> {
  @override
  bool build() => ref.read(initialAlwaysOnTopProvider);

  Future<void> set(bool value) async {
    if (state == value) {
      return;
    }

    state = value;

    if (ref.read(isDesktopPlatformProvider)) {
      // setAlwaysOnTop 在非桌面平台會擲回例外，因此先以平台守衛擋住。
      await windowManager.setAlwaysOnTop(value);
    }

    await AlwaysOnTopStorage.save(value);
  }

  Future<void> toggle() => set(!state);
}

final alwaysOnTopProvider =
    NotifierProvider<AlwaysOnTopNotifier, bool>(AlwaysOnTopNotifier.new);
