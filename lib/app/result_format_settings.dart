import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 結果顯示格式偏好：小數或分數／根式。
///
/// 配合 DEG/RAD 旁的切換鈕使用。`decimal` 為預設值（保留原有行為）；
/// `fraction` 時會在可精確化的情況下以最簡分數／帶分數／根式顯示結果，否則
/// （三角、π、e、log 等）回退為小數。
enum ResultFormatPreference {
  /// 小數（預設）。
  decimal,

  /// 分數／根式（盡量精確化簡，無法時回退小數）。
  fraction;

  String get label {
    return switch (this) {
      ResultFormatPreference.decimal => 'DEC',
      ResultFormatPreference.fraction => 'FRAC',
    };
  }

  /// 只接受已知的持久化字串；未知值或 `null` 一律回傳 [decimal]。
  static ResultFormatPreference fromName(String? name) {
    return switch (name) {
      'fraction' => ResultFormatPreference.fraction,
      _ => ResultFormatPreference.decimal,
    };
  }
}

/// 以 SharedPreferences 持久化儲存結果顯示格式偏好。
///
/// 沿用 [ThemeSettingsStorage] 的 `SharedPreferencesAsync` 模式。
class ResultFormatSettingsStorage {
  static const _key = 'result_format_preference';
  static final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  /// 載入已儲存的偏好；未儲存時回傳 [ResultFormatPreference.decimal]。
  static Future<ResultFormatPreference> load() async {
    final name = await _preferences.getString(_key);
    return ResultFormatPreference.fromName(name);
  }

  static Future<void> save(ResultFormatPreference preference) {
    return _preferences.setString(_key, preference.name);
  }
}

/// 初始結果格式偏好。
///
/// 在 `bootstrap()` 中以從 SharedPreferences 載入的值覆寫，讓第一個畫面就
/// 套用正確的格式，避免啟動時的不一致。
final initialResultFormatPreferenceProvider = Provider<ResultFormatPreference>(
  (ref) => ResultFormatPreference.decimal,
);

/// 結果格式偏好狀態。
///
/// 讀取 [initialResultFormatPreferenceProvider] 作為初始值；[set] 同步更新
/// state，再非同步寫入 [ResultFormatSettingsStorage]。
class ResultFormatSettingsNotifier extends Notifier<ResultFormatPreference> {
  @override
  ResultFormatPreference build() =>
      ref.read(initialResultFormatPreferenceProvider);

  Future<void> set(ResultFormatPreference value) async {
    if (state == value) {
      return;
    }
    state = value;
    await ResultFormatSettingsStorage.save(value);
  }
}

final resultFormatSettingsProvider =
    NotifierProvider<ResultFormatSettingsNotifier, ResultFormatPreference>(
      ResultFormatSettingsNotifier.new,
    );
