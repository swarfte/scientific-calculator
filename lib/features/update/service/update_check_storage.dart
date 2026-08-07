import 'package:shared_preferences/shared_preferences.dart';

/// 記住上次檢查到的最新 Release tag。
///
/// 沿用 [ThemeSettingsStorage] / [ResultFormatSettingsStorage] 的
/// `SharedPreferencesAsync` 靜態類別模式。
///
/// 用途只有一個：啟動時先用上次的結果把紅點點亮，不必等網路回應。真正的
/// 判斷仍以每次啟動實際打 API 的結果為準，因此不需要額外的節流機制
/// （每次啟動一個請求遠低於 GitHub 未驗證的 60 次／小時上限）。
class UpdateCheckStorage {
  static const _keyLatestTag = 'update_latest_tag';

  /// 刻意每次重新建立，而不是像其他 Storage 一樣存成 `static final`。
  ///
  /// `SharedPreferencesAsync` 的建構式會把 `SharedPreferencesAsyncPlatform
  /// .instance` 抓進私有欄位，之後就不再重讀；用 `static final` 快取實例的話，
  /// 測試在 `setUp` 換掉 in-memory 平台實作也不會生效，資料會跨測試殘留。
  /// 這裡一次啟動最多只呼叫兩次，重建的成本可以忽略。
  static SharedPreferencesAsync get _preferences => SharedPreferencesAsync();

  /// 載入上次檢查到的最新 tag；沒有紀錄時回傳 `null`。
  static Future<String?> loadLatestTag() {
    return _preferences.getString(_keyLatestTag);
  }

  static Future<void> saveLatestTag(String tag) {
    return _preferences.setString(_keyLatestTag, tag);
  }
}
