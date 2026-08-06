import 'package:flutter_test/flutter_test.dart';
import 'package:scientific_calculator/features/calculator/model/expression/cursor_position.dart';
import 'package:scientific_calculator/features/calculator/model/expression/node/fraction_node.dart';
import 'package:scientific_calculator/features/calculator/model/expression/node/function_node.dart';
import 'package:scientific_calculator/features/calculator/model/expression/node/number_node.dart';
import 'package:scientific_calculator/features/calculator/model/expression/node/operator_node.dart';
import 'package:scientific_calculator/features/calculator/model/expression/node/power_node.dart';
import 'package:scientific_calculator/features/calculator/model/expression/node/root_node.dart';
import 'package:scientific_calculator/features/calculator/model/expression/node/sequence_node.dart';
import 'package:scientific_calculator/features/calculator/model/expression/node_id.dart';
import 'package:scientific_calculator/features/calculator/model/expression/sequence_role.dart';
import 'package:scientific_calculator/features/calculator/model/expression/tree_index.dart';

void main() {
  group('TreeIndex', () {
    test('root sequence and node are indexed', () {
      final root = SequenceNode.empty();
      final index = TreeIndex(root);

      expect(index.rootId, root.id);
      expect(index.findSequence(root.id), same(root));
      expect(index.findNode(root.id), same(root));
      expect(index.findParentOfSequence(root.id), isNull);
      expect(index.findParentOfNode(root.id), isNull);
    });

    test('flat sequence children are indexed with parent locations', () {
      final number = NumberNode.create('2');
      final op = OperatorNode.create(ExpressionOperator.add);
      final number2 = NumberNode.create('3');
      final root = SequenceNode(
        id: NodeId.generate(),
        children: [number, op, number2],
      );
      final index = TreeIndex(root);

      expect(index.findNode(number.id), same(number));
      expect(index.findNode(op.id), same(op));

      final numberLoc = index.findParentOfNode(number.id);
      expect(numberLoc?.parentSequence, same(root));
      expect(numberLoc?.index, 0);

      final number2Loc = index.findParentOfNode(number2.id);
      expect(number2Loc?.index, 2);
    });

    test('function argument sequence is indexed with correct role', () {
      final argumentNumber = NumberNode.create('30');
      final argument = SequenceNode(
        id: NodeId.generate(),
        children: [argumentNumber],
      );
      final function = FunctionNode(
        id: NodeId.generate(),
        function: MathFunction.sin,
        argument: argument,
      );
      final root = SequenceNode(id: NodeId.generate(), children: [function]);
      final index = TreeIndex(root);

      final argLocation = index.findParentOfSequence(argument.id);
      expect(argLocation, isNotNull);
      expect(argLocation!.ownerNode, same(function));
      expect(argLocation.role, SequenceRole.functionArgument);
      expect(argLocation.parentSequence, same(root));
      expect(argLocation.ownerIndex, 0);

      expect(index.findParentOfNode(function.id)?.index, 0);
    });

    test('fraction numerator and denominator have distinct roles', () {
      final numerator = SequenceNode.empty();
      final denominator = SequenceNode.empty();
      final fraction = FractionNode(
        id: NodeId.generate(),
        numerator: numerator,
        denominator: denominator,
      );
      final root = SequenceNode(id: NodeId.generate(), children: [fraction]);
      final index = TreeIndex(root);

      expect(
        index.findParentOfSequence(numerator.id)?.role,
        SequenceRole.fractionNumerator,
      );
      expect(
        index.findParentOfSequence(denominator.id)?.role,
        SequenceRole.fractionDenominator,
      );
    });

    test('square root has only radicand; nth root has degree and radicand', () {
      final square = RootNode.squareRoot();
      final squareChildren = TreeIndex.childSequencesOf(
        square,
      ).map((e) => e.role).toList();
      expect(squareChildren, [SequenceRole.rootRadicand]);

      final nth = RootNode.nthRoot();
      final nthChildren = TreeIndex.childSequencesOf(
        nth,
      ).map((e) => e.role).toList();
      // degree 排在前，radicand 在後。
      expect(nthChildren, [SequenceRole.rootDegree, SequenceRole.rootRadicand]);
    });

    test('leaf nodes expose no child sequences', () {
      expect(TreeIndex.childSequencesOf(NumberNode.create('1')), isEmpty);
      expect(
        TreeIndex.childSequencesOf(OperatorNode.create(ExpressionOperator.add)),
        isEmpty,
      );
    });

    group('isValidCursor', () {
      test('valid gap and text cursors', () {
        final number = NumberNode.create('123');
        final root = SequenceNode(id: NodeId.generate(), children: [number]);
        final index = TreeIndex(root);

        expect(
          index.isValidCursor(
            CursorPosition(sequenceId: root.id, nodeOffset: 0),
          ),
          isTrue,
        );
        expect(
          index.isValidCursor(
            CursorPosition(sequenceId: root.id, nodeOffset: 1),
          ),
          isTrue,
        );
        expect(
          index.isValidCursor(
            CursorPosition(sequenceId: root.id, nodeOffset: 0, textOffset: 2),
          ),
          isTrue,
        );
      });

      test('unknown sequence id is invalid', () {
        final root = SequenceNode.empty();
        final index = TreeIndex(root);

        expect(
          index.isValidCursor(
            CursorPosition(sequenceId: NodeId('ghost'), nodeOffset: 0),
          ),
          isFalse,
        );
      });

      test('text mode on non-number child is invalid', () {
        final op = OperatorNode.create(ExpressionOperator.add);
        final root = SequenceNode(id: NodeId.generate(), children: [op]);
        final index = TreeIndex(root);

        expect(
          index.isValidCursor(
            CursorPosition(sequenceId: root.id, nodeOffset: 0, textOffset: 0),
          ),
          isFalse,
        );
      });
    });

    group('clampCursor', () {
      test('unknown sequence id falls back to root end', () {
        final root = SequenceNode.empty();
        final index = TreeIndex(root);

        final clamped = index.clampCursor(
          CursorPosition(sequenceId: NodeId('ghost'), nodeOffset: 5),
        );
        expect(clamped.sequenceId, root.id);
        expect(clamped.nodeOffset, 0);
        expect(clamped.textOffset, isNull);
      });

      test('out-of-range text offset is clamped into number range', () {
        final number = NumberNode.create('12');
        final root = SequenceNode(id: NodeId.generate(), children: [number]);
        final index = TreeIndex(root);

        final clamped = index.clampCursor(
          CursorPosition(sequenceId: root.id, nodeOffset: 0, textOffset: 99),
        );
        expect(clamped.textOffset, 2);
      });

      test('text mode on a non-number degrades to gap mode', () {
        final op = OperatorNode.create(ExpressionOperator.add);
        final root = SequenceNode(id: NodeId.generate(), children: [op]);
        final index = TreeIndex(root);

        final clamped = index.clampCursor(
          CursorPosition(sequenceId: root.id, nodeOffset: 0, textOffset: 1),
        );
        expect(clamped.textOffset, isNull);
        expect(clamped.nodeOffset, 0);
      });

      test('deeply nested cursor in power exponent is valid', () {
        final exponent = SequenceNode.empty();
        final base = SequenceNode.empty();
        final power = PowerNode(
          id: NodeId.generate(),
          base: base,
          exponent: exponent,
        );
        final root = SequenceNode(id: NodeId.generate(), children: [power]);
        final index = TreeIndex(root);

        final cursor = CursorPosition(sequenceId: exponent.id, nodeOffset: 0);
        expect(index.isValidCursor(cursor), isTrue);
        expect(
          index.findParentOfSequence(exponent.id)?.role,
          SequenceRole.powerExponent,
        );
      });
    });
  });
}
