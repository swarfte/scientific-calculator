import 'dart:math' as math;

import 'package:math_expressions/math_expressions.dart' hide MathFunction;

import '../../../core/math/angle_mode.dart';
import '../model/expression/expression_node.dart';
import '../model/expression/node/constant_node.dart';
import '../model/expression/node/fraction_node.dart';
import '../model/expression/node/function_node.dart';
import '../model/expression/node/group_node.dart';
import '../model/expression/node/number_node.dart';
import '../model/expression/node/operator_node.dart';
import '../model/expression/node/power_node.dart';
import '../model/expression/node/root_node.dart';
import '../model/expression/node/sequence_node.dart';

/// 將 Expression Tree 編譯成 `math_expressions` 的 [Expression]。
///
/// 不把 Tree 轉回字串再交給 `GrammarParser`，而是直接遍歷 Node 建立
/// Expression。Sequence 是線性輸入，Compiler 內建 Pratt parser 以處理
/// operator 優先順序（先乘除後加減）。
///
/// DEG/RAD 由 [AngleMode] 控制：三角函數 argument 在 DEG 模式下乘上
/// `pi / 180`，反三角函數輸出在 DEG 模式下乘上 `180 / pi`。
class ExpressionCompiler {
  const ExpressionCompiler();

  /// 編譯 root sequence。`answer` 為上一個答案（供 [MathConstant.answer] 用）。
  Expression compile(
    SequenceNode root, {
    required AngleMode angleMode,
    double? answer,
  }) {
    final context = _CompileContext(angleMode: angleMode, answer: answer);
    final parser = _PrattParser(context);
    return parser.parseSequence(root);
  }
}

/// 編譯過程共用的狀態。
class _CompileContext {
  _CompileContext({required this.angleMode, this.answer});

  final AngleMode angleMode;
  final double? answer;

  bool get isDegree => angleMode == AngleMode.degree;

  /// 將 trig argument 從顯示單位轉成 radians（供 math_expressions 使用）。
  Expression toRadians(Expression argument) {
    if (!isDegree) {
      return argument;
    }
    // argument * pi / 180
    return Divide(Times(argument, Number(math.pi)), Number(180));
  }

  /// 將反三角函數的 radians 輸出轉回顯示單位。
  Expression fromRadians(Expression radians) {
    if (!isDegree) {
      return radians;
    }
    // radians * 180 / pi
    return Divide(Times(radians, Number(180)), Number(math.pi));
  }
}

/// 以 Sequence children 為 token stream 的 Pratt parser。
///
/// 優先順序：
/// - `+` / `-`（二元）：1
/// - `*` / `/`：2
/// - unary `-`：3
class _PrattParser {
  _PrattParser(this.context);

  final _CompileContext context;
  int _position = 0;

  Expression parseSequence(SequenceNode sequence) {
    // 子 sequence（fraction、group、power 等的 child）會透過 _compileNode
    // 遞迴呼叫此方法；每次呼叫都使用獨立的 position 狀態，避免破壞外層解析
    // 進度。
    final savedPosition = _position;
    _position = 0;
    final children = sequence.children;
    final result = _parseExpression(children);
    _position = savedPosition;
    return result;
  }

  Expression _parseExpression(List<ExpressionNode> children) =>
      _parseBinary(children, 0);

  /// Pratt 主迴圈：不斷讀取優先順序 >= [minPrecedence] 的二元 operator。
  Expression _parseBinary(List<ExpressionNode> children, int minPrecedence) {
    var left = _parseUnary(children);

    while (_position < children.length) {
      final node = children[_position];
      if (node is! OperatorNode) {
        break;
      }
      final precedence = _binaryPrecedence(node.operator);
      if (precedence < minPrecedence) {
        break;
      }
      _position++; // 消耗 operator
      final right = _parseBinary(children, precedence + 1);
      left = _combine(node.operator, left, right);
    }

    return left;
  }

  /// 處理 unary 負號與 primary（數字、常數、composite node）。
  Expression _parseUnary(List<ExpressionNode> children) {
    if (_position < children.length) {
      final node = children[_position];
      if (node is OperatorNode &&
          node.operator == ExpressionOperator.subtract) {
        _position++;
        final operand = _parseUnary(children);
        return UnaryMinus(operand);
      }
    }
    return _parsePrimary(children);
  }

  Expression _parsePrimary(List<ExpressionNode> children) {
    final node = children[_position];
    _position++;
    return _compileNode(node);
  }

  Expression _combine(
    ExpressionOperator operator,
    Expression left,
    Expression right,
  ) {
    switch (operator) {
      case ExpressionOperator.add:
        return Plus(left, right);
      case ExpressionOperator.subtract:
        return Minus(left, right);
      case ExpressionOperator.multiply:
        return Times(left, right);
      case ExpressionOperator.divide:
        return Divide(left, right);
    }
  }

  int _binaryPrecedence(ExpressionOperator operator) {
    switch (operator) {
      case ExpressionOperator.add:
      case ExpressionOperator.subtract:
        return 1;
      case ExpressionOperator.multiply:
      case ExpressionOperator.divide:
        return 2;
    }
  }

  Expression _compileNode(ExpressionNode node) {
    switch (node) {
      case NumberNode():
        return Number(num.parse(node.value));
      case ConstantNode():
        return _compileConstant(node);
      case OperatorNode():
        // 不應在 primary 出現；防禦性回傳 0。
        return Number(0);
      case FunctionNode():
        return _compileFunction(node);
      case FractionNode():
        return Divide(
          parseSequence(node.numerator),
          parseSequence(node.denominator),
        );
      case RootNode():
        return _compileRoot(node);
      case PowerNode():
        return Power(parseSequence(node.base), parseSequence(node.exponent));
      case GroupNode():
        return parseSequence(node.content);
      case SequenceNode():
        return parseSequence(node);
      default:
        // 未來新增的 node 型別防禦性回傳 0。
        return Number(0);
    }
  }

  Expression _compileConstant(ConstantNode node) {
    switch (node.constant) {
      case MathConstant.pi:
        return Number(math.pi);
      case MathConstant.e:
        return Number(math.e);
      case MathConstant.answer:
        return Number(context.answer ?? 0);
    }
  }

  Expression _compileFunction(FunctionNode node) {
    final argument = parseSequence(node.argument);
    switch (node.function) {
      case MathFunction.sin:
        return Sin(context.toRadians(argument));
      case MathFunction.cos:
        return Cos(context.toRadians(argument));
      case MathFunction.tan:
        return Tan(context.toRadians(argument));
      case MathFunction.asin:
        return context.fromRadians(Asin(argument));
      case MathFunction.acos:
        return context.fromRadians(Acos(argument));
      case MathFunction.atan:
        return context.fromRadians(Atan(argument));
      case MathFunction.log10:
        // log10(x) = ln(x) / ln(10)
        return Divide(Ln(argument), Ln(Number(10)));
      case MathFunction.ln:
        return Ln(argument);
      case MathFunction.absolute:
        return Abs(argument);
    }
  }

  Expression _compileRoot(RootNode node) {
    final radicand = parseSequence(node.radicand);
    final degree = node.degree;
    if (degree == null) {
      return Sqrt(radicand);
    }
    // n 次根 = radicand ^ (1 / degree)
    final degreeExpr = parseSequence(degree);
    return Power(radicand, Divide(Number(1), degreeExpr));
  }
}
