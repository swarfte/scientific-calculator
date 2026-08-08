import 'package:flutter_test/flutter_test.dart';
import 'package:scientific_calculator/features/calculator/model/expression/cursor_position.dart';
import 'package:scientific_calculator/features/calculator/model/expression/node/fraction_node.dart';
import 'package:scientific_calculator/features/calculator/model/expression/node/logarithm_node.dart';
import 'package:scientific_calculator/features/calculator/model/expression/node/mixed_fraction_node.dart';
import 'package:scientific_calculator/features/calculator/model/expression/node/number_node.dart';
import 'package:scientific_calculator/features/calculator/model/expression/node/operator_node.dart';
import 'package:scientific_calculator/features/calculator/model/expression/node/power_node.dart';
import 'package:scientific_calculator/features/calculator/model/expression/node/scientific_node.dart';
import 'package:scientific_calculator/features/calculator/model/expression/node/sequence_node.dart';
import 'package:scientific_calculator/features/calculator/model/expression/node_id.dart';
import 'package:scientific_calculator/features/calculator/model/expression/tree_expression_document.dart';
import 'package:scientific_calculator/features/calculator/service/tree_expression_editor.dart';

/// 針對 LogarithmNode / MixedFractionNode / ScientificNode 的新增按鍵與
/// backspace 降級規則測試。
void main() {
  const editor = TreeExpressionEditor();

  group('insertLogarithm', () {
    test('空位置建立空 LogarithmNode，游標進入 argument', () {
      var doc = TreeExpressionDocument.empty();
      doc = editor.insertLogarithm(doc);

      expect(doc.root.children.length, 1);
      final node = doc.root.children.first as LogarithmNode;
      expect(node.base.isEmpty, isTrue);
      expect(node.argument.isEmpty, isTrue);
      // 空位置：先進 base（先輸底數）。
      expect(doc.cursor.sequenceId, node.base.id);
      expect(doc.cursor.nodeOffset, 0);
    });

    test('左方 NumberNode 提升為 base，游標進入（空的）argument', () {
      final number = NumberNode.create('8');
      final root = SequenceNode(id: NodeId.generate(), children: [number]);
      var doc = TreeExpressionDocument(
        root: root,
        cursor: CursorPosition(sequenceId: root.id, nodeOffset: 1),
      );

      doc = editor.insertLogarithm(doc);

      expect(doc.root.children.length, 1);
      final node = doc.root.children.first as LogarithmNode;
      // base 含原 NumberNode（底數）。
      expect((node.base.children.first as NumberNode).value, '8');
      expect(node.argument.isEmpty, isTrue);
      // 游標進入 argument（真數）。
      expect(doc.cursor.sequenceId, node.argument.id);
    });
  });

  group('insertLogarithmBase2', () {
    test('建立底數預設為 2 的 LogarithmNode，游標進入 argument', () {
      var doc = TreeExpressionDocument.empty();
      doc = editor.insertLogarithmBase2(doc);

      expect(doc.root.children.length, 1);
      final node = doc.root.children.first as LogarithmNode;
      expect((node.base.children.first as NumberNode).value, '2');
      expect(node.argument.isEmpty, isTrue);
      expect(doc.cursor.sequenceId, node.argument.id);
    });
  });

  group('insertMixedFraction', () {
    test('空位置建立空 MixedFractionNode，游標進入 whole', () {
      var doc = TreeExpressionDocument.empty();
      doc = editor.insertMixedFraction(doc);

      expect(doc.root.children.length, 1);
      final node = doc.root.children.first as MixedFractionNode;
      expect(node.whole.isEmpty, isTrue);
      expect(node.numerator.isEmpty, isTrue);
      expect(node.denominator.isEmpty, isTrue);
      expect(doc.cursor.sequenceId, node.whole.id);
    });

    test('左方 NumberNode 提升為 whole，游標進入 numerator', () {
      final number = NumberNode.create('3');
      final root = SequenceNode(id: NodeId.generate(), children: [number]);
      var doc = TreeExpressionDocument(
        root: root,
        cursor: CursorPosition(sequenceId: root.id, nodeOffset: 1),
      );

      doc = editor.insertMixedFraction(doc);

      expect(doc.root.children.length, 1);
      final node = doc.root.children.first as MixedFractionNode;
      expect((node.whole.children.first as NumberNode).value, '3');
      expect(doc.cursor.sequenceId, node.numerator.id);
    });
  });

  group('insertScientific', () {
    test('空位置建立空 ScientificNode，游標進入 mantissa', () {
      var doc = TreeExpressionDocument.empty();
      doc = editor.insertScientific(doc);

      expect(doc.root.children.length, 1);
      final node = doc.root.children.first as ScientificNode;
      expect(node.mantissa.isEmpty, isTrue);
      expect(node.exponent.isEmpty, isTrue);
      expect(doc.cursor.sequenceId, node.mantissa.id);
    });

    test('左方 NumberNode 提升為 mantissa，游標進入 exponent', () {
      final number = NumberNode.create('1');
      final root = SequenceNode(id: NodeId.generate(), children: [number]);
      var doc = TreeExpressionDocument(
        root: root,
        cursor: CursorPosition(sequenceId: root.id, nodeOffset: 1),
      );

      doc = editor.insertScientific(doc);

      expect(doc.root.children.length, 1);
      final node = doc.root.children.first as ScientificNode;
      expect((node.mantissa.children.first as NumberNode).value, '1');
      expect(node.exponent.isEmpty, isTrue);
      expect(doc.cursor.sequenceId, node.exponent.id);
    });
  });

  group('backspace 降級', () {
    test('ScientificNode exponent 空白開頭 -> 解除保留 mantissa', () {
      final number = NumberNode.create('1');
      final sci = ScientificNode(
        id: NodeId.generate(),
        mantissa: SequenceNode(id: NodeId.generate(), children: [number]),
        exponent: SequenceNode.empty(),
      );
      final root = SequenceNode(id: NodeId.generate(), children: [sci]);
      var doc = TreeExpressionDocument(
        root: root,
        cursor: CursorPosition(sequenceId: sci.exponent.id, nodeOffset: 0),
      );

      doc = editor.backspace(doc);

      // ScientificNode 降回單一 NumberNode。
      expect(doc.root.children.length, 1);
      expect(doc.root.children.first, isA<NumberNode>());
      expect((doc.root.children.first as NumberNode).value, '1');
    });

    test('LogarithmNode argument 空白開頭 -> 移除整個 node', () {
      final log = LogarithmNode.empty();
      final root = SequenceNode(id: NodeId.generate(), children: [log]);
      var doc = TreeExpressionDocument(
        root: root,
        cursor: CursorPosition(sequenceId: log.argument.id, nodeOffset: 0),
      );

      doc = editor.backspace(doc);

      expect(doc.root.children, isEmpty);
    });

    test('LogarithmNode base 空白開頭 -> 退到 argument 開頭', () {
      final log = LogarithmNode.empty();
      final root = SequenceNode(id: NodeId.generate(), children: [log]);
      var doc = TreeExpressionDocument(
        root: root,
        cursor: CursorPosition(sequenceId: log.base.id, nodeOffset: 0),
      );

      doc = editor.backspace(doc);

      // Tree 不變，游標退到 argument 開頭。
      expect(doc.root.children.length, 1);
      expect(doc.cursor.sequenceId, log.argument.id);
      expect(doc.cursor.nodeOffset, 0);
    });

    test('MixedFractionNode denominator 空白開頭 -> 退到 numerator 末端', () {
      final mixed = MixedFractionNode(
        id: NodeId.generate(),
        whole: SequenceNode(
          id: NodeId.generate(),
          children: [NumberNode.create('1')],
        ),
        numerator: SequenceNode(
          id: NodeId.generate(),
          children: [NumberNode.create('2')],
        ),
        denominator: SequenceNode.empty(),
      );
      final root = SequenceNode(id: NodeId.generate(), children: [mixed]);
      var doc = TreeExpressionDocument(
        root: root,
        cursor: CursorPosition(
          sequenceId: mixed.denominator.id,
          nodeOffset: 0,
        ),
      );

      doc = editor.backspace(doc);

      expect(doc.cursor.sequenceId, mixed.numerator.id);
      expect(doc.cursor.nodeOffset, 1);
    });

    test('MixedFractionNode numerator 空白開頭 -> 退到 whole 末端', () {
      final mixed = MixedFractionNode(
        id: NodeId.generate(),
        whole: SequenceNode(
          id: NodeId.generate(),
          children: [NumberNode.create('1')],
        ),
        numerator: SequenceNode.empty(),
        denominator: SequenceNode.empty(),
      );
      final root = SequenceNode(id: NodeId.generate(), children: [mixed]);
      var doc = TreeExpressionDocument(
        root: root,
        cursor: CursorPosition(
          sequenceId: mixed.numerator.id,
          nodeOffset: 0,
        ),
      );

      doc = editor.backspace(doc);

      expect(doc.cursor.sequenceId, mixed.whole.id);
      expect(doc.cursor.nodeOffset, 1);
    });

    test('MixedFractionNode whole 空白開頭 -> 移除整個 node', () {
      final mixed = MixedFractionNode.empty();
      final root = SequenceNode(id: NodeId.generate(), children: [mixed]);
      var doc = TreeExpressionDocument(
        root: root,
        cursor: CursorPosition(sequenceId: mixed.whole.id, nodeOffset: 0),
      );

      doc = editor.backspace(doc);

      expect(doc.root.children, isEmpty);
    });
  });

  group('insertSquare 包覆任意左方 node', () {
    test('左方為 FractionNode：整個分數成為 base，exponent 為 2', () {
      final fraction = FractionNode(
        id: NodeId.generate(),
        numerator: SequenceNode(
          id: NodeId.generate(),
          children: [NumberNode.create('1')],
        ),
        denominator: SequenceNode(
          id: NodeId.generate(),
          children: [NumberNode.create('2')],
        ),
      );
      final root = SequenceNode(id: NodeId.generate(), children: [fraction]);
      var doc = TreeExpressionDocument(
        root: root,
        cursor: CursorPosition(sequenceId: root.id, nodeOffset: 1),
      );

      doc = editor.insertSquare(doc);

      expect(doc.root.children.length, 1);
      final power = doc.root.children.first as PowerNode;
      // base 包含原 FractionNode。
      expect(power.base.children.first, isA<FractionNode>());
      // exponent 為 2。
      expect((power.exponent.children.first as NumberNode).value, '2');
      // 游標移到 PowerNode 後方。
      expect(doc.cursor.sequenceId, root.id);
      expect(doc.cursor.nodeOffset, 1);
    });

    test('空位置建立 base 為空的 PowerNode，exponent 為 2', () {
      var doc = TreeExpressionDocument.empty();
      doc = editor.insertSquare(doc);

      expect(doc.root.children.length, 1);
      final power = doc.root.children.first as PowerNode;
      expect(power.base.isEmpty, isTrue);
      expect((power.exponent.children.first as NumberNode).value, '2');
    });
  });

  group('insertOperator 在 exponent 內外提', () {
    test('ScientificNode exponent 內按 + -> 跳出至 parent，operator 加在 parent',
        () {
      // 1E3：mantissa=1, exponent=3，cursor 在 exponent 末端。
      final sci = ScientificNode(
        id: NodeId.generate(),
        mantissa: SequenceNode(
          id: NodeId.generate(),
          children: [NumberNode.create('1')],
        ),
        exponent: SequenceNode(
          id: NodeId.generate(),
          children: [NumberNode.create('3')],
        ),
      );
      final root = SequenceNode(id: NodeId.generate(), children: [sci]);
      var doc = TreeExpressionDocument(
        root: root,
        cursor: CursorPosition(
          sequenceId: sci.exponent.id,
          nodeOffset: 0,
          textOffset: 1, // 3|
        ),
      );

      doc = editor.insertOperator(doc, ExpressionOperator.add);

      // operator 加在 root（ScientificNode 後方），不在 exponent 內。
      expect(doc.root.children.length, 2);
      expect(doc.root.children[0], isA<ScientificNode>());
      expect(doc.root.children[1], isA<OperatorNode>());
      expect(
        (doc.root.children[1] as OperatorNode).operator,
        ExpressionOperator.add,
      );
      // ScientificNode 的 exponent 仍只有 3，未被污染。
      final sciAfter = doc.root.children[0] as ScientificNode;
      expect(sciAfter.exponent.children.length, 1);
      // cursor 在 operator 後方。
      expect(doc.cursor.sequenceId, root.id);
      expect(doc.cursor.nodeOffset, 2);
    });

    test('PowerNode exponent 內按 + -> 跳出至 parent', () {
      final power = PowerNode(
        id: NodeId.generate(),
        base: SequenceNode(
          id: NodeId.generate(),
          children: [NumberNode.create('2')],
        ),
        exponent: SequenceNode(
          id: NodeId.generate(),
          children: [NumberNode.create('3')],
        ),
      );
      final root = SequenceNode(id: NodeId.generate(), children: [power]);
      var doc = TreeExpressionDocument(
        root: root,
        cursor: CursorPosition(
          sequenceId: power.exponent.id,
          nodeOffset: 0,
          textOffset: 1, // 3|
        ),
      );

      doc = editor.insertOperator(doc, ExpressionOperator.multiply);

      expect(doc.root.children.length, 2);
      expect(doc.root.children[0], isA<PowerNode>());
      expect(
        (doc.root.children[1] as OperatorNode).operator,
        ExpressionOperator.multiply,
      );
    });
  });
}
