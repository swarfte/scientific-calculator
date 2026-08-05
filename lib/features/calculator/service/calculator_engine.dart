import '../../../core/math/angle_mode.dart';
import '../../../core/math/result_formatter.dart';
import '../model/calculation_result.dart';
import '../model/expression/expression_document.dart';
import 'expression_editor.dart';
import 'expression_evaluator.dart';

class CalculatorEngine {
  const CalculatorEngine({required this.evaluator, required this.editor});

  final ExpressionEvaluator evaluator;
  final ExpressionEditor editor;

  CalculationResult evaluate(
    ExpressionDocument document, {
    required AngleMode angleMode,
  }) {
    final completedDocument = editor.closePendingGroups(document);

    var expression = completedDocument.evaluationExpression;

    if (expression.endsWith('^')) {
      expression += '1';
    }

    final value = evaluator.evaluate(expression, angleMode: angleMode);

    return CalculationResult(
      value: value,
      formattedValue: ResultFormatter.format(value),
    );
  }
}
