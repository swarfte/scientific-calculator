import 'package:flutter_test/flutter_test.dart';
import 'package:scientific_calculator/core/errors/calculator_exception.dart';
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
import 'package:scientific_calculator/features/calculator/service/expression_validator.dart';

void main() {
  const validator = ExpressionValidator();

  SequenceNode seq(List<ExpressionNode> children) =>
      SequenceNode(id: NodeId.generate(), children: children);

  group('ExpressionValidator', () {
    test('空 root 回傳 emptyExpression', () {
      final failure = validator.validate(SequenceNode.empty());
      expect(failure?.type, CalculatorErrorType.emptyExpression);
    });

    test('完整算式 2+3 通過', () {
      final root = seq([
        NumberNode.create('2'),
        OperatorNode.create(ExpressionOperator.add),
        NumberNode.create('3'),
      ]);
      expect(validator.validate(root), isNull);
    });

    test('以 operator 結尾回傳 invalidExpression', () {
      final root = seq([
        NumberNode.create('2'),
        OperatorNode.create(ExpressionOperator.add),
      ]);
      final failure = validator.validate(root);
      expect(failure?.type, CalculatorErrorType.invalidExpression);
      expect(failure?.message, contains('運算符結尾'));
    });

    test('非法連續 operator', () {
      final root = seq([
        NumberNode.create('2'),
        OperatorNode.create(ExpressionOperator.add),
        OperatorNode.create(ExpressionOperator.add),
        NumberNode.create('3'),
      ]);
      final failure = validator.validate(root);
      expect(failure?.type, CalculatorErrorType.invalidExpression);
    });

    test('乘號後接負號允許（3*-2）', () {
      final root = seq([
        NumberNode.create('3'),
        OperatorNode.create(ExpressionOperator.multiply),
        OperatorNode.create(ExpressionOperator.subtract),
        NumberNode.create('2'),
      ]);
      expect(validator.validate(root), isNull);
    });

    test('NumberNode 只是 "." 回傳 invalidExpression', () {
      final root = seq([NumberNode.create('.')]);
      expect(
        validator.validate(root)?.type,
        CalculatorErrorType.invalidExpression,
      );
    });

    test('空 function argument 回傳 invalidExpression', () {
      final fn = FunctionNode.create(MathFunction.sin);
      final root = seq([fn]);
      final failure = validator.validate(root);
      expect(failure?.type, CalculatorErrorType.invalidExpression);
      expect(failure?.sequenceId, fn.argument.id);
    });

    test('空 fraction denominator 回傳 invalidExpression', () {
      final frac = FractionNode(
        id: NodeId.generate(),
        numerator: seq([NumberNode.create('1')]),
        denominator: SequenceNode.empty(),
      );
      final root = seq([frac]);
      expect(
        validator.validate(root)?.type,
        CalculatorErrorType.invalidExpression,
      );
    });

    test('Ans 在無上一個答案時回傳 undefinedAnswer', () {
      final root = seq([ConstantNode.create(MathConstant.answer)]);
      final failure = validator.validate(root, hasAnswer: false);
      expect(failure?.type, CalculatorErrorType.undefinedAnswer);
    });

    test('Ans 在有上一個答案時通過', () {
      final root = seq([ConstantNode.create(MathConstant.answer)]);
      expect(validator.validate(root, hasAnswer: true), isNull);
    });

    test('巢狀結構：sqrt(2)/sqrt(3) 通過', () {
      final sqrt2 = RootNode(
        id: NodeId.generate(),
        radicand: seq([NumberNode.create('2')]),
      );
      final sqrt3 = RootNode(
        id: NodeId.generate(),
        radicand: seq([NumberNode.create('3')]),
      );
      final frac = FractionNode(
        id: NodeId.generate(),
        numerator: seq([sqrt2]),
        denominator: seq([sqrt3]),
      );
      final root = seq([frac]);
      expect(validator.validate(root), isNull);
    });

    test('空 group content 回傳 invalidExpression', () {
      final group = GroupNode.empty();
      final root = seq([group]);
      expect(
        validator.validate(root)?.type,
        CalculatorErrorType.invalidExpression,
      );
    });

    test('power 空 base 回傳 invalidExpression', () {
      final power = PowerNode(
        id: NodeId.generate(),
        base: SequenceNode.empty(),
        exponent: seq([NumberNode.create('2')]),
      );
      final root = seq([power]);
      expect(
        validator.validate(root)?.type,
        CalculatorErrorType.invalidExpression,
      );
    });
  });
}
