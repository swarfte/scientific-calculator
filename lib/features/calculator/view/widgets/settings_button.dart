import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../update/viewmodel/update_providers.dart';
import 'settings_dialog.dart';

/// AppBar 上的設定按鈕；點擊後開啟設定對話框。
///
/// 背景檢查（`UpdateCheckStarter`）找到新版本時，圖示上會出現一個紅點。
class SettingsButton extends ConsumerWidget {
  const SettingsButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasUpdate = ref.watch(updateBadgeVisibleProvider);

    return IconButton(
      // 沒有 label 的 Badge 會渲染成一個小紅點，正好符合「有新版本」的提示。
      icon: Badge(
        isLabelVisible: hasUpdate,
        child: const Icon(Icons.settings),
      ),
      tooltip: hasUpdate ? 'Settings — update available' : 'Settings',
      onPressed: () => showSettingsDialog(context),
    );
  }
}
