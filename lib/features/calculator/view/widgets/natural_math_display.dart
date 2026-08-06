import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

/// 算式自然顯示區。
///
/// 職責（Phase 6 後）：
/// - 在 visible / hidden TeX 間切換以產生閃爍游標。
/// - 維持等寬 cursor layout（TeX 由 Tree Serializer 保證等寬）。
/// - 水平捲動。
/// - Renderer 失敗時顯示安全 fallback（空白或游標），不顯示錯誤訊息。
///
/// 不管理 cursor location，也不依賴 evaluationExpression。
class NaturalMathDisplay extends StatefulWidget {
  const NaturalMathDisplay({
    required this.tex,
    required this.texWithCursor,
    required this.showCursor,
    super.key,
  });

  final String tex;
  final String texWithCursor;
  final bool showCursor;

  @override
  State<NaturalMathDisplay> createState() => _NaturalMathDisplayState();
}

class _NaturalMathDisplayState extends State<NaturalMathDisplay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _cursorController;

  @override
  void initState() {
    super.initState();

    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _cursorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 110),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        reverse: true,
        child: AnimatedBuilder(
          animation: _cursorController,
          builder: (context, child) {
            final cursorIsVisible =
                widget.showCursor && _cursorController.value < 0.5;

            final currentTex = cursorIsVisible
                ? widget.texWithCursor
                : widget.tex;

            return Math.tex(
              currentTex,
              mathStyle: MathStyle.display,
              textStyle: TextStyle(
                fontSize: MediaQuery.sizeOf(context).width < 400 ? 28 : 36,
                color: textColor,
              ),
              // Renderer 失敗時顯示安全 fallback：僅游標或空白，不顯示錯誤。
              onErrorFallback: (_) {
                return Text(
                  widget.showCursor ? '|' : '',
                  style: TextStyle(fontSize: 28, color: textColor),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
