import '../../model/expression/expression_node.dart';
import '../../model/expression/node/constant_node.dart';
import '../../model/expression/node/fraction_node.dart';
import '../../model/expression/node/function_node.dart';
import '../../model/expression/node/group_node.dart';
import '../../model/expression/node/number_node.dart';
import '../../model/expression/node/operator_node.dart';
import '../../model/expression/node/power_node.dart';
import '../../model/expression/node/root_node.dart';
import '../../model/expression/node/sequence_node.dart';
import 'exact_number.dart';
import 'rational.dart';

/// 以 [ExactNumber]（根式和）精確求值 Expression Tree。
///
/// 與 [ExpressionCompiler]（Pratt parser）使用相同的優先順序與結構，差別在於
/// 算術改為 [ExactNumber]（[BigInt] 有理數 + 根式）。任何無法精確表示的節點
/// （三角／指對數函數、π、e、n 次根、非整數次方、負數開根號…）會回傳 `null`，
/// 由呼叫端 fallback 到 decimal 路徑。
///
/// `answer`（`Ans` 常數）僅在它本身為整數時可精確參與；否則回傳 `null`。
class ExactValueEvaluator {
  const ExactValueEvaluator({this.answer});

  /// 上一個答案，供 [MathConstant.answer] 使用；`null` 表示無答案。
  final double? answer;

  /// 求值 [root]。回傳 `null` 表示無法精確表示。
  ExactNumber? evaluate(SequenceNode root) {
    final parser = _ExactParser(this);
    return parser.parseSequence(root);
  }
}

/// 以 Sequence children 為 token stream 的 Pratt parser（exact 版本）。
///
/// 優先順序與 [ExpressionCompiler] 的 `_PrattParser` 一致：
/// - `+` / `-`（二元）：1
/// - `*` / `/`：2
/// - unary `-`：3
class _ExactParser {
  _ExactParser(this.evaluator);

  final ExactValueEvaluator evaluator;
  int _position = 0;

  ExactNumber? parseSequence(SequenceNode sequence) {
    final savedPosition = _position;
    _position = 0;
    final children = sequence.children;
    if (children.isEmpty) {
      // 空 sequence 視為 0（與 decimal 路徑一致：Validator 會攔截大部分空結構）。
      _position = savedPosition;
      return ExactNumber.zero;
    }
    final result = _parseExpression(children);
    final consumedAll = _position == children.length;
    _position = savedPosition;
    // 若解析未耗盡所有 children（結構異常），視為無法求值；交由 decimal 處理。
    if (result == null || !consumedAll) {
      return null;
    }
    return result;
  }

  ExactNumber? _parseExpression(List<ExpressionNode> children) =>
      _parseBinary(children, 0);

  ExactNumber? _parseBinary(List<ExpressionNode> children, int minPrecedence) {
    final initial = _parseUnary(children);
    if (initial == null) return null;
    var left = initial;

    while (_position < children.length) {
      final node = children[_position];
      if (node is! OperatorNode) break;
      final precedence = _binaryPrecedence(node.operator);
      if (precedence < minPrecedence) break;
      _position++;
      final right = _parseBinary(children, precedence + 1);
      if (right == null) return null;
      final combined = _combine(node.operator, left, right);
      if (combined == null) return null;
      left = combined;
    }
    return left;
  }

  ExactNumber? _parseUnary(List<ExpressionNode> children) {
    if (_position < children.length) {
      final node = children[_position];
      if (node is OperatorNode &&
          node.operator == ExpressionOperator.subtract) {
        _position++;
        final operand = _parseUnary(children);
        if (operand == null) return null;
        return -operand;
      }
    }
    return _parsePrimary(children);
  }

  ExactNumber? _parsePrimary(List<ExpressionNode> children) {
    if (_position >= children.length) return null;
    final node = children[_position];
    _position++;
    return _compileNode(node);
  }

  ExactNumber? _combine(
    ExpressionOperator operator,
    ExactNumber left,
    ExactNumber right,
  ) {
    switch (operator) {
      case ExpressionOperator.add:
        return left + right;
      case ExpressionOperator.subtract:
        return left - right;
      case ExpressionOperator.multiply:
        return left * right;
      case ExpressionOperator.divide:
        return left.divide(right);
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

  ExactNumber? _compileNode(ExpressionNode node) {
    switch (node) {
      case NumberNode():
        return _compileNumber(node);
      case ConstantNode():
        return _compileConstant(node);
      case OperatorNode():
        // primary 不應出現 operator；視為無法求值。
        return null;
      case FunctionNode():
        // 所有函數（三角、log、ln、abs）皆非代數精確可表示。
        return null;
      case FractionNode():
        final numerator = parseSequence(node.numerator);
        final denominator = parseSequence(node.denominator);
        if (numerator == null || denominator == null) return null;
        return numerator.divide(denominator); // divide 回傳 null 時自動傳播。
      case RootNode():
        return _compileRoot(node);
      case PowerNode():
        return _compilePower(node);
      case GroupNode():
        return parseSequence(node.content);
      case SequenceNode():
        return parseSequence(node);
      default:
        return null;
    }
  }

  ExactNumber? _compileNumber(NumberNode node) {
    if (!node.isComplete) return null;
    try {
      final rational = Rational.fromDecimalString(node.value);
      return ExactNumber.rational(rational);
    } on FormatException {
      return null;
    }
  }

  ExactNumber? _compileConstant(ConstantNode node) {
    switch (node.constant) {
      case MathConstant.pi:
      case MathConstant.e:
        // 超越常數無法以根式精確表示。
        return null;
      case MathConstant.answer:
        // Ans 僅在整數時可精確參與。
        final value = evaluator.answer;
        if (value == null) return null;
        if (value == value.roundToDouble()) {
          return ExactNumber.fromInt(value.round());
        }
        return null;
    }
  }

  ExactNumber? _compileRoot(RootNode node) {
    // n 次根（degree 已設定）目前不支援精確表示，fallback。
    if (node.degree != null) {
      return null;
    }
    final radicand = parseSequence(node.radicand);
    if (radicand == null) return null;
    return _sqrt(radicand);
  }

  /// 對一個 [ExactNumber] 取平方根。
  ///
  /// 僅在 radicand 為純有理數時有意義：`√(a + b√c)` 一般無法化簡，回傳 `null`。
  ExactNumber? _sqrt(ExactNumber value) {
    if (!value.isRational) {
      return null;
    }
    return sqrtOfRational(value.rationalPart);
  }

  ExactNumber? _compilePower(PowerNode node) {
    final base = parseSequence(node.base);
    final exponent = parseSequence(node.exponent);
    if (base == null || exponent == null) return null;
    if (!exponent.isRational) return null;
    final expRational = exponent.rationalPart;
    if (!expRational.isInteger) {
      // 非整數次方（含 x^(1/2)）目前不嘗試代數化簡；使用者可用 √ 鍵。
      return null;
    }
    final n = expRational.truncateToBigInt();
    if (n >= BigInt.zero) {
      final ni = n.toInt();
      if (ni < 0 || BigInt.from(ni) != n) {
        // 超過 int 範圍的指數，fallback。
        return null;
      }
      return base.pow(ni);
    }
    // 負整數次方：先取倒數再取次方。
    if (n == BigInt.from(-1)) {
      return base.reciprocal();
    }
    final absExp = (-n).toInt();
    if (absExp < 0 || BigInt.from(absExp) != -n) return null;
    final reciprocal = base.reciprocal();
    if (reciprocal == null) return null;
    return reciprocal.pow(absExp);
  }
}
