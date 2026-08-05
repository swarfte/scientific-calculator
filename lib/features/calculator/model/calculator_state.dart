import '../../../../core/math/angle_mode.dart';
import 'calculation_result.dart';
import 'expression/expression_document.dart';
import 'expression/fraction_draft.dart';

const Object _notSpecified = Object();

class CalculatorState {
  const CalculatorState({
    required this.document,
    this.result,
    this.fractionDraft,
    this.angleMode = AngleMode.degree,
    this.errorMessage,
    this.hasEvaluated = false,
  });

  final ExpressionDocument document;
  final CalculationResult? result;
  final FractionDraft? fractionDraft;
  final AngleMode angleMode;
  final String? errorMessage;
  final bool hasEvaluated;

  bool get isEditingFraction => fractionDraft != null;

  factory CalculatorState.initial() {
    return CalculatorState(document: ExpressionDocument.empty());
  }

  CalculatorState copyWith({
    ExpressionDocument? document,
    CalculationResult? result,
    Object? fractionDraft = _notSpecified,
    AngleMode? angleMode,
    String? errorMessage,
    bool? hasEvaluated,
    bool clearResult = false,
    bool clearError = false,
  }) {
    return CalculatorState(
      document: document ?? this.document,
      result: clearResult ? null : result ?? this.result,
      fractionDraft: identical(fractionDraft, _notSpecified)
          ? this.fractionDraft
          : fractionDraft as FractionDraft?,
      angleMode: angleMode ?? this.angleMode,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      hasEvaluated: hasEvaluated ?? this.hasEvaluated,
    );
  }
}
