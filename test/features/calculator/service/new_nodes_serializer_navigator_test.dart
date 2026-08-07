import 'package:flutter_test/flutter_test.dart';
import 'package:scientific_calculator/features/calculator/model/expression/cursor_position.dart';
import 'package:scientific_calculator/features/calculator/model/expression/node/logarithm_node.dart';
import 'package:scientific_calculator/features/calculator/model/expression/node/mixed_fraction_node.dart';
import 'package:scientific_calculator/features/calculator/model/expression/node/number_node.dart';
import 'package:scientific_calculator/features/calculator/model/expression/node/scientific_node.dart';
import 'package:scientific_calculator/features/calculator/model/expression/node/sequence_node.dart';
import 'package:scientific_calculator/features/calculator/model/expression/node_id.dart';
import 'package:scientific_calculator/features/calculator/model/expression/tree_expression_document.dart';
import 'package:scientific_calculator/features/calculator/service/expression_navigator.dart';
import 'package:scientific_calculator/features/calculator/service/tree_expression_tex_serializer.dart';

/// LogarithmNode / MixedFractionNode / ScientificNode 的 TeX 序列化與
/// Navigator 垂直移動測試。
void main() {
  const serializer = TreeExpressionTexSerializer();
  const navigator = ExpressionNavigator();

  String visibleTex(TreeExpressionDocument doc) =>
      serializer.serialize(doc).withVisibleCursor;

  group('LogarithmNode serialization', () {
    test('log_2(8) -> \\log_{2}\\left(8\\right)', () {
      final node = LogarithmNode(
        id: NodeId.generate(),
        base: SequenceNode(
          id: NodeId.generate(),
          children: [NumberNode.create('2')],
        ),
        argument: SequenceNode(
          id: NodeId.generate(),
          children: [NumberNode.create('8')],
        ),
      );
      final root = SequenceNode(id: NodeId.generate(), children: [node]);
      final doc = TreeExpressionDocument(
        root: root,
        cursor: CursorPosition(sequenceId: root.id, nodeOffset: 1),
      );
      final tex = visibleTex(doc);
      expect(tex, contains(r'\log_{2}'));
      expect(tex, contains(r'\left(8\right)'));
    });
  });

  group('MixedFractionNode serialization', () {
    test('1 2/3 -> 1\\frac{2}{3}', () {
      final node = MixedFractionNode(
        id: NodeId.generate(),
        whole: SequenceNode(
          id: NodeId.generate(),
          children: [NumberNode.create('1')],
        ),
        numerator: SequenceNode(
          id: NodeId.generate(),
          children: [NumberNode.create('2')],
        ),
        denominator: SequenceNode(
          id: NodeId.generate(),
          children: [NumberNode.create('3')],
        ),
      );
      final root = SequenceNode(id: NodeId.generate(), children: [node]);
      final doc = TreeExpressionDocument(
        root: root,
        cursor: CursorPosition(sequenceId: root.id, nodeOffset: 1),
      );
      final tex = visibleTex(doc);
      expect(tex, contains('1'));
      expect(tex, contains(r'\frac{2}{3}'));
    });
  });

  group('ScientificNode serialization', () {
    test('1E4 顯示 mantissa E exponent', () {
      final node = ScientificNode(
        id: NodeId.generate(),
        mantissa: SequenceNode(
          id: NodeId.generate(),
          children: [NumberNode.create('1')],
        ),
        exponent: SequenceNode(
          id: NodeId.generate(),
          children: [NumberNode.create('4')],
        ),
      );
      final root = SequenceNode(id: NodeId.generate(), children: [node]);
      final doc = TreeExpressionDocument(
        root: root,
        cursor: CursorPosition(sequenceId: root.id, nodeOffset: 1),
      );
      final tex = visibleTex(doc);
      expect(tex, contains('1'));
      expect(tex, contains('E'));
      expect(tex, contains('4'));
    });
  });

  group('Navigator 垂直移動（新 node）', () {
    test('LogarithmNode: base 向下 -> argument', () {
      final node = LogarithmNode(
        id: NodeId.generate(),
        base: SequenceNode(
          id: NodeId.generate(),
          children: [NumberNode.create('2')],
        ),
        argument: SequenceNode(
          id: NodeId.generate(),
          children: [NumberNode.create('8')],
        ),
      );
      final root = SequenceNode(id: NodeId.generate(), children: [node]);
      var doc = TreeExpressionDocument(
        root: root,
        cursor: CursorPosition(
          sequenceId: node.base.id,
          nodeOffset: 1,
        ),
      );

      doc = navigator.moveDown(doc);
      expect(doc.cursor.sequenceId, node.argument.id);
    });

    test('LogarithmNode: argument 向上 -> base', () {
      final node = LogarithmNode(
        id: NodeId.generate(),
        base: SequenceNode(
          id: NodeId.generate(),
          children: [NumberNode.create('2')],
        ),
        argument: SequenceNode(
          id: NodeId.generate(),
          children: [NumberNode.create('8')],
        ),
      );
      final root = SequenceNode(id: NodeId.generate(), children: [node]);
      var doc = TreeExpressionDocument(
        root: root,
        cursor: CursorPosition(
          sequenceId: node.argument.id,
          nodeOffset: 0,
        ),
      );

      doc = navigator.moveUp(doc);
      expect(doc.cursor.sequenceId, node.base.id);
    });

    test('MixedFractionNode: whole -> numerator -> denominator', () {
      final node = MixedFractionNode(
        id: NodeId.generate(),
        whole: SequenceNode(
          id: NodeId.generate(),
          children: [NumberNode.create('1')],
        ),
        numerator: SequenceNode(
          id: NodeId.generate(),
          children: [NumberNode.create('2')],
        ),
        denominator: SequenceNode(
          id: NodeId.generate(),
          children: [NumberNode.create('3')],
        ),
      );
      final root = SequenceNode(id: NodeId.generate(), children: [node]);
      var doc = TreeExpressionDocument(
        root: root,
        cursor: CursorPosition(
          sequenceId: node.whole.id,
          nodeOffset: 1,
        ),
      );

      doc = navigator.moveDown(doc);
      expect(doc.cursor.sequenceId, node.numerator.id);

      doc = navigator.moveDown(doc);
      expect(doc.cursor.sequenceId, node.denominator.id);
    });

    test('ScientificNode: mantissa 向下 -> exponent', () {
      final node = ScientificNode(
        id: NodeId.generate(),
        mantissa: SequenceNode(
          id: NodeId.generate(),
          children: [NumberNode.create('1')],
        ),
        exponent: SequenceNode(
          id: NodeId.generate(),
          children: [NumberNode.create('4')],
        ),
      );
      final root = SequenceNode(id: NodeId.generate(), children: [node]);
      var doc = TreeExpressionDocument(
        root: root,
        cursor: CursorPosition(
          sequenceId: node.mantissa.id,
          nodeOffset: 1,
        ),
      );

      doc = navigator.moveDown(doc);
      expect(doc.cursor.sequenceId, node.exponent.id);
    });
  });
}
