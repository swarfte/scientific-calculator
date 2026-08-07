import 'package:flutter_test/flutter_test.dart';
import 'package:scientific_calculator/features/calculator/model/expression/cursor_position.dart';
import 'package:scientific_calculator/features/calculator/model/expression/node/fraction_node.dart';
import 'package:scientific_calculator/features/calculator/model/expression/node/function_node.dart';
import 'package:scientific_calculator/features/calculator/model/expression/node/group_node.dart';
import 'package:scientific_calculator/features/calculator/model/expression/node/mixed_fraction_node.dart';
import 'package:scientific_calculator/features/calculator/model/expression/node/number_node.dart';
import 'package:scientific_calculator/features/calculator/model/expression/node/operator_node.dart';
import 'package:scientific_calculator/features/calculator/model/expression/node/power_node.dart';
import 'package:scientific_calculator/features/calculator/model/expression/node/root_node.dart';
import 'package:scientific_calculator/features/calculator/model/expression/node/sequence_node.dart';
import 'package:scientific_calculator/features/calculator/model/expression/node_id.dart';
import 'package:scientific_calculator/features/calculator/model/expression/tree_expression_document.dart';
import 'package:scientific_calculator/features/calculator/service/expression_navigator.dart';

/// Phase 2 navigator 測試輔助：用樹狀結構描述游標位置，方便斷言。
///
/// 測試以手動建構的 Tree 驗證 cursor 移動，不依賴 evaluation/TeX string。
void main() {
  const navigator = ExpressionNavigator();

  /// 建構 `123` 並回傳 sequence 與 number，方便設定 cursor。
  SequenceNode buildNumber123(NumberNode number) {
    return SequenceNode(id: NodeId.generate(), children: [number]);
  }

  group('moveLeft / moveRight inside NumberNode', () {
    test('1|23 向右 -> 12|3', () {
      final number = NumberNode.create('123');
      final root = buildNumber123(number);
      final doc = TreeExpressionDocument(
        root: root,
        cursor: CursorPosition(
          sequenceId: root.id,
          nodeOffset: 0,
          textOffset: 1,
        ),
      );

      final moved = navigator.moveRight(doc);

      expect(moved.cursor.sequenceId, root.id);
      expect(moved.cursor.nodeOffset, 0);
      expect(moved.cursor.textOffset, 2);
    });

    test('12|3 向左 -> 1|23', () {
      final number = NumberNode.create('123');
      final root = buildNumber123(number);
      final doc = TreeExpressionDocument(
        root: root,
        cursor: CursorPosition(
          sequenceId: root.id,
          nodeOffset: 0,
          textOffset: 2,
        ),
      );

      final moved = navigator.moveLeft(doc);

      expect(moved.cursor.textOffset, 1);
    });

    test('number 開頭向左 -> 離開 number 至前方間隙', () {
      final number = NumberNode.create('123');
      final root = buildNumber123(number);
      final doc = TreeExpressionDocument(
        root: root,
        cursor: CursorPosition(
          sequenceId: root.id,
          nodeOffset: 0,
          textOffset: 0,
        ),
      );

      final moved = navigator.moveLeft(doc);

      // root 開頭無路可走，停在 root 開頭。
      expect(moved.cursor.sequenceId, root.id);
      expect(moved.cursor.nodeOffset, 0);
      expect(moved.cursor.textOffset, isNull);
    });

    test('number 末端向右 -> 離開 number 至後方間隙', () {
      final number = NumberNode.create('123');
      final root = buildNumber123(number);
      final doc = TreeExpressionDocument(
        root: root,
        cursor: CursorPosition(
          sequenceId: root.id,
          nodeOffset: 0,
          textOffset: 3,
        ),
      );

      final moved = navigator.moveRight(doc);

      expect(moved.cursor.sequenceId, root.id);
      expect(moved.cursor.nodeOffset, 1);
      expect(moved.cursor.textOffset, isNull);
    });
  });

  group('flat sequence node boundaries', () {
    test('|2+3 向右進入 number 2 文字開頭', () {
      final n2 = NumberNode.create('2');
      final op = OperatorNode.create(ExpressionOperator.add);
      final n3 = NumberNode.create('3');
      final root = SequenceNode(id: NodeId.generate(), children: [n2, op, n3]);
      final doc = TreeExpressionDocument(
        root: root,
        cursor: CursorPosition(sequenceId: root.id, nodeOffset: 0),
      );

      // |[2]+[3] -> 向右遇到 NumberNode 2，進入文字開頭（text mode）。
      final moved = navigator.moveRight(doc);
      expect(moved.cursor.sequenceId, root.id);
      expect(moved.cursor.nodeOffset, 0);
      expect(moved.cursor.textOffset, 0);
    });

    test('number 末端向右跨越 operator 進入下一個 number 文字開頭', () {
      final n2 = NumberNode.create('2');
      final op = OperatorNode.create(ExpressionOperator.add);
      final n3 = NumberNode.create('3');
      final root = SequenceNode(id: NodeId.generate(), children: [n2, op, n3]);
      final doc = TreeExpressionDocument(
        root: root,
        cursor: CursorPosition(
          sequenceId: root.id,
          nodeOffset: 0,
          textOffset: 1, // 2| (number 末端)
        ),
      );

      final step1 = navigator.moveRight(doc); // -> 離開 number 至後方間隙 (operator 前)
      expect(step1.cursor.nodeOffset, 1);
      expect(step1.cursor.textOffset, isNull);

      final step2 = navigator.moveRight(step1); // -> operator 為 leaf，跨越至後方間隙
      expect(step2.cursor.nodeOffset, 2);
      expect(step2.cursor.textOffset, isNull);

      final step3 = navigator.moveRight(step2); // -> 進入 number 3 文字開頭
      expect(step3.cursor.nodeOffset, 2);
      expect(step3.cursor.textOffset, 0);
    });
  });

  group('FunctionNode navigation', () {
    test('sin(30|) 向右 -> sin(30)| （離開 argument 至 function 後方）', () {
      final argNumber = NumberNode.create('30');
      final argument = SequenceNode(
        id: NodeId.generate(),
        children: [argNumber],
      );
      final function = FunctionNode(
        id: NodeId.generate(),
        function: MathFunction.sin,
        argument: argument,
      );
      final root = SequenceNode(id: NodeId.generate(), children: [function]);
      final doc = TreeExpressionDocument(
        root: root,
        cursor: CursorPosition(
          sequenceId: argument.id,
          nodeOffset: 1, // argument 末端
        ),
      );

      final moved = navigator.moveRight(doc);

      // 離開 argument，停在 root 中 function 後方（nodeOffset == 1）。
      expect(moved.cursor.sequenceId, root.id);
      expect(moved.cursor.nodeOffset, 1);
      expect(moved.cursor.textOffset, isNull);
    });

    test('sin(|30) 向左 -> 離開 argument 回到 function 前方', () {
      final argNumber = NumberNode.create('30');
      final argument = SequenceNode(
        id: NodeId.generate(),
        children: [argNumber],
      );
      final function = FunctionNode(
        id: NodeId.generate(),
        function: MathFunction.sin,
        argument: argument,
      );
      final root = SequenceNode(id: NodeId.generate(), children: [function]);
      final doc = TreeExpressionDocument(
        root: root,
        cursor: CursorPosition(
          sequenceId: argument.id,
          nodeOffset: 0, // argument 開頭
        ),
      );

      final moved = navigator.moveLeft(doc);

      // 離開 argument，停在 root 中 function 前方（nodeOffset == 0）。
      expect(moved.cursor.sequenceId, root.id);
      expect(moved.cursor.nodeOffset, 0);
      expect(moved.cursor.textOffset, isNull);
    });

    test('function 前方間隙向右 -> 進入 argument 開頭', () {
      final argument = SequenceNode.empty();
      final function = FunctionNode(
        id: NodeId.generate(),
        function: MathFunction.log10,
        argument: argument,
      );
      final root = SequenceNode(id: NodeId.generate(), children: [function]);
      final doc = TreeExpressionDocument(
        root: root,
        cursor: CursorPosition(sequenceId: root.id, nodeOffset: 0),
      );

      final moved = navigator.moveRight(doc);

      expect(moved.cursor.sequenceId, argument.id);
      expect(moved.cursor.nodeOffset, 0);
    });

    test('function 後方間隙向左 -> 進入 argument 末端', () {
      final argNumber = NumberNode.create('100');
      final argument = SequenceNode(
        id: NodeId.generate(),
        children: [argNumber],
      );
      final function = FunctionNode(
        id: NodeId.generate(),
        function: MathFunction.log10,
        argument: argument,
      );
      final root = SequenceNode(id: NodeId.generate(), children: [function]);
      final doc = TreeExpressionDocument(
        root: root,
        cursor: CursorPosition(sequenceId: root.id, nodeOffset: 1),
      );

      final moved = navigator.moveLeft(doc);

      expect(moved.cursor.sequenceId, argument.id);
      expect(moved.cursor.nodeOffset, 1); // argument 末端
    });
  });

  // 單一 child-sequence owner（function / group / root）的「隱形中間步」回歸：
  // 游標在末端 NumberNode 文字末端（或開頭）時，單次方向鍵應合併步驟、
  // 直接離開 owner，避免「按一下視覺無變化、需按兩下」。
  group('invisible-step skip（單一 sequence owner）', () {
    test('sin(30|) 文字末端向右一下 -> 直接離開 function 至 root', () {
      final argument = SequenceNode(
        id: NodeId.generate(),
        children: [NumberNode.create('30')],
      );
      final function = FunctionNode(
        id: NodeId.generate(),
        function: MathFunction.sin,
        argument: argument,
      );
      final root = SequenceNode(id: NodeId.generate(), children: [function]);
      final doc = TreeExpressionDocument(
        root: root,
        cursor: CursorPosition(
          sequenceId: argument.id,
          nodeOffset: 0,
          textOffset: 2, // 30|
        ),
      );

      final moved = navigator.moveRight(doc);

      expect(moved.cursor.sequenceId, root.id);
      expect(moved.cursor.nodeOffset, 1); // function 後方間隙
      expect(moved.cursor.textOffset, isNull);
    });

    test('sin(|30) 文字開頭向左一下 -> 直接離開 function 至前方間隙', () {
      final argument = SequenceNode(
        id: NodeId.generate(),
        children: [NumberNode.create('30')],
      );
      final function = FunctionNode(
        id: NodeId.generate(),
        function: MathFunction.sin,
        argument: argument,
      );
      final root = SequenceNode(id: NodeId.generate(), children: [function]);
      final doc = TreeExpressionDocument(
        root: root,
        cursor: CursorPosition(
          sequenceId: argument.id,
          nodeOffset: 0,
          textOffset: 0, // |30
        ),
      );

      final moved = navigator.moveLeft(doc);

      expect(moved.cursor.sequenceId, root.id);
      expect(moved.cursor.nodeOffset, 0); // function 前方間隙
      expect(moved.cursor.textOffset, isNull);
    });

    test('group content 文字末端向右一下 -> 直接離開 group', () {
      final content = SequenceNode(
        id: NodeId.generate(),
        children: [NumberNode.create('5')],
      );
      final group = GroupNode(id: NodeId.generate(), content: content);
      final root = SequenceNode(id: NodeId.generate(), children: [group]);
      final doc = TreeExpressionDocument(
        root: root,
        cursor: CursorPosition(
          sequenceId: content.id,
          nodeOffset: 0,
          textOffset: 1, // 5|
        ),
      );

      final moved = navigator.moveRight(doc);

      expect(moved.cursor.sequenceId, root.id);
      expect(moved.cursor.nodeOffset, 1); // group 後方間隙
    });

    test('square root radicand 文字末端向右一下 -> 直接離開 root', () {
      final radicand = SequenceNode(
        id: NodeId.generate(),
        children: [NumberNode.create('2')],
      );
      final root = RootNode(
        id: NodeId.generate(),
        radicand: radicand,
      );
      final sequence = SequenceNode(
        id: NodeId.generate(),
        children: [root],
      );
      final doc = TreeExpressionDocument(
        root: sequence,
        cursor: CursorPosition(
          sequenceId: radicand.id,
          nodeOffset: 0,
          textOffset: 1, // 2|
        ),
      );

      final moved = navigator.moveRight(doc);

      expect(moved.cursor.sequenceId, sequence.id);
      expect(moved.cursor.nodeOffset, 1); // root 後方間隙
    });
  });

  group('多 sequence owner 單次方向鍵跨越 sibling（消除隱形間隙步）', () {
    test('Fraction numerator 文字末端向右一下 -> 直接進入 denominator 開頭', () {
      final numerator = SequenceNode(
        id: NodeId.generate(),
        children: [NumberNode.create('1')],
      );
      final denominator = SequenceNode(
        id: NodeId.generate(),
        children: [NumberNode.create('2')],
      );
      final fraction = FractionNode(
        id: NodeId.generate(),
        numerator: numerator,
        denominator: denominator,
      );
      final root = SequenceNode(id: NodeId.generate(), children: [fraction]);
      final doc = TreeExpressionDocument(
        root: root,
        cursor: CursorPosition(
          sequenceId: numerator.id,
          nodeOffset: 0,
          textOffset: 1, // 1|
        ),
      );

      final moved = navigator.moveRight(doc);

      // 有 sibling sequence（denominator）：直接跳過間隙步，進入 denominator 開頭。
      expect(moved.cursor.sequenceId, denominator.id);
      expect(moved.cursor.nodeOffset, 0);
    });

    test('Fraction denominator 文字開頭向左一下 -> 直接進入 numerator 末端', () {
      final numerator = SequenceNode(
        id: NodeId.generate(),
        children: [NumberNode.create('1')],
      );
      final denominator = SequenceNode(
        id: NodeId.generate(),
        children: [NumberNode.create('2')],
      );
      final fraction = FractionNode(
        id: NodeId.generate(),
        numerator: numerator,
        denominator: denominator,
      );
      final root = SequenceNode(id: NodeId.generate(), children: [fraction]);
      final doc = TreeExpressionDocument(
        root: root,
        cursor: CursorPosition(
          sequenceId: denominator.id,
          nodeOffset: 0,
          textOffset: 0, // |2
        ),
      );

      final moved = navigator.moveLeft(doc);

      // 有 sibling sequence（numerator）：直接跳過間隙步，進入 numerator 末端。
      expect(moved.cursor.sequenceId, numerator.id);
      expect(moved.cursor.nodeOffset, 1);
      expect(moved.cursor.textOffset, isNull);
    });

    test('MixedFraction whole 文字末端向右一下 -> 直接進入 numerator 開頭', () {
      final whole = SequenceNode(
        id: NodeId.generate(),
        children: [NumberNode.create('1')],
      );
      final numerator = SequenceNode.empty();
      final denominator = SequenceNode.empty();
      final mixed = MixedFractionNode(
        id: NodeId.generate(),
        whole: whole,
        numerator: numerator,
        denominator: denominator,
      );
      final root = SequenceNode(id: NodeId.generate(), children: [mixed]);
      final doc = TreeExpressionDocument(
        root: root,
        cursor: CursorPosition(
          sequenceId: whole.id,
          nodeOffset: 0,
          textOffset: 1, // 1|
        ),
      );

      final moved = navigator.moveRight(doc);

      expect(moved.cursor.sequenceId, numerator.id);
      expect(moved.cursor.nodeOffset, 0);
    });

    test('MixedFraction numerator 文字末端向右一下 -> 直接進入 denominator 開頭', () {
      final whole = SequenceNode.empty();
      final numerator = SequenceNode(
        id: NodeId.generate(),
        children: [NumberNode.create('2')],
      );
      final denominator = SequenceNode.empty();
      final mixed = MixedFractionNode(
        id: NodeId.generate(),
        whole: whole,
        numerator: numerator,
        denominator: denominator,
      );
      final root = SequenceNode(id: NodeId.generate(), children: [mixed]);
      final doc = TreeExpressionDocument(
        root: root,
        cursor: CursorPosition(
          sequenceId: numerator.id,
          nodeOffset: 0,
          textOffset: 1, // 2|
        ),
      );

      final moved = navigator.moveRight(doc);

      expect(moved.cursor.sequenceId, denominator.id);
      expect(moved.cursor.nodeOffset, 0);
    });
  });

  group('FractionNode left/right navigation', () {
    late FractionNode fraction;
    late SequenceNode root;

    setUp(() {
      fraction = FractionNode.empty();
      root = SequenceNode(id: NodeId.generate(), children: [fraction]);
    });

    test('numerator 末端向右 -> denominator 開頭', () {
      final doc = TreeExpressionDocument(
        root: root,
        cursor: CursorPosition(
          sequenceId: fraction.numerator.id,
          nodeOffset: 0,
        ),
      );

      final moved = navigator.moveRight(doc);

      expect(moved.cursor.sequenceId, fraction.denominator.id);
      expect(moved.cursor.nodeOffset, 0);
    });

    test('denominator 開頭向左 -> numerator 末端', () {
      final doc = TreeExpressionDocument(
        root: root,
        cursor: CursorPosition(
          sequenceId: fraction.denominator.id,
          nodeOffset: 0,
        ),
      );

      final moved = navigator.moveLeft(doc);

      expect(moved.cursor.sequenceId, fraction.numerator.id);
      // numerator 為空，末端 nodeOffset == 0。
      expect(moved.cursor.nodeOffset, 0);
    });
  });

  group('FractionNode up/down navigation', () {
    test('denominator 向上 -> numerator，保留水平位置', () {
      final numerator = SequenceNode(
        id: NodeId.generate(),
        children: [
          NumberNode.create('1'),
          NumberNode.create('2'),
          NumberNode.create('3'),
        ],
      );
      final denominator = SequenceNode(
        id: NodeId.generate(),
        children: [NumberNode.create('4'), NumberNode.create('5')],
      );
      final fraction = FractionNode(
        id: NodeId.generate(),
        numerator: numerator,
        denominator: denominator,
      );
      final root = SequenceNode(id: NodeId.generate(), children: [fraction]);
      final doc = TreeExpressionDocument(
        root: root,
        cursor: CursorPosition(
          sequenceId: denominator.id,
          nodeOffset: 2, // 越過 denominator 末端
        ),
      );

      final moved = navigator.moveUp(doc);

      expect(moved.cursor.sequenceId, numerator.id);
      // nodeOffset 2 clamp 到 numerator 的合法範圍 (3)。
      expect(moved.cursor.nodeOffset, 2);
    });

    test('numerator 向下 -> denominator，保留並 clamp 水平位置', () {
      final numerator = SequenceNode(
        id: NodeId.generate(),
        children: [
          NumberNode.create('1'),
          NumberNode.create('2'),
          NumberNode.create('3'),
        ],
      );
      final denominator = SequenceNode(
        id: NodeId.generate(),
        children: [NumberNode.create('4')],
      );
      final fraction = FractionNode(
        id: NodeId.generate(),
        numerator: numerator,
        denominator: denominator,
      );
      final root = SequenceNode(id: NodeId.generate(), children: [fraction]);
      final doc = TreeExpressionDocument(
        root: root,
        cursor: CursorPosition(sequenceId: numerator.id, nodeOffset: 2),
      );

      final moved = navigator.moveDown(doc);

      expect(moved.cursor.sequenceId, denominator.id);
      expect(moved.cursor.nodeOffset, 1); // clamp 至 denominator 末端
    });
  });

  group('PowerNode navigation', () {
    test('base 向上 -> exponent', () {
      final power = PowerNode.empty();
      final root = SequenceNode(id: NodeId.generate(), children: [power]);
      final doc = TreeExpressionDocument(
        root: root,
        cursor: CursorPosition(sequenceId: power.base.id, nodeOffset: 0),
      );

      final moved = navigator.moveUp(doc);

      expect(moved.cursor.sequenceId, power.exponent.id);
    });

    test('exponent 向下 -> base', () {
      final power = PowerNode.empty();
      final root = SequenceNode(id: NodeId.generate(), children: [power]);
      final doc = TreeExpressionDocument(
        root: root,
        cursor: CursorPosition(sequenceId: power.exponent.id, nodeOffset: 0),
      );

      final moved = navigator.moveDown(doc);

      expect(moved.cursor.sequenceId, power.base.id);
    });

    test('base 開頭向上不離開 power（base 沒有上方目標）', () {
      final power = PowerNode.empty();
      final root = SequenceNode(id: NodeId.generate(), children: [power]);
      final cursor = CursorPosition(sequenceId: power.base.id, nodeOffset: 0);
      final doc = TreeExpressionDocument(root: root, cursor: cursor);

      final moved = navigator.moveDown(doc);

      // exponent 向下才會到 base；base 向下沒有目標，保持不動。
      expect(moved.cursor, cursor);
    });
  });

  group('RootNode navigation', () {
    test('square root radicand 開頭向左不 throw', () {
      final root = RootNode.squareRoot();
      final sequence = SequenceNode(id: NodeId.generate(), children: [root]);
      final doc = TreeExpressionDocument(
        root: sequence,
        cursor: CursorPosition(sequenceId: root.radicand.id, nodeOffset: 0),
      );

      final moved = navigator.moveLeft(doc);

      // 離開 radicand 至 owner 前方間隙。
      expect(moved.cursor.sequenceId, sequence.id);
      expect(moved.cursor.nodeOffset, 0);
    });

    test('square root radicand 末端向右不 throw', () {
      final root = RootNode.squareRoot();
      final sequence = SequenceNode(id: NodeId.generate(), children: [root]);
      final doc = TreeExpressionDocument(
        root: sequence,
        cursor: CursorPosition(
          sequenceId: root.radicand.id,
          nodeOffset: 0, // 空 radicand 末端
        ),
      );

      final moved = navigator.moveRight(doc);

      expect(moved.cursor.sequenceId, sequence.id);
      expect(moved.cursor.nodeOffset, 1); // owner 後方間隙
    });

    test('nth root: degree 向下 -> radicand', () {
      final root = RootNode.nthRoot();
      final sequence = SequenceNode(id: NodeId.generate(), children: [root]);
      final doc = TreeExpressionDocument(
        root: sequence,
        cursor: CursorPosition(sequenceId: root.degree!.id, nodeOffset: 0),
      );

      final moved = navigator.moveDown(doc);

      expect(moved.cursor.sequenceId, root.radicand.id);
    });

    test('nth root: radicand 向上 -> degree', () {
      final root = RootNode.nthRoot();
      final sequence = SequenceNode(id: NodeId.generate(), children: [root]);
      final doc = TreeExpressionDocument(
        root: sequence,
        cursor: CursorPosition(sequenceId: root.radicand.id, nodeOffset: 0),
      );

      final moved = navigator.moveUp(doc);

      expect(moved.cursor.sequenceId, root.degree!.id);
    });

    test('square root 向上沒有 degree，保持不動', () {
      final root = RootNode.squareRoot();
      final sequence = SequenceNode(id: NodeId.generate(), children: [root]);
      final cursor = CursorPosition(
        sequenceId: root.radicand.id,
        nodeOffset: 0,
      );
      final doc = TreeExpressionDocument(root: sequence, cursor: cursor);

      final moved = navigator.moveUp(doc);

      expect(moved.cursor, cursor);
    });
  });

  group('GroupNode navigation', () {
    test('group content 末端向右 -> owner 後方間隙', () {
      final inner = NumberNode.create('5');
      final content = SequenceNode(id: NodeId.generate(), children: [inner]);
      final group = GroupNode(id: NodeId.generate(), content: content);
      final root = SequenceNode(id: NodeId.generate(), children: [group]);
      final doc = TreeExpressionDocument(
        root: root,
        cursor: CursorPosition(sequenceId: content.id, nodeOffset: 1),
      );

      final moved = navigator.moveRight(doc);

      expect(moved.cursor.sequenceId, root.id);
      expect(moved.cursor.nodeOffset, 1);
    });

    test('group 前方向右 -> content 開頭', () {
      final content = SequenceNode.empty();
      final group = GroupNode(id: NodeId.generate(), content: content);
      final root = SequenceNode(id: NodeId.generate(), children: [group]);
      final doc = TreeExpressionDocument(
        root: root,
        cursor: CursorPosition(sequenceId: root.id, nodeOffset: 0),
      );

      final moved = navigator.moveRight(doc);

      expect(moved.cursor.sequenceId, content.id);
      expect(moved.cursor.nodeOffset, 0);
    });
  });

  group('invalid cursor recovery', () {
    test('未知 sequenceId clamp 至 root 結尾後保持穩定', () {
      final root = SequenceNode(
        id: NodeId.generate(),
        children: [NumberNode.create('1')],
      );
      final doc = TreeExpressionDocument(
        root: root,
        cursor: CursorPosition(sequenceId: NodeId('ghost'), nodeOffset: 9),
      );

      // clampCursor 將未知 sequenceId 回復到 root 結尾 (nodeOffset == 1)。
      // 在 root 末端向右已無路可走，游標穩定停留在 root 結尾。
      final moved = navigator.moveRight(doc);

      expect(moved.cursor.sequenceId, root.id);
      expect(moved.cursor.nodeOffset, 1); // root 末端
      expect(moved.cursor.textOffset, isNull);
    });

    test('越界 nodeOffset 被 clamp 後再移動', () {
      final number = NumberNode.create('1');
      final root = SequenceNode(id: NodeId.generate(), children: [number]);
      final doc = TreeExpressionDocument(
        root: root,
        cursor: CursorPosition(sequenceId: root.id, nodeOffset: 50),
      );

      // nodeOffset 50 clamp 至 1（root 末端）；向左遇到 number，進入其末端。
      final moved = navigator.moveLeft(doc);

      expect(moved.cursor.sequenceId, root.id);
      expect(moved.cursor.nodeOffset, 0);
      expect(moved.cursor.textOffset, 1);
    });
  });
}
