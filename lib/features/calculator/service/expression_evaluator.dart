import 'dart:math' as math;

import 'package:math_expressions/math_expressions.dart';

import '../../../core/errors/calculator_exception.dart';
import '../../../core/math/angle_mode.dart';

class ExpressionEvaluator {
  const ExpressionEvaluator();

  num evaluate(String expression, {required AngleMode angleMode}) {
    if (expression.trim().isEmpty) {
      throw const CalculatorException(
        '請先輸入算式',
        type: CalculatorErrorType.emptyExpression,
      );
    }

    try {
      final normalized = _normalizeExpression(expression, angleMode: angleMode);

      final parser = GrammarParser();
      final parsedExpression = parser.parse(normalized);

      final context = ContextModel()
        ..bindVariableName('pi', Number(math.pi))
        ..bindVariableName('e', Number(math.e));

      final evaluator = RealEvaluator(context);
      final result = evaluator.evaluate(parsedExpression);

      final doubleResult = result.toDouble();

      if (doubleResult.isNaN) {
        throw const CalculatorException(
          '此算式在實數範圍內沒有定義',
          type: CalculatorErrorType.domainError,
        );
      }

      if (doubleResult.isInfinite) {
        throw const CalculatorException(
          '結果超出可顯示範圍',
          type: CalculatorErrorType.nonFiniteResult,
        );
      }

      return result;
    } on CalculatorException {
      rethrow;
    } catch (_) {
      throw const CalculatorException(
        '算式格式不正確',
        type: CalculatorErrorType.invalidExpression,
      );
    }
  }

  String _normalizeExpression(
    String expression, {
    required AngleMode angleMode,
  }) {
    var result = expression;

    result = result.replaceAll('π', 'pi');

    if (angleMode == AngleMode.degree) {
      result = _convertSimpleTrigArgumentsToRadians(result);
    }

    return result;
  }

  String _convertSimpleTrigArgumentsToRadians(String expression) {
    final pattern = RegExp(r'\b(sin|cos|tan)\((-?\d+(?:\.\d+)?)\)');

    return expression.replaceAllMapped(pattern, (match) {
      final functionName = match.group(1)!;
      final value = match.group(2)!;

      return '$functionName(($value)*pi/180)';
    });
  }
}
