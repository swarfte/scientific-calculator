import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// 為測試安裝 SharedPreferences 的 mock 平台實作。
///
/// `SharedPreferences.setMockInitialValues({})` 只會註冊「舊版」
/// ([SharedPreferencesStorePlatform]) 的 in-memory store；但專案使用的是
/// `SharedPreferencesAsync`，它依賴另一個獨立的 singleton
/// `SharedPreferencesAsyncPlatform.instance`，未註冊時會擲回
/// `Bad state: The SharedPreferencesAsyncPlatform instance must be set.`。
///
/// 此 helper 同時安裝兩者，讓涉及 [SharedPreferencesAsync] 的測試能正確執行。
void setupSharedPreferencesForTest([Map<String, Object>? initial]) {
  // 舊版 store（保留舊測試行為）。
  SharedPreferences.setMockInitialValues(initial ?? const <String, Object>{});

  // 新版 async 平台；每次 setUp 重新建立，避免跨測試殘留資料。
  SharedPreferencesAsyncPlatform.instance =
      initial == null || initial.isEmpty
          ? InMemorySharedPreferencesAsync.empty()
          : InMemorySharedPreferencesAsync.withData(initial);
}
