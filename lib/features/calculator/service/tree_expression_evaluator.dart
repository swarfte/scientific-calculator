import 'package:math_expressions/math_expressions.dart';

import '../../../core/errors/calculator_exception.dart';

/// 編譯後 [Expression] 的求值器（Tree 版本）。
///
/// 接收 [ExpressionCompiler] 產生的 [Expression]，以 `RealEvaluator` 求值，
/// 並將數學錯誤（divide by zero、domain error、overflow 等）翻譯為對應的
/// [CalculatorException]。
///
/// DEG/RAD 已在 Compiler 階段處理（包裝 argument），Evaluator 不再關心角度
/// 模式。
///
/// 待 Phase 6 切換後，取代舊字串版 `expression_evaluator.dart`。
class TreeExpressionEvaluator {
  const TreeExpressionEvaluator();

  /// 求值 [expression]，回傳 double。
  ///
  /// `Infinity` / `-Infinity` 映射為 [CalculatorErrorType.overflow]，
  /// `NaN` 映射為 [CalculatorErrorType.domainError]。Divide-by-zero 與其他
  /// 評估例外分別映射為 [CalculatorErrorType.divisionByZero] /
  /// [CalculatorErrorType.invalidExpression]。
  double evaluate(Expression expression) {
    try {
      final evaluator = RealEvaluator(ContextModel());
      final result = evaluator.evaluate(expression);

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
          type: CalculatorErrorType.overflow,
        );
      }

      return doubleResult;
    } on CalculatorException {
      rethrow;
    } catch (error) {
      // math_expressions 對 divide-by-zero 丟出 EvaluationException，其
      // message 通常含 'Division by zero'。
      final message = error.toString();
      if (message.contains('Division by zero') ||
          message.contains('divide by zero')) {
        throw const CalculatorException(
          '不能除以 0',
          type: CalculatorErrorType.divisionByZero,
        );
      }
      throw CalculatorException(
        '算式格式不正確',
        type: CalculatorErrorType.invalidExpression,
      );
    }
  }
}
