import '../../../app/result_format_settings.dart';
import '../../../core/errors/calculator_exception.dart';
import '../../../core/math/angle_mode.dart';
import '../../../core/math/result_formatter.dart';
import '../model/calculation_result.dart';
import '../model/expression/node/sequence_node.dart';
import '../model/expression/validation_failure.dart';
import 'exact_math/exact_value_evaluator.dart';
import 'exact_math/exact_value_formatter.dart';
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
    this.exactFormatter = const ExactValueFormatter(),
  });

  final ExpressionValidator validator;
  final ExpressionCompiler compiler;
  final TreeExpressionEvaluator evaluator;
  final ExactValueFormatter exactFormatter;

  /// 求值 [root] Tree。
  ///
  /// [answer] 為上一個答案，供 `Ans` 常數使用；`null` 表示尚無答案。
  /// [resultFormat] 控制顯示格式：[ResultFormatPreference.fraction] 時會嘗試
  /// 以最簡分數／帶分數／根式（TeX）表示結果，無法精確化簡時 [formattedTex]
  /// 為 `null`，由 UI 退回小數顯示。數值 [CalculationResult.value] 恆為小數
  /// `double`，使 `Ans` 在兩種模式下保持一致。
  ///
  /// 拋出 [CalculatorException]（含 domain error 型別）供 ViewModel 放入
  /// ResultDisplay。
  CalculationResult evaluate(
    SequenceNode root, {
    required AngleMode angleMode,
    double? answer,
    ResultFormatPreference resultFormat = ResultFormatPreference.decimal,
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
      formattedTex: _tryExactTex(root, answer: answer, resultFormat: resultFormat),
    );
  }

  /// 在「分數」模式下嘗試以 [ExactValueEvaluator] 精確求值並格式化為 TeX；
  /// 失敗（或非分數模式）回傳 `null`。
  String? _tryExactTex(
    SequenceNode root, {
    double? answer,
    required ResultFormatPreference resultFormat,
  }) {
    if (resultFormat != ResultFormatPreference.fraction) {
      return null;
    }
    final evaluated = ExactValueEvaluator(answer: answer).evaluate(root);
    if (evaluated == null) {
      return null;
    }
    return exactFormatter.format(evaluated);
  }

  CalculatorException _toException(ValidationFailure failure) {
    return CalculatorException(failure.message, type: failure.type);
  }
}
