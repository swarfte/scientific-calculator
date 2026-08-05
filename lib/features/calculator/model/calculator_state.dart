import '../../../../core/math/angle_mode.dart';
import 'calculation_result.dart';
import 'expression/expression_document.dart';

class CalculatorState {
  const CalculatorState({
    required this.document,
    this.result,
    this.angleMode = AngleMode.degree,
    this.errorMessage,
    this.hasEvaluated = false,
  });

  final ExpressionDocument document;
  final CalculationResult? result;
  final AngleMode angleMode;
  final String? errorMessage;
  final bool hasEvaluated;

  factory CalculatorState.initial() {
    return CalculatorState(document: ExpressionDocument.empty());
  }

  CalculatorState copyWith({
    ExpressionDocument? document,
    CalculationResult? result,
    AngleMode? angleMode,
    String? errorMessage,
    bool? hasEvaluated,
    bool clearResult = false,
    bool clearError = false,
  }) {
    return CalculatorState(
      document: document ?? this.document,
      result: clearResult ? null : result ?? this.result,
      angleMode: angleMode ?? this.angleMode,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      hasEvaluated: hasEvaluated ?? this.hasEvaluated,
    );
  }
}
