import 'package:flutter/material.dart';

import '../../../../app/result_format_settings.dart';

/// 結果顯示格式切換鈕（DEC / FRAC），樣式與 [ModeIndicator]（DEG/RAD）一致。
class ResultFormatIndicator extends StatelessWidget {
  const ResultFormatIndicator({
    required this.resultFormat,
    required this.onPressed,
    super.key,
  });

  final ResultFormatPreference resultFormat;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(resultFormat.label),
      avatar: const Icon(Icons.calculate, size: 18),
      onPressed: onPressed,
    );
  }
}
