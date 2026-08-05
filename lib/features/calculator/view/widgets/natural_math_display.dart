import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

class NaturalMathDisplay extends StatefulWidget {
  const NaturalMathDisplay({
    required this.tex,
    required this.texWithCursor,
    required this.fallbackText,
    required this.showCursor,
    super.key,
  });

  final String tex;
  final String texWithCursor;
  final String fallbackText;
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
              onErrorFallback: (_) {
                final fallback = widget.fallbackText.trim();

                return Text(
                  fallback.isEmpty ? '|' : fallback,
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
