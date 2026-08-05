import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

class NaturalMathDisplay extends StatelessWidget {
  const NaturalMathDisplay({
    required this.tex,
    required this.fallbackText,
    super.key,
  });

  final String tex;
  final String fallbackText;

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
        child: Math.tex(
          tex,
          mathStyle: MathStyle.display,
          textStyle: TextStyle(
            fontSize: MediaQuery.sizeOf(context).width < 400 ? 28 : 36,
            color: textColor,
          ),
          onErrorFallback: (_) {
            return Text(
              fallbackText.isEmpty ? '□' : fallbackText,
              style: TextStyle(fontSize: 28, color: textColor),
            );
          },
        ),
      ),
    );
  }
}
