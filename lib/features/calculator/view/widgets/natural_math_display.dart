import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

class NaturalMathDisplay extends StatelessWidget {
  const NaturalMathDisplay({required this.tex, super.key});

  final String tex;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 100),
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
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onErrorFallback: (error) {
            return Text(
              'Expression error',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            );
          },
        ),
      ),
    );
  }
}
