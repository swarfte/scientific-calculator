import 'package:flutter/material.dart';

enum CalculatorKeyStyle { normal, function, operator, destructive, equals }

class CalculatorKey extends StatelessWidget {
  const CalculatorKey({
    required this.label,
    required this.onPressed,
    this.style = CalculatorKeyStyle.normal,
    this.flex = 1,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
  final CalculatorKeyStyle style;
  final int flex;

  @override
  Widget build(BuildContext context) {
    final colors = _resolveColors(context);

    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Material(
          color: colors.background,
          borderRadius: BorderRadius.circular(12),
          elevation: 1,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onPressed,
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: colors.foreground,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  ({Color background, Color foreground}) _resolveColors(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return switch (style) {
      CalculatorKeyStyle.normal => (
        background: scheme.surfaceContainerHighest,
        foreground: scheme.onSurface,
      ),
      CalculatorKeyStyle.function => (
        background: scheme.secondaryContainer,
        foreground: scheme.onSecondaryContainer,
      ),
      CalculatorKeyStyle.operator => (
        background: scheme.tertiaryContainer,
        foreground: scheme.onTertiaryContainer,
      ),
      CalculatorKeyStyle.destructive => (
        background: scheme.errorContainer,
        foreground: scheme.onErrorContainer,
      ),
      CalculatorKeyStyle.equals => (
        background: scheme.primary,
        foreground: scheme.onPrimary,
      ),
    };
  }
}
