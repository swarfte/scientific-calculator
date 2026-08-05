import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/calculator_exception.dart';
import '../../../core/math/angle_mode.dart';
import '../model/calculator_state.dart';
import '../model/expression/expression_document.dart';
import '../service/calculator_engine.dart';
import '../service/expression_editor.dart';
import 'calculator_providers.dart';

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
    _updateDocument(_editor.appendDigit(state.document, digit));
  }

  void inputDecimalPoint() {
    _updateDocument(_editor.appendDecimalPoint(state.document));
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
    _updateDocument(_editor.appendOpenParenthesis(state.document));
  }

  void inputCloseParenthesis() {
    _updateDocument(_editor.appendCloseParenthesis(state.document));
  }

  void inputSquare() {
    _updateDocument(_editor.appendSquare(state.document));
  }

  void inputPower() {
    _updateDocument(_editor.appendPower(state.document));
  }

  void inputSquareRoot() {
    _updateDocument(_editor.appendSquareRoot(state.document));
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
        state.document,
        evaluationValue: 'pi',
        texValue: r'\pi',
      ),
    );
  }

  void inputEulerNumber() {
    _updateDocument(
      _editor.appendConstant(
        state.document,
        evaluationValue: 'e',
        texValue: 'e',
      ),
    );
  }

  void backspace() {
    _updateDocument(_editor.backspace(state.document), preserveResult: true);
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
        state.document,
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
        state.document,
        evaluationName: evaluationName,
        texName: texName,
      ),
    );
  }

  void _updateDocument(
    ExpressionDocument document, {
    bool preserveResult = false,
  }) {
    state = state.copyWith(
      document: document,
      hasEvaluated: false,
      clearResult: !preserveResult,
      clearError: true,
    );
  }
}
