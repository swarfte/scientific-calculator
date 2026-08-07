import 'package:flutter_test/flutter_test.dart';
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
import 'package:scientific_calculator/features/calculator/service/exact_math/exact_number.dart';
import 'package:scientific_calculator/features/calculator/service/exact_math/exact_value_evaluator.dart';
import 'package:scientific_calculator/features/calculator/service/exact_math/rational.dart';

void main() {
  const evaluator = ExactValueEvaluator();

  SequenceNode seq(List<ExpressionNode> children) =>
      SequenceNode(id: NodeId.generate(), children: children);

  ExactNumber intNum(int v) => ExactNumber.fromInt(v);
  ExactNumber rational(int n, int d) =>
      ExactNumber.rational(Rational.reduce(BigInt.from(n), BigInt.from(d)));
  ExactNumber surd(int radicand, int coeff) =>
      ExactNumber.fromTerms({BigInt.from(radicand): Rational.fromInt(coeff)});

  group('基本算術', () {
    test('2 + 3 -> 5', () {
      final root = seq([
        NumberNode.create('2'),
        OperatorNode.create(ExpressionOperator.add),
        NumberNode.create('3'),
      ]);
      expect(evaluator.evaluate(root), intNum(5));
    });

    test('7 / 3 -> 7/3（未化簡帶分數，由 formatter 處理）', () {
      final root = seq([
        NumberNode.create('7'),
        OperatorNode.create(ExpressionOperator.divide),
        NumberNode.create('3'),
      ]);
      expect(evaluator.evaluate(root), rational(7, 3));
    });

    test('2.5 + 0.5 -> 3', () {
      final root = seq([
        NumberNode.create('2.5'),
        OperatorNode.create(ExpressionOperator.add),
        NumberNode.create('0.5'),
      ]);
      expect(evaluator.evaluate(root), intNum(3));
    });

    test('負號（unary minus）', () {
      final root = seq([
        OperatorNode.create(ExpressionOperator.subtract),
        NumberNode.create('5'),
      ]);
      expect(evaluator.evaluate(root), intNum(-5));
    });

    test('運算子優先順序：2 + 3 * 4 -> 14', () {
      final root = seq([
        NumberNode.create('2'),
        OperatorNode.create(ExpressionOperator.add),
        NumberNode.create('3'),
        OperatorNode.create(ExpressionOperator.multiply),
        NumberNode.create('4'),
      ]);
      expect(evaluator.evaluate(root), intNum(14));
    });
  });

  group('分數節點 FractionNode', () {
    test('4/3 -> 4/3', () {
      final frac = FractionNode(
        id: NodeId.generate(),
        numerator: seq([NumberNode.create('4')]),
        denominator: seq([NumberNode.create('3')]),
      );
      expect(evaluator.evaluate(seq([frac])), rational(4, 3));
    });

    test('分數內含運算：(1+2)/(3+4) -> 3/7', () {
      final frac = FractionNode(
        id: NodeId.generate(),
        numerator: seq([
          NumberNode.create('1'),
          OperatorNode.create(ExpressionOperator.add),
          NumberNode.create('2'),
        ]),
        denominator: seq([
          NumberNode.create('3'),
          OperatorNode.create(ExpressionOperator.add),
          NumberNode.create('4'),
        ]),
      );
      expect(evaluator.evaluate(seq([frac])), rational(3, 7));
    });
  });

  group('根號節點 RootNode（平方根）', () {
    test('√12 -> 2√3', () {
      final root = seq([
        RootNode(id: NodeId.generate(), radicand: seq([NumberNode.create('12')])),
      ]);
      expect(evaluator.evaluate(root), surd(3, 2));
    });

    test('√18 -> 3√2', () {
      final root = seq([
        RootNode(id: NodeId.generate(), radicand: seq([NumberNode.create('18')])),
      ]);
      expect(evaluator.evaluate(root), surd(2, 3));
    });

    test('√16 -> 4（完全平方）', () {
      final root = seq([
        RootNode(id: NodeId.generate(), radicand: seq([NumberNode.create('16')])),
      ]);
      expect(evaluator.evaluate(root), intNum(4));
    });

    test('√2 + √3 -> √2 + √3', () {
      final root = seq([
        RootNode(id: NodeId.generate(), radicand: seq([NumberNode.create('2')])),
        OperatorNode.create(ExpressionOperator.add),
        RootNode(id: NodeId.generate(), radicand: seq([NumberNode.create('3')])),
      ]);
      final result = evaluator.evaluate(root)!;
      expect(result.surdTerms.length, 2);
    });

    test('1/√2 -> √2/2（有理化）', () {
      final frac = FractionNode(
        id: NodeId.generate(),
        numerator: seq([NumberNode.create('1')]),
        denominator: seq([
          RootNode(id: NodeId.generate(), radicand: seq([NumberNode.create('2')])),
        ]),
      );
      // 1/√2 = √2/2，即 (1/2)√2。
      expect(
        evaluator.evaluate(seq([frac])),
        ExactNumber.fromTerms({BigInt.two: Rational.reduce(BigInt.one, BigInt.two)}),
      );
    });

    test('n 次根（degree 已設）-> null（fallback）', () {
      final root = seq([
        RootNode(
          id: NodeId.generate(),
          radicand: seq([NumberNode.create('8')]),
          degree: seq([NumberNode.create('3')]),
        ),
      ]);
      expect(evaluator.evaluate(root), isNull);
    });

    test('√(-1) -> null（實數範圍無定義）', () {
      final root = seq([
        RootNode(
          id: NodeId.generate(),
          radicand: seq([
            OperatorNode.create(ExpressionOperator.subtract),
            NumberNode.create('1'),
          ]),
        ),
      ]);
      expect(evaluator.evaluate(root), isNull);
    });
  });

  group('指數節點 PowerNode', () {
    PowerNode power(String base, String exp) => PowerNode(
      id: NodeId.generate(),
      base: seq([NumberNode.create(base)]),
      exponent: seq([NumberNode.create(exp)]),
    );

    test('5^2 -> 25', () {
      expect(evaluator.evaluate(seq([power('5', '2')])), intNum(25));
    });

    test('(1+√2)^2 -> 3+2√2', () {
      final base = seq([
        NumberNode.create('1'),
        OperatorNode.create(ExpressionOperator.add),
        RootNode(id: NodeId.generate(), radicand: seq([NumberNode.create('2')])),
      ]);
      final pow = PowerNode(
        id: NodeId.generate(),
        base: base,
        exponent: seq([NumberNode.create('2')]),
      );
      final result = evaluator.evaluate(seq([pow]))!;
      expect(result.rationalPart, Rational.fromInt(3));
      expect(result.surdTerms.single.value, Rational.fromInt(2));
    });

    test('2^-1 -> 1/2（負整數次方）', () {
      expect(evaluator.evaluate(seq([power('2', '-1')])), rational(1, 2));
    });

    test('非整數次方 -> null', () {
      expect(evaluator.evaluate(seq([power('2', '0.5')])), isNull);
    });
  });

  group('bail-out（無法精確表示）', () {
    test('π 常數 -> null', () {
      final root = seq([ConstantNode.create(MathConstant.pi)]);
      expect(evaluator.evaluate(root), isNull);
    });

    test('e 常數 -> null', () {
      final root = seq([ConstantNode.create(MathConstant.e)]);
      expect(evaluator.evaluate(root), isNull);
    });

    test('sin(30) -> null', () {
      final root = seq([
        FunctionNode(
          id: NodeId.generate(),
          function: MathFunction.sin,
          argument: seq([NumberNode.create('30')]),
        ),
      ]);
      expect(evaluator.evaluate(root), isNull);
    });

    test('ln(e) -> null', () {
      final root = seq([
        FunctionNode(
          id: NodeId.generate(),
          function: MathFunction.ln,
          argument: seq([ConstantNode.create(MathConstant.e)]),
        ),
      ]);
      expect(evaluator.evaluate(root), isNull);
    });

    test('2 + π -> null（牽涉超越數）', () {
      final root = seq([
        NumberNode.create('2'),
        OperatorNode.create(ExpressionOperator.add),
        ConstantNode.create(MathConstant.pi),
      ]);
      expect(evaluator.evaluate(root), isNull);
    });
  });

  group('Ans 常數', () {
    test('Ans 為整數時可精確使用', () {
      final eval = ExactValueEvaluator(answer: 42);
      final root = seq([ConstantNode.create(MathConstant.answer)]);
      expect(eval.evaluate(root), intNum(42));
    });

    test('Ans 為小數時 -> null', () {
      final eval = ExactValueEvaluator(answer: 2.5);
      final root = seq([ConstantNode.create(MathConstant.answer)]);
      expect(eval.evaluate(root), isNull);
    });
  });

  group('群組 GroupNode', () {
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
      expect(evaluator.evaluate(root), intNum(20));
    });
  });
}
