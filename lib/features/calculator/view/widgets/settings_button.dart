import 'package:flutter/material.dart';

import 'settings_dialog.dart';

/// AppBar 上的設定按鈕；點擊後開啟設定對話框。
class SettingsButton extends StatelessWidget {
  const SettingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.settings),
      tooltip: 'Settings',
      onPressed: () => showSettingsDialog(context),
    );
  }
}
