import 'package:flutter_test/flutter_test.dart';
import 'package:scientific_calculator/core/errors/calculator_exception.dart';
import 'package:scientific_calculator/core/math/angle_mode.dart';
import 'package:scientific_calculator/features/calculator/model/expression/expression_node.dart';
import 'package:scientific_calculator/features/calculator/model/expression/node/constant_node.dart';
import 'package:scientific_calculator/features/calculator/model/expression/node/fraction_node.dart';
import 'package:scientific_calculator/features/calculator/model/expression/node/function_node.dart';
import 'package:scientific_calculator/features/calculator/model/expression/node/group_node.dart';
import 'package:scientific_calculator/features/calculator/model/expression/node/number_node.dart';
import 'package:scientific_calculator/features/calculator/model/expression/node/operator_node.dart';
import 'package:scientific_calculator/features/calculator/model/expression/node/power_node.dart';
import 'package:scientific_calculator/features/calculator/model/expression/node/root_node.dart';
import 'package:scientific_calculator/features/calculator/model/expression/node/sequence_node.dart';
import 'package:scientific_calculator/features/calculator/model/expression/node_id.dart';
import 'package:scientific_calculator/features/calculator/service/tree_calculator_engine.dart';

/// Phase 5 engine 整合測試：Tree -> Validator -> Compiler -> Evaluator ->
/// ResultFormatter。
///
/// 驗證計劃必測案例，浮點使用 tolerance 比較。
void main() {
  const engine = TreeCalculatorEngine();

  /// 便利 builder：以 List<ExpressionNode> 建立 root sequence。
  SequenceNode seq(List<ExpressionNode> children) =>
      SequenceNode(id: NodeId.generate(), children: children);

  /// 浮點近似比對。
  void expectClose(num actual, num expected, {double tolerance = 1e-9}) {
    expect((actual - expected).abs(), lessThan(tolerance));
  }

  group('operator precedence and groups', () {
    test('2 + 3 * 4 -> 14', () {
      final root = seq([
        NumberNode.create('2'),
        OperatorNode.create(ExpressionOperator.add),
        NumberNode.create('3'),
        OperatorNode.create(ExpressionOperator.multiply),
        NumberNode.create('4'),
      ]);
      expect(engine.evaluate(root, angleMode: AngleMode.degree).value, 14);
    });

    test('(2 + 3) * 4 -> 20', () {
      final group = GroupNode(
        id: NodeId.generate(),
        content: seq([
          NumberNode.create('2'),
          OperatorNode.create(ExpressionOperator.add),
          NumberNode.create('3'),
        ]),
      );
      final root = seq([
        group,
        OperatorNode.create(ExpressionOperator.multiply),
        NumberNode.create('4'),
      ]);
      expect(engine.evaluate(root, angleMode: AngleMode.degree).value, 20);
    });
  });

  group('power and root', () {
    test('5^2 -> 25', () {
      final power = PowerNode(
        id: NodeId.generate(),
        base: seq([NumberNode.create('5')]),
        exponent: seq([NumberNode.create('2')]),
      );
      final root = seq([power]);
      expect(engine.evaluate(root, angleMode: AngleMode.degree).value, 25);
    });

    test('sqrt(9) -> 3', () {
      final rootSeq = seq([
        RootNode(
          id: NodeId.generate(),
          radicand: seq([NumberNode.create('9')]),
        ),
      ]);
      expect(engine.evaluate(rootSeq, angleMode: AngleMode.degree).value, 3);
    });

    test('sqrt(2)/sqrt(3) -> approximately 0.8164965809', () {
      final frac = FractionNode(
        id: NodeId.generate(),
        numerator: seq([
          RootNode(
            id: NodeId.generate(),
            radicand: seq([NumberNode.create('2')]),
          ),
        ]),
        denominator: seq([
          RootNode(
            id: NodeId.generate(),
            radicand: seq([NumberNode.create('3')]),
          ),
        ]),
      );
      final root = seq([frac]);
      expectClose(
        engine.evaluate(root, angleMode: AngleMode.degree).value,
        0.816496580927726,
      );
    });

    test('nth root cuberoot(8) -> 2', () {
      final root = seq([
        RootNode(
          id: NodeId.generate(),
          radicand: seq([NumberNode.create('8')]),
          degree: seq([NumberNode.create('3')]),
        ),
      ]);
      expect(engine.evaluate(root, angleMode: AngleMode.degree).value, 2);
    });
  });

  group('trig DEG/RAD', () {
    test('sin(30 DEG) -> approximately 0.5', () {
      final root = seq([
        FunctionNode(
          id: NodeId.generate(),
          function: MathFunction.sin,
          argument: seq([NumberNode.create('30')]),
        ),
      ]);
      expectClose(
        engine.evaluate(root, angleMode: AngleMode.degree).value,
        0.5,
      );
    });

    test('sin(pi/2 RAD) -> approximately 1', () {
      final group = GroupNode(
        id: NodeId.generate(),
        content: seq([
          ConstantNode.create(MathConstant.pi),
          OperatorNode.create(ExpressionOperator.divide),
          NumberNode.create('2'),
        ]),
      );
      final root = seq([
        FunctionNode(
          id: NodeId.generate(),
          function: MathFunction.sin,
          argument: seq([group]),
        ),
      ]);
      expectClose(engine.evaluate(root, angleMode: AngleMode.radian).value, 1);
    });

    test('cos(60 DEG) -> approximately 0.5', () {
      final root = seq([
        FunctionNode(
          id: NodeId.generate(),
          function: MathFunction.cos,
          argument: seq([NumberNode.create('60')]),
        ),
      ]);
      expectClose(
        engine.evaluate(root, angleMode: AngleMode.degree).value,
        0.5,
      );
    });

    test('tan(45 DEG) -> approximately 1', () {
      final root = seq([
        FunctionNode(
          id: NodeId.generate(),
          function: MathFunction.tan,
          argument: seq([NumberNode.create('45')]),
        ),
      ]);
      expectClose(
        engine.evaluate(root, angleMode: AngleMode.degree).value,
        1,
        tolerance: 1e-9,
      );
    });

    test('DEG/RAD 對巢狀 argument 仍正確（sin(sqrt(36) DEG) -> ~0.5）', () {
      // sin( sqrt(36) ) = sin(6°) in DEG ≈ 0.1045
      final root = seq([
        FunctionNode(
          id: NodeId.generate(),
          function: MathFunction.sin,
          argument: seq([
            RootNode(
              id: NodeId.generate(),
              radicand: seq([NumberNode.create('36')]),
            ),
          ]),
        ),
      ]);
      // sin(6°) ≈ 0.104528
      expectClose(
        engine.evaluate(root, angleMode: AngleMode.degree).value,
        0.10452846326765347,
      );
    });
  });

  group('log and constants', () {
    test('log10(100) -> 2', () {
      final root = seq([
        FunctionNode(
          id: NodeId.generate(),
          function: MathFunction.log10,
          argument: seq([NumberNode.create('100')]),
        ),
      ]);
      expectClose(engine.evaluate(root, angleMode: AngleMode.degree).value, 2);
    });

    test('ln(e) -> 1', () {
      final root = seq([
        FunctionNode(
          id: NodeId.generate(),
          function: MathFunction.ln,
          argument: seq([ConstantNode.create(MathConstant.e)]),
        ),
      ]);
      expectClose(engine.evaluate(root, angleMode: AngleMode.degree).value, 1);
    });

    test('Ans 常數使用上一個答案', () {
      final root = seq([ConstantNode.create(MathConstant.answer)]);
      final result = engine.evaluate(
        root,
        angleMode: AngleMode.degree,
        answer: 42,
      );
      expect(result.value, 42);
    });
  });

  group('error cases', () {
    test('1 / 0 -> divisionByZero 或 overflow（IEEE 除法回傳 infinity）', () {
      final root = seq([
        NumberNode.create('1'),
        OperatorNode.create(ExpressionOperator.divide),
        NumberNode.create('0'),
      ]);
      expect(
        () => engine.evaluate(root, angleMode: AngleMode.degree),
        throwsA(
          isA<CalculatorException>().having(
            (e) => e.type,
            'type',
            anyOf(
              CalculatorErrorType.divisionByZero,
              CalculatorErrorType.overflow,
            ),
          ),
        ),
      );
    });

    test('sqrt(-1) -> domainError', () {
      final root = seq([
        RootNode(
          id: NodeId.generate(),
          radicand: seq([
            OperatorNode.create(ExpressionOperator.subtract),
            NumberNode.create('1'),
          ]),
        ),
      ]);
      expect(
        () => engine.evaluate(root, angleMode: AngleMode.degree),
        throwsA(
          isA<CalculatorException>().having(
            (e) => e.type,
            'type',
            CalculatorErrorType.domainError,
          ),
        ),
      );
    });

    test('log10(0) -> domainError 或 overflow（IEEE log(0) = -infinity）', () {
      final root = seq([
        FunctionNode(
          id: NodeId.generate(),
          function: MathFunction.log10,
          argument: seq([NumberNode.create('0')]),
        ),
      ]);
      expect(
        () => engine.evaluate(root, angleMode: AngleMode.degree),
        throwsA(
          isA<CalculatorException>().having(
            (e) => e.type,
            'type',
            anyOf(
              CalculatorErrorType.domainError,
              CalculatorErrorType.overflow,
            ),
          ),
        ),
      );
    });

    test('ln(-1) -> domainError', () {
      final root = seq([
        FunctionNode(
          id: NodeId.generate(),
          function: MathFunction.ln,
          argument: seq([
            OperatorNode.create(ExpressionOperator.subtract),
            NumberNode.create('1'),
          ]),
        ),
      ]);
      expect(
        () => engine.evaluate(root, angleMode: AngleMode.degree),
        throwsA(
          isA<CalculatorException>().having(
            (e) => e.type,
            'type',
            CalculatorErrorType.domainError,
          ),
        ),
      );
    });

    test('empty function -> validation invalidExpression', () {
      final root = seq([FunctionNode.create(MathFunction.sin)]);
      expect(
        () => engine.evaluate(root, angleMode: AngleMode.degree),
        throwsA(
          isA<CalculatorException>().having(
            (e) => e.type,
            'type',
            CalculatorErrorType.invalidExpression,
          ),
        ),
      );
    });

    test('empty denominator -> validation invalidExpression', () {
      final frac = FractionNode(
        id: NodeId.generate(),
        numerator: seq([NumberNode.create('1')]),
        denominator: SequenceNode.empty(),
      );
      final root = seq([frac]);
      expect(
        () => engine.evaluate(root, angleMode: AngleMode.degree),
        throwsA(
          isA<CalculatorException>().having(
            (e) => e.type,
            'type',
            CalculatorErrorType.invalidExpression,
          ),
        ),
      );
    });

    test('operator at end -> validation invalidExpression', () {
      final root = seq([
        NumberNode.create('2'),
        OperatorNode.create(ExpressionOperator.add),
      ]);
      expect(
        () => engine.evaluate(root, angleMode: AngleMode.degree),
        throwsA(
          isA<CalculatorException>().having(
            (e) => e.type,
            'type',
            CalculatorErrorType.invalidExpression,
          ),
        ),
      );
    });

    test('1/0 產生 overflow 或 divisionByZero（非 invalidExpression）', () {
      // 大數除零會產生 Infinity -> overflow；小整數除零視套件行為。
      final root = seq([
        NumberNode.create('5'),
        OperatorNode.create(ExpressionOperator.divide),
        NumberNode.create('0'),
      ]);
      expect(
        () => engine.evaluate(root, angleMode: AngleMode.degree),
        throwsA(
          isA<CalculatorException>().having(
            (e) => e.type,
            'type',
            anyOf(
              CalculatorErrorType.divisionByZero,
              CalculatorErrorType.overflow,
            ),
          ),
        ),
      );
    });
  });

  group('formattedValue', () {
    test('整數結果格式化為整數字串', () {
      final root = seq([
        NumberNode.create('2'),
        OperatorNode.create(ExpressionOperator.add),
        NumberNode.create('3'),
      ]);
      final result = engine.evaluate(root, angleMode: AngleMode.degree);
      expect(result.formattedValue, '5');
    });
  });
}
