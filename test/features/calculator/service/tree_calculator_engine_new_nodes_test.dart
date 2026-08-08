import 'package:flutter_test/flutter_test.dart';
import 'package:scientific_calculator/app/result_format_settings.dart';
import 'package:scientific_calculator/core/math/angle_mode.dart';
import 'package:scientific_calculator/features/calculator/model/expression/expression_node.dart';
import 'package:scientific_calculator/features/calculator/model/expression/node/logarithm_node.dart';
import 'package:scientific_calculator/features/calculator/model/expression/node/mixed_fraction_node.dart';
import 'package:scientific_calculator/features/calculator/model/expression/node/number_node.dart';
import 'package:scientific_calculator/features/calculator/model/expression/node/operator_node.dart';
import 'package:scientific_calculator/features/calculator/model/expression/node/scientific_node.dart';
import 'package:scientific_calculator/features/calculator/model/expression/node/sequence_node.dart';
import 'package:scientific_calculator/features/calculator/model/expression/node_id.dart';
import 'package:scientific_calculator/features/calculator/service/tree_calculator_engine.dart';

/// LogarithmNode / MixedFractionNode / ScientificNode 的 engine 整合測試。
void main() {
  const engine = TreeCalculatorEngine();

  SequenceNode seq(List<ExpressionNode> children) =>
      SequenceNode(id: NodeId.generate(), children: children);

  void expectClose(num actual, num expected, {double tolerance = 1e-9}) {
    expect((actual - expected).abs(), lessThan(tolerance));
  }

  group('LogarithmNode', () {
    test('log_2(8) -> 3', () {
      final node = LogarithmNode(
        id: NodeId.generate(),
        base: seq([NumberNode.create('2')]),
        argument: seq([NumberNode.create('8')]),
      );
      final root = seq([node]);
      expectClose(
        engine.evaluate(root, angleMode: AngleMode.degree).value,
        3,
      );
    });

    test('log_10(1000) -> 3', () {
      final node = LogarithmNode(
        id: NodeId.generate(),
        base: seq([NumberNode.create('10')]),
        argument: seq([NumberNode.create('1000')]),
      );
      final root = seq([node]);
      expectClose(
        engine.evaluate(root, angleMode: AngleMode.degree).value,
        3,
      );
    });
  });

  group('MixedFractionNode', () {
    test('1 + 2/3 -> 1.666...', () {
      final node = MixedFractionNode(
        id: NodeId.generate(),
        whole: seq([NumberNode.create('1')]),
        numerator: seq([NumberNode.create('2')]),
        denominator: seq([NumberNode.create('3')]),
      );
      final root = seq([node]);
      expectClose(
        engine.evaluate(root, angleMode: AngleMode.degree).value,
        1 + 2 / 3,
      );
    });

    test('分數模式下以精確分數顯示', () {
      final node = MixedFractionNode(
        id: NodeId.generate(),
        whole: seq([NumberNode.create('2')]),
        numerator: seq([NumberNode.create('1')]),
        denominator: seq([NumberNode.create('4')]),
      );
      final root = seq([node]);
      final result = engine.evaluate(
        root,
        angleMode: AngleMode.degree,
        resultFormat: ResultFormatPreference.fraction,
      );
      // 2 + 1/4 = 9/4，exact formatter 應能化簡為分數 TeX。
      expect(result.formattedTex, isNotNull);
      expect(result.formattedTex, contains('frac'));
    });
  });

  group('ScientificNode', () {
    test('1E4 -> 10000', () {
      final node = ScientificNode(
        id: NodeId.generate(),
        mantissa: seq([NumberNode.create('1')]),
        exponent: seq([NumberNode.create('4')]),
      );
      final root = seq([node]);
      expectClose(
        engine.evaluate(root, angleMode: AngleMode.degree).value,
        10000,
      );
    });

    test('2.5E3 -> 2500', () {
      final node = ScientificNode(
        id: NodeId.generate(),
        mantissa: seq([NumberNode.create('2.5')]),
        exponent: seq([NumberNode.create('3')]),
      );
      final root = seq([node]);
      expectClose(
        engine.evaluate(root, angleMode: AngleMode.degree).value,
        2500,
      );
    });

    test('1E-2 -> 0.01', () {
      final node = ScientificNode(
        id: NodeId.generate(),
        mantissa: seq([NumberNode.create('1')]),
        exponent: seq([
          OperatorNode.create(ExpressionOperator.subtract),
          NumberNode.create('2'),
        ]),
      );
      final root = seq([node]);
      expectClose(
        engine.evaluate(root, angleMode: AngleMode.degree).value,
        0.01,
      );
    });
  });
}
