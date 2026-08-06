import '../../../core/errors/calculator_exception.dart';
import '../../../core/math/angle_mode.dart';
import '../../../core/math/result_formatter.dart';
import '../model/calculation_result.dart';
import '../model/expression/node/sequence_node.dart';
import '../model/expression/validation_failure.dart';
import 'expression_compiler.dart';
import 'expression_validator.dart';
import 'tree_expression_evaluator.dart';

/// Tree 版本的計算引擎，協調 validation -> compilation -> evaluation ->
/// formatting。
///
/// 完全以 [SequenceNode]（Expression Tree root）作為輸入，不依賴 evaluation
/// string 或 UI TeX。按 `=` 時依計劃執行：
///
/// ```text
/// ExpressionValidator -> ExpressionCompiler -> TreeExpressionEvaluator
/// -> ResultFormatter -> CalculationResult
/// ```
///
/// 待 Phase 6 切換後，取代舊字串版 `calculator_engine.dart`。
class TreeCalculatorEngine {
  const TreeCalculatorEngine({
    this.validator = const ExpressionValidator(),
    this.compiler = const ExpressionCompiler(),
    this.evaluator = const TreeExpressionEvaluator(),
  });

  final ExpressionValidator validator;
  final ExpressionCompiler compiler;
  final TreeExpressionEvaluator evaluator;

  /// 求值 [root] Tree。
  ///
  /// [answer] 為上一個答案，供 `Ans` 常數使用；`null` 表示尚無答案。
  ///
  /// 拋出 [CalculatorException]（含 domain error 型別）供 ViewModel 放入
  /// ResultDisplay。
  CalculationResult evaluate(
    SequenceNode root, {
    required AngleMode angleMode,
    double? answer,
  }) {
    final failure = validator.validate(root, hasAnswer: answer != null);
    if (failure != null) {
      throw _toException(failure);
    }

    final expression = compiler.compile(
      root,
      angleMode: angleMode,
      answer: answer,
    );

    final value = evaluator.evaluate(expression);

    return CalculationResult(
      value: value,
      formattedValue: ResultFormatter.format(value),
    );
  }

  CalculatorException _toException(ValidationFailure failure) {
    return CalculatorException(failure.message, type: failure.type);
  }
}
