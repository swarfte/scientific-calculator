import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;

import 'release_info.dart';

/// 有提供自動更新安裝檔的平台。
///
/// CI 只建置 Android / Windows / macOS 三個平台（見
/// `.github/workflows/build-release.yml`），其餘平台（Linux、iOS、Web）
/// 一律為 [unsupported]，UI 只會提供「開啟 Release 頁面」的連結。
enum UpdatePlatform {
  android,
  windows,
  macos,
  unsupported;

  /// 目前執行的平台。
  ///
  /// 必須先以 `kIsWeb` 短路，才能讀取 `dart:io` 的 `Platform`；這是
  /// `PlatformInfo`（`lib/core/platform/platform_info.dart`）已經記錄的規則
  /// （Web 上存取 `Platform.is*` 會擲回 `Unsupported operation`）。
  static UpdatePlatform get current {
    if (kIsWeb) {
      return UpdatePlatform.unsupported;
    }

    if (Platform.isAndroid) {
      return UpdatePlatform.android;
    }
    if (Platform.isWindows) {
      return UpdatePlatform.windows;
    }
    if (Platform.isMacOS) {
      return UpdatePlatform.macos;
    }

    return UpdatePlatform.unsupported;
  }

  bool get isSupported => this != UpdatePlatform.unsupported;

  /// 優先比對的完整檔名後綴。
  ///
  /// 對應 CI 產出的三個 asset（workflow 自身也會驗證這些檔名存在）：
  /// `scientific_calculator-Android.apk`、
  /// `scientific_calculator-Windows-Setup.exe`、
  /// `scientific_calculator.dmg`。
  List<String> get _assetSuffixes {
    return switch (this) {
      UpdatePlatform.android => const ['-Android.apk', '.apk'],
      UpdatePlatform.windows => const ['-Windows-Setup.exe', '.exe'],
      UpdatePlatform.macos => const ['.dmg'],
      UpdatePlatform.unsupported => const [],
    };
  }

  /// 從 Release 的 assets 中挑出這個平台要下載的檔案。
  ///
  /// 後綴由精確到寬鬆依序比對，因此即使日後 CI 改了檔名前綴（例如 app 更名），
  /// 仍能靠副檔名找到正確的安裝檔。找不到時回傳 `null`。
  ReleaseAsset? selectAsset(List<ReleaseAsset> assets) {
    for (final suffix in _assetSuffixes) {
      for (final asset in assets) {
        if (asset.name.toLowerCase().endsWith(suffix.toLowerCase())) {
          return asset;
        }
      }
    }

    return null;
  }

  /// 安裝檔在各平台的動作描述，用於按鈕文字。
  String get installActionLabel {
    return switch (this) {
      UpdatePlatform.android => 'Download & install',
      UpdatePlatform.windows => 'Download & install',
      UpdatePlatform.macos => 'Download & open',
      UpdatePlatform.unsupported => 'Download',
    };
  }
}
