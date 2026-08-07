import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 使用者選擇的佈景主題偏好。
enum ThemePreference {
  /// 跟隨系統設定。
  system,

  /// 淺色主題。
  light,

  /// 深色主題。
  dark;

  String get label {
    return switch (this) {
      ThemePreference.system => '跟隨系統',
      ThemePreference.light => '淺色',
      ThemePreference.dark => '深色',
    };
  }

  ThemeMode get themeMode {
    return switch (this) {
      ThemePreference.system => ThemeMode.system,
      ThemePreference.light => ThemeMode.light,
      ThemePreference.dark => ThemeMode.dark,
    };
  }

  /// 只接受已知的持久化字串；未知值或 `null` 一律回傳 [system]。
  static ThemePreference fromName(String? name) {
    return switch (name) {
      'light' => ThemePreference.light,
      'dark' => ThemePreference.dark,
      _ => ThemePreference.system,
    };
  }
}

/// 以 SharedPreferences 持久化儲存主題偏好。
///
/// 沿用 [WindowStateStorage] 的 `SharedPreferencesAsync` 模式。
class ThemeSettingsStorage {
  static const _key = 'theme_preference';
  static final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  /// 載入已儲存的偏好；未儲存時回傳 [ThemePreference.system]。
  static Future<ThemePreference> load() async {
    final name = await _preferences.getString(_key);
    return ThemePreference.fromName(name);
  }

  static Future<void> save(ThemePreference preference) {
    return _preferences.setString(_key, preference.name);
  }
}

/// 初始主題偏好。
///
/// 在 `bootstrap()` 中以從 SharedPreferences 載入的值覆寫，讓第一個畫面就套用
/// 正確的主題，避免啟動時的閃爍。
final initialThemePreferenceProvider = Provider<ThemePreference>(
  (ref) => ThemePreference.system,
);

/// 主題偏好狀態。
///
/// 讀取 [initialThemePreferenceProvider] 作為初始值；[set] 同步更新 state，
/// 再非同步寫入 [ThemeSettingsStorage]。
class ThemeSettingsNotifier extends Notifier<ThemePreference> {
  @override
  ThemePreference build() => ref.read(initialThemePreferenceProvider);

  Future<void> set(ThemePreference value) async {
    if (state == value) {
      return;
    }
    state = value;
    await ThemeSettingsStorage.save(value);
  }
}

final themeSettingsProvider =
    NotifierProvider<ThemeSettingsNotifier, ThemePreference>(
  ThemeSettingsNotifier.new,
);
