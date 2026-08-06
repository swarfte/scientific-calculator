import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/always_on_top_settings.dart';

/// AppBar 上的「釘選 / 永遠置頂」按鈕。
///
/// 只在桌面平台（Windows / macOS / Linux）顯示，並以 Riverpod
/// [alwaysOnTopProvider] 驅動視窗的 always-on-top 狀態。
class PinButton extends ConsumerWidget {
  const PinButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPinned = ref.watch(alwaysOnTopProvider);
    final notifier = ref.read(alwaysOnTopProvider.notifier);

    return IconButton(
      icon: Icon(
        // 已釘選時使用實心圖釘；未釘選時使用外框圖釘。
        isPinned ? Icons.push_pin : Icons.push_pin_outlined,
        // 釘選時強調顏色，讓使用者一眼看出目前的狀態。
        color: isPinned ? Theme.of(context).colorScheme.primary : null,
      ),
      tooltip: isPinned ? 'Unpin (always on top)' : 'Pin on top',
      onPressed: notifier.toggle,
    );
  }
}
