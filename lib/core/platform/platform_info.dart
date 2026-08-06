import 'dart:io';

import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

/// 平台相關的輔助函式。
///
/// 重點：[dart:io] 的 `Platform` 在 Web 上不存在，存取任何
/// `Platform.is*` 都會擲回 `Unsupported operation: Platform._operatingSystem`。
/// 因此所有桌面平台判斷都必須先以 `kIsWeb` 短路擋住，再讀取 `Platform`。
class PlatformInfo {
  PlatformInfo._();

  /// 是否為桌面平台（Windows / macOS / Linux）。
  ///
  /// 在 Web 與行動裝置上一律回傳 `false`。
  static bool get isDesktop {
    if (kIsWeb) {
      return false;
    }

    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  /// 目前是否為 Web 平台。
  static bool get isWeb => kIsWeb;

  /// 來自 Flutter 的目標平台；在 Web 上仍可安全讀取。
  static bool get isMobile {
    if (kIsWeb) {
      return false;
    }

    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }
}
