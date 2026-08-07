import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../viewmodel/update_providers.dart';

/// 在 app 啟動時於背景觸發一次更新檢查。
///
/// 沿用 `WindowStateObserver`（`lib/app/windows_state.dart`）的包裝式 widget
/// 模式：只在 `initState` 做一次副作用，然後原樣回傳 [child]。
///
/// 檢查刻意放在這裡而不是 `UpdateController.build()`，這樣 widget 測試只要不
/// 掛上這個 widget，就絕對不會連網。
class UpdateCheckStarter extends ConsumerStatefulWidget {
  const UpdateCheckStarter({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<UpdateCheckStarter> createState() => _UpdateCheckStarterState();
}

class _UpdateCheckStarterState extends ConsumerState<UpdateCheckStarter> {
  @override
  void initState() {
    super.initState();

    // 不支援的平台（Linux / iOS / Web）沒有可下載的安裝檔，不必浪費一次請求。
    if (!ref.read(updateSupportedProvider)) {
      return;
    }

    // 不 await：啟動流程不應該被網路請求拖住。失敗會由 controller 自行吞掉。
    unawaited(
      ref.read(updateControllerProvider.notifier).checkForUpdates(
        background: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
