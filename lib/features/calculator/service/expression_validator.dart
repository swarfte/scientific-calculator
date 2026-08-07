import '../../../core/errors/calculator_exception.dart';
import '../model/expression/expression_node.dart';
import '../model/expression/node/constant_node.dart';
import '../model/expression/node/fraction_node.dart';
import '../model/expression/node/function_node.dart';
import '../model/expression/node/group_node.dart';
import '../model/expression/node/logarithm_node.dart';
import '../model/expression/node/mixed_fraction_node.dart';
import '../model/expression/node/number_node.dart';
import '../model/expression/node/operator_node.dart';
import '../model/expression/node/power_node.dart';
import '../model/expression/node/root_node.dart';
import '../model/expression/node/scientific_node.dart';
import '../model/expression/node/sequence_node.dart';
import '../model/expression/validation_failure.dart';

/// Expression Tree 的驗證器。
///
/// 遍歷 Tree 檢查算式是否完整可計算，回傳第一個 [ValidationFailure] 或
/// `null`（表示通過）。不 throw parser exception，讓 Engine 與 UI 能取得
/// 錯誤型別與位置。
class ExpressionValidator {
  const ExpressionValidator();

  /// `hasAnswer` 為 `false` 時，使用 [MathConstant.answer] 會被視為未定義。
  ValidationFailure? validate(SequenceNode root, {bool hasAnswer = true}) {
    if (root.isEmpty) {
      return ValidationFailure(
        type: CalculatorErrorType.emptyExpression,
        message: '請先輸入算式',
        sequenceId: root.id,
      );
    }

    return _validateSequence(root, hasAnswer: hasAnswer);
  }

  ValidationFailure? _validateSequence(
    SequenceNode sequence, {
    required bool hasAnswer,
  }) {
    for (var i = 0; i < sequence.children.length; i++) {
      final child = sequence.children[i];
      final previous = i > 0 ? sequence.children[i - 1] : null;

      switch (child) {
        case NumberNode():
          if (child.value.isEmpty || child.value == '.') {
            return ValidationFailure(
              type: CalculatorErrorType.invalidExpression,
              message: '數字格式不正確',
              nodeId: child.id,
            );
          }
        case OperatorNode():
          final failure = _validateOperator(child, previous);
          if (failure != null) {
            return failure;
          }
        case ConstantNode():
          if (child.constant == MathConstant.answer && !hasAnswer) {
            return ValidationFailure(
              type: CalculatorErrorType.undefinedAnswer,
              message: '尚無上一個答案可使用',
              nodeId: child.id,
            );
          }
        case FunctionNode():
          final failure = _validateComposite(
            child,
            child.argument,
            argumentName: '函數內容',
            hasAnswer: hasAnswer,
          );
          if (failure != null) {
            return failure;
          }
        case FractionNode():
          final failure = _validateRequiredSequence(
            child.numerator,
            argumentName: '分子',
            hasAnswer: hasAnswer,
          );
          if (failure != null) {
            return failure;
          }
          final denomFailure = _validateRequiredSequence(
            child.denominator,
            argumentName: '分母',
            hasAnswer: hasAnswer,
          );
          if (denomFailure != null) {
            return denomFailure;
          }
        case RootNode():
          final degree = child.degree;
          if (degree != null) {
            final degFailure = _validateRequiredSequence(
              degree,
              argumentName: '根號次數',
              hasAnswer: hasAnswer,
            );
            if (degFailure != null) {
              return degFailure;
            }
          }
          final radFailure = _validateRequiredSequence(
            child.radicand,
            argumentName: '根號內容',
            hasAnswer: hasAnswer,
          );
          if (radFailure != null) {
            return radFailure;
          }
        case PowerNode():
          final baseFailure = _validateRequiredSequence(
            child.base,
            argumentName: '底數',
            hasAnswer: hasAnswer,
          );
          if (baseFailure != null) {
            return baseFailure;
          }
          final expFailure = _validateRequiredSequence(
            child.exponent,
            argumentName: '指數',
            hasAnswer: hasAnswer,
          );
          if (expFailure != null) {
            return expFailure;
          }
        case LogarithmNode():
          final baseFailure = _validateRequiredSequence(
            child.base,
            argumentName: '對數底數',
            hasAnswer: hasAnswer,
          );
          if (baseFailure != null) {
            return baseFailure;
          }
          final argFailure = _validateRequiredSequence(
            child.argument,
            argumentName: '對數內容',
            hasAnswer: hasAnswer,
          );
          if (argFailure != null) {
            return argFailure;
          }
        case MixedFractionNode():
          final wholeFailure = _validateRequiredSequence(
            child.whole,
            argumentName: '帶分數整數部分',
            hasAnswer: hasAnswer,
          );
          if (wholeFailure != null) {
            return wholeFailure;
          }
          final numFailure = _validateRequiredSequence(
            child.numerator,
            argumentName: '帶分數分子',
            hasAnswer: hasAnswer,
          );
          if (numFailure != null) {
            return numFailure;
          }
          final denomFailure = _validateRequiredSequence(
            child.denominator,
            argumentName: '帶分數分母',
            hasAnswer: hasAnswer,
          );
          if (denomFailure != null) {
            return denomFailure;
          }
        case ScientificNode():
          final mantissaFailure = _validateRequiredSequence(
            child.mantissa,
            argumentName: '科學記號尾數',
            hasAnswer: hasAnswer,
          );
          if (mantissaFailure != null) {
            return mantissaFailure;
          }
          final expFailure = _validateRequiredSequence(
            child.exponent,
            argumentName: '科學記號指數',
            hasAnswer: hasAnswer,
          );
          if (expFailure != null) {
            return expFailure;
          }
        case GroupNode():
          final failure = _validateComposite(
            child,
            child.content,
            argumentName: '括號內容',
            hasAnswer: hasAnswer,
          );
          if (failure != null) {
            return failure;
          }
        case SequenceNode():
          // child 不應是 sequence；防禦性跳過。
          break;
      }
    }

    // Sequence 不可以 operator 結尾。
    if (sequence.children.isNotEmpty) {
      final last = sequence.children.last;
      if (last is OperatorNode) {
        return ValidationFailure(
          type: CalculatorErrorType.invalidExpression,
          message: '算式不能以運算符結尾',
          nodeId: last.id,
        );
      }
    }

    return null;
  }

  /// 驗證 operator 是否合法（非法連續 operator）。
  ValidationFailure? _validateOperator(
    OperatorNode operator,
    ExpressionNode? previous,
  ) {
    if (previous is OperatorNode) {
      // 允許 * 或 / 後接 -（例如 3*-2）。
      final allowsConsecutiveMinus =
          (previous.operator == ExpressionOperator.multiply ||
              previous.operator == ExpressionOperator.divide) &&
          operator.operator == ExpressionOperator.subtract;
      if (!allowsConsecutiveMinus) {
        return ValidationFailure(
          type: CalculatorErrorType.invalidExpression,
          message: '運算符不能連續輸入',
          nodeId: operator.id,
        );
      }
    }
    return null;
  }

  /// 驗證 composite node 的單一 child sequence 非空，並遞迴驗證內容。
  ValidationFailure? _validateComposite(
    ExpressionNode owner,
    SequenceNode child, {
    required String argumentName,
    required bool hasAnswer,
  }) {
    return _validateRequiredSequence(
      child,
      argumentName: argumentName,
      hasAnswer: hasAnswer,
    );
  }

  /// 驗證 child sequence 非空，再遞迴驗證內容。
  ValidationFailure? _validateRequiredSequence(
    SequenceNode child, {
    required String argumentName,
    required bool hasAnswer,
  }) {
    if (child.isEmpty) {
      return ValidationFailure(
        type: CalculatorErrorType.invalidExpression,
        message: '$argumentName不可為空',
        sequenceId: child.id,
      );
    }
    return _validateSequence(child, hasAnswer: hasAnswer);
  }
}
