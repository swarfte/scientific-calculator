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
      final parser = GrammarParser();

      _registerFunctions(parser, angleMode: angleMode);

      final normalized = _normalizeExpression(expression);

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

  void _registerFunctions(
    GrammarParser parser, {
    required AngleMode angleMode,
  }) {
    double toRadians(double value) {
      return angleMode == AngleMode.degree ? value * math.pi / 180 : value;
    }

    parser.addFunction('sind', (arguments) {
      _requireArgumentCount('sin', arguments, 1);

      return math.sin(toRadians(arguments.first));
    });

    parser.addFunction('cosd', (arguments) {
      _requireArgumentCount('cos', arguments, 1);

      return math.cos(toRadians(arguments.first));
    });

    parser.addFunction('tand', (arguments) {
      _requireArgumentCount('tan', arguments, 1);

      return math.tan(toRadians(arguments.first));
    });

    parser.addFunction('sqrtx', (arguments) {
      _requireArgumentCount('sqrt', arguments, 1);

      final value = arguments.first;

      if (value < 0) {
        return double.nan;
      }

      return math.sqrt(value);
    });

    parser.addFunction('log10x', (arguments) {
      _requireArgumentCount('log', arguments, 1);

      final value = arguments.first;

      if (value <= 0) {
        return double.nan;
      }

      return math.log(value) / math.ln10;
    });

    parser.addFunction('lnx', (arguments) {
      _requireArgumentCount('ln', arguments, 1);

      final value = arguments.first;

      if (value <= 0) {
        return double.nan;
      }

      return math.log(value);
    });
  }

  String _normalizeExpression(String expression) {
    return expression
        .replaceAll('π', 'pi')
        .replaceAllMapped(RegExp(r'\bsin\s*\('), (_) => 'sind(')
        .replaceAllMapped(RegExp(r'\bcos\s*\('), (_) => 'cosd(')
        .replaceAllMapped(RegExp(r'\btan\s*\('), (_) => 'tand(')
        .replaceAllMapped(RegExp(r'\bsqrt\s*\('), (_) => 'sqrtx(')
        .replaceAllMapped(RegExp(r'\blog\s*\('), (_) => 'log10x(')
        .replaceAllMapped(RegExp(r'\bln\s*\('), (_) => 'lnx(');
  }

  void _requireArgumentCount(
    String functionName,
    List<double> arguments,
    int expected,
  ) {
    if (arguments.length != expected) {
      throw FormatException('$functionName expects $expected argument');
    }
  }
}
