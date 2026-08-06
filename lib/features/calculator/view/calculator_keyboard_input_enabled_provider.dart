import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/platform/platform_info.dart';

/// 是否啟用硬體鍵盤輸入。
///
/// 只在桌面（Windows / macOS / Linux）與瀏覽器上啟用；行動裝置沒有硬體
/// 鍵盤，攔截鍵盤事件沒有意義。
final isKeyboardInputEnabledProvider = Provider<bool>((ref) {
  return PlatformInfo.isDesktop || PlatformInfo.isWeb;
});
