import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/calculator_exception.dart';
import '../../../core/math/angle_mode.dart';
import '../model/calculator_state.dart';
import '../model/expression/expression_document.dart';
import '../service/calculator_engine.dart';
import '../service/expression_editor.dart';
import 'calculator_providers.dart';
import '../model/expression/fraction_draft.dart';

class CalculatorViewModel extends Notifier<CalculatorState> {
  late final ExpressionEditor _editor;
  late final CalculatorEngine _engine;

  @override
  CalculatorState build() {
    _editor = ref.read(expressionEditorProvider);
    _engine = ref.read(calculatorEngineProvider);

    return CalculatorState.initial();
  }

  void inputDigit(String digit) {
    _updateDocument(_editor.appendDigit(_activeDocument, digit));
  }

  void inputDecimalPoint() {
    _updateDocument(_editor.appendDecimalPoint(_activeDocument));
  }

  void inputAdd() {
    _inputOperator(evaluationOperator: '+', texOperator: '+');
  }

  void inputSubtract() {
    _inputOperator(evaluationOperator: '-', texOperator: '-');
  }

  void inputMultiply() {
    _inputOperator(evaluationOperator: '*', texOperator: r'\times');
  }

  void inputDivide() {
    _inputOperator(evaluationOperator: '/', texOperator: r'\div');
  }

  void inputOpenParenthesis() {
    _updateDocument(_editor.appendOpenParenthesis(_activeDocument));
  }

  void inputCloseParenthesis() {
    _updateDocument(_editor.appendCloseParenthesis(_activeDocument));
  }

  void inputSquare() {
    _updateDocument(_editor.appendSquare(_activeDocument));
  }

  void inputPower() {
    _updateDocument(_editor.appendPower(_activeDocument));
  }

  void inputSquareRoot() {
    _updateDocument(_editor.appendSquareRoot(_activeDocument));
  }

  void inputSin() {
    _inputFunction(evaluationName: 'sin', texName: r'\sin');
  }

  void inputCos() {
    _inputFunction(evaluationName: 'cos', texName: r'\cos');
  }

  void inputTan() {
    _inputFunction(evaluationName: 'tan', texName: r'\tan');
  }

  void inputLog() {
    _inputFunction(evaluationName: 'log', texName: r'\log');
  }

  void inputLn() {
    _inputFunction(evaluationName: 'ln', texName: r'\ln');
  }

  void inputPi() {
    _updateDocument(
      _editor.appendConstant(
        _activeDocument,
        evaluationValue: 'pi',
        texValue: r'\pi',
      ),
    );
  }

  void inputEulerNumber() {
    _updateDocument(
      _editor.appendConstant(
        _activeDocument,
        evaluationValue: 'e',
        texValue: 'e',
      ),
    );
  }

  void backspace() {
    _updateDocument(_editor.backspace(_activeDocument), preserveResult: true);
  }

  void clear() {
    state = CalculatorState.initial().copyWith(angleMode: state.angleMode);
  }

  void toggleAngleMode() {
    final nextMode = state.angleMode == AngleMode.degree
        ? AngleMode.radian
        : AngleMode.degree;

    state = state.copyWith(angleMode: nextMode, clearError: true);
  }

  void calculate() {
    if (state.fractionDraft != null) {
      if (!state.fractionDraft!.isComplete) {
        state = state.copyWith(errorMessage: '請完成分子和分母', hasEvaluated: false);

        return;
      }

      confirmFraction();
    }

    try {
      final completedDocument = _editor.closePendingGroups(state.document);

      final result = _engine.evaluate(
        completedDocument,
        angleMode: state.angleMode,
      );

      state = state.copyWith(
        document: completedDocument,
        result: result,
        hasEvaluated: true,
        clearError: true,
      );
    } on CalculatorException catch (error) {
      state = state.copyWith(errorMessage: error.message, hasEvaluated: false);
    }
  }

  void _inputOperator({
    required String evaluationOperator,
    required String texOperator,
  }) {
    _updateDocument(
      _editor.appendOperator(
        _activeDocument,
        evaluationOperator: evaluationOperator,
        texOperator: texOperator,
      ),
    );
  }

  void _inputFunction({
    required String evaluationName,
    required String texName,
  }) {
    _updateDocument(
      _editor.appendFunction(
        _activeDocument,
        evaluationName: evaluationName,
        texName: texName,
      ),
    );
  }

  void _updateDocument(
    ExpressionDocument document, {
    bool preserveResult = false,
  }) {
    final draft = state.fractionDraft;

    if (draft != null) {
      state = state.copyWith(
        fractionDraft: draft.updateActiveDocument(document),
        hasEvaluated: false,
        clearResult: !preserveResult,
        clearError: true,
      );

      return;
    }

    state = state.copyWith(
      document: document,
      hasEvaluated: false,
      clearResult: !preserveResult,
      clearError: true,
    );
  }

  ExpressionDocument get _activeDocument {
    return state.fractionDraft?.activeDocument ?? state.document;
  }

  void startFraction() {
    if (state.fractionDraft != null) {
      return;
    }

    state = state.copyWith(
      fractionDraft: FractionDraft.empty(),
      hasEvaluated: false,
      clearResult: true,
      clearError: true,
    );
  }

  void moveFractionUp() {
    final draft = state.fractionDraft;

    if (draft == null) {
      return;
    }

    state = state.copyWith(
      fractionDraft: draft.moveToNumerator(),
      clearError: true,
    );
  }

  void moveFractionDown() {
    final draft = state.fractionDraft;

    if (draft == null) {
      return;
    }

    state = state.copyWith(
      fractionDraft: draft.moveToDenominator(),
      clearError: true,
    );
  }

  void confirmFraction() {
    final draft = state.fractionDraft;

    if (draft == null) {
      return;
    }

    if (draft.numerator.isEmpty) {
      state = state.copyWith(fractionDraft: draft.moveToNumerator());
      return;
    }

    if (draft.denominator.isEmpty) {
      state = state.copyWith(fractionDraft: draft.moveToDenominator());
      return;
    }

    final document = _editor.appendFraction(
      _activeDocument,
      numerator: draft.numerator,
      denominator: draft.denominator,
    );

    state = state.copyWith(
      document: document,
      fractionDraft: null,
      hasEvaluated: false,
      clearResult: true,
      clearError: true,
    );
  }
}
