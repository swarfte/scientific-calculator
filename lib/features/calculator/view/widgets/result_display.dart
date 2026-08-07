import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

/// 計算結果顯示區。
///
/// 顯示規則：
/// - 有錯誤訊息 -> 顯示錯誤（error 色）。
/// - 有 [tex]（分數模式下可精確化簡的結果）-> 以 `flutter_math_fork` 渲染
///   最簡分數／帶分數／根式；水平置右、可橫向捲動。
/// - 否則 -> 顯示 [result] 純文字（小數），無結果時顯示 `0`。
class ResultDisplay extends StatelessWidget {
  const ResultDisplay({
    required this.result,
    required this.errorMessage,
    this.tex,
    super.key,
  });

  final String? result;
  final String? errorMessage;

  /// 精確結果的 TeX；為 `null` 時退回 [result] 純文字顯示。
  final String? tex;

  @override
  Widget build(BuildContext context) {
    final hasError = errorMessage != null;
    final theme = Theme.of(context);
    final baseStyle = theme.textTheme.headlineMedium?.copyWith(
      fontWeight: FontWeight.w600,
    );
    final color = hasError
        ? theme.colorScheme.error
        : theme.colorScheme.onSurface;

    final Widget content;
    if (hasError) {
      content = Text(
        errorMessage!,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.right,
        style: baseStyle?.copyWith(color: color),
      );
    } else if (tex != null) {
      content = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        reverse: true,
        child: Math.tex(
          tex!,
          mathStyle: MathStyle.text,
          textStyle: baseStyle?.copyWith(color: color),
          onErrorFallback: (_) => Text(
            result ?? '0',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: baseStyle?.copyWith(color: color),
          ),
        ),
      );
    } else {
      content = Text(
        result ?? '0',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.right,
        style: baseStyle?.copyWith(color: color),
      );
    }

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      alignment: Alignment.centerRight,
      child: content,
    );
  }
}
