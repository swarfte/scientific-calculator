import 'package:flutter_test/flutter_test.dart';
import 'package:scientific_calculator/features/calculator/model/expression/cursor_position.dart';
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
import 'package:scientific_calculator/features/calculator/model/expression/tree_expression_document.dart';
import 'package:scientific_calculator/features/calculator/service/expression_navigator.dart';
import 'package:scientific_calculator/features/calculator/service/tree_expression_editor.dart';

/// Phase 4 editor 測試。
///
/// 驗證所有按鍵操作直接修改 Tree，回傳 immutable document，且與 Navigator
/// 可組合使用。
void main() {
  const editor = TreeExpressionEditor();

  group('digit input', () {
    test('連續輸入 1, 2, 3 合併為單一 NumberNode "123"', () {
      var doc = TreeExpressionDocument.empty();
      doc = editor.insertDigit(doc, '1');
      doc = editor.insertDigit(doc, '2');
      doc = editor.insertDigit(doc, '3');

      expect(doc.root.children.length, 1);
      expect((doc.root.children.first as NumberNode).value, '123');
      // cursor 在 NumberNode 末端。
      expect(doc.cursor.sequenceId, doc.root.id);
      expect(doc.cursor.nodeOffset, 0);
      expect(doc.cursor.textOffset, 3);
    });

    test('在 1|23 插入 9 -> 19|23（保留同一 NumberNode ID）', () {
      final number = NumberNode.create('123');
      final root = SequenceNode(id: NodeId.generate(), children: [number]);
      var doc = TreeExpressionDocument(
        root: root,
        cursor: CursorPosition(
          sequenceId: root.id,
          nodeOffset: 0,
          textOffset: 1,
        ),
      );

      doc = editor.insertDigit(doc, '9');

      expect(doc.root.children.length, 1);
      final updated = doc.root.children.first as NumberNode;
      expect(updated.value, '1923');
      expect(updated.id, number.id); // ID 保留
      expect(doc.cursor.textOffset, 2);
    });

    test('gap 末端插入數字建立新 NumberNode', () {
      final op = OperatorNode.create(ExpressionOperator.add);
      final root = SequenceNode(id: NodeId.generate(), children: [op]);
      var doc = TreeExpressionDocument(
        root: root,
        cursor: CursorPosition(sequenceId: root.id, nodeOffset: 1),
      );

      doc = editor.insertDigit(doc, '5');

      expect(doc.root.children.length, 2);
      expect((doc.root.children[1] as NumberNode).value, '5');
      expect(doc.cursor.nodeOffset, 1);
      expect(doc.cursor.textOffset, 1);
    });
  });

  group('decimal point', () {
    test('空位置按 . 建立 0.', () {
      var doc = TreeExpressionDocument.empty();
      doc = editor.insertDecimalPoint(doc);

      expect(doc.root.children.length, 1);
      expect((doc.root.children.first as NumberNode).value, '0.');
      expect(doc.cursor.textOffset, 2);
    });

    test('同一 NumberNode 不能有兩個小數點', () {
      final number = NumberNode.create('1.5');
      final root = SequenceNode(id: NodeId.generate(), children: [number]);
      final doc = TreeExpressionDocument(
        root: root,
        cursor: CursorPosition(
          sequenceId: root.id,
          nodeOffset: 0,
          textOffset: 3,
        ),
      );

      final result = editor.insertDecimalPoint(doc);

      // 不變。
      expect(result.root, same(doc.root));
      expect((result.root.children.first as NumberNode).value, '1.5');
    });
  });

  group('operator', () {
    test('空 sequence 只允許 unary subtract', () {
      var doc = TreeExpressionDocument.empty();

      // add 不被允許。
      final addResult = editor.insertOperator(doc, ExpressionOperator.add);
      expect(addResult.root.isEmpty, isTrue);

      // subtract 被允許。
      final subResult = editor.insertOperator(doc, ExpressionOperator.subtract);
      expect(subResult.root.children.length, 1);
      expect(
        (subResult.root.children.first as OperatorNode).operator,
        ExpressionOperator.subtract,
      );
      expect(subResult.cursor.nodeOffset, 1);
    });

    test('連續 operator 替換前一個', () {
      final op1 = OperatorNode.create(ExpressionOperator.add);
      final root = SequenceNode(id: NodeId.generate(), children: [op1]);
      final doc = TreeExpressionDocument(
        root: root,
        cursor: CursorPosition(sequenceId: root.id, nodeOffset: 1),
      );

      final result = editor.insertOperator(doc, ExpressionOperator.multiply);

      expect(result.root.children.length, 1);
      expect(
        (result.root.children.first as OperatorNode).operator,
        ExpressionOperator.multiply,
      );
    });

    test('乘號後接負號例外保留（允許 3*-2）', () {
      final mul = OperatorNode.create(ExpressionOperator.multiply);
      final root = SequenceNode(id: NodeId.generate(), children: [mul]);
      final doc = TreeExpressionDocument(
        root: root,
        cursor: CursorPosition(sequenceId: root.id, nodeOffset: 1),
      );

      final result = editor.insertOperator(doc, ExpressionOperator.subtract);

      expect(result.root.children.length, 2);
      expect(
        (result.root.children[0] as OperatorNode).operator,
        ExpressionOperator.multiply,
      );
      expect(
        (result.root.children[1] as OperatorNode).operator,
        ExpressionOperator.subtract,
      );
    });

    test('text mode 輸入 operator 先離開 NumberNode', () {
      final number = NumberNode.create('5');
      final root = SequenceNode(id: NodeId.generate(), children: [number]);
      final doc = TreeExpressionDocument(
        root: root,
        cursor: CursorPosition(
          sequenceId: root.id,
          nodeOffset: 0,
          textOffset: 1,
        ),
      );

      final result = editor.insertOperator(doc, ExpressionOperator.add);

      expect(result.root.children.length, 2);
      expect((result.root.children[0] as NumberNode).value, '5');
      expect(
        (result.root.children[1] as OperatorNode).operator,
        ExpressionOperator.add,
      );
      expect(result.cursor.nodeOffset, 2);
    });
  });

  group('function', () {
    test('建立函數並將 cursor 移入 argument 開頭', () {
      var doc = TreeExpressionDocument.empty();
      doc = editor.insertFunction(doc, MathFunction.sin);

      expect(doc.root.children.length, 1);
      final fn = doc.root.children.first as FunctionNode;
      expect(fn.function, MathFunction.sin);
      expect(fn.argument.isEmpty, isTrue);
      expect(doc.cursor.sequenceId, fn.argument.id);
      expect(doc.cursor.nodeOffset, 0);
    });

    test('函數 argument 內可繼續輸入數字', () {
      var doc = editor.insertFunction(
        TreeExpressionDocument.empty(),
        MathFunction.sin,
      );
      doc = editor.insertDigit(doc, '3');
      doc = editor.insertDigit(doc, '0');

      final fn = doc.root.children.first as FunctionNode;
      expect((fn.argument.children.first as NumberNode).value, '30');
    });
  });

  group('fraction', () {
    test('空位置建空 FractionNode，cursor 進 numerator', () {
      var doc = editor.insertFraction(TreeExpressionDocument.empty());

      expect(doc.root.children.length, 1);
      final frac = doc.root.children.first as FractionNode;
      expect(frac.numerator.isEmpty, isTrue);
      expect(frac.denominator.isEmpty, isTrue);
      expect(doc.cursor.sequenceId, frac.numerator.id);
    });

    test('33| 按 a/b：提升 33 為 numerator，cursor 進 denominator', () {
      final number = NumberNode.create('33');
      final root = SequenceNode(id: NodeId.generate(), children: [number]);
      final doc = TreeExpressionDocument(
        root: root,
        cursor: CursorPosition(
          sequenceId: root.id,
          nodeOffset: 0,
          textOffset: 2,
        ),
      );

      final result = editor.insertFraction(doc);

      expect(result.root.children.length, 1);
      final frac = result.root.children.first as FractionNode;
      expect((frac.numerator.children.first as NumberNode).value, '33');
      expect(frac.denominator.isEmpty, isTrue);
      expect(result.cursor.sequenceId, frac.denominator.id);
    });
  });

  group('root', () {
    test('square root 建立 RootNode，cursor 進 radicand', () {
      var doc = editor.insertSquareRoot(TreeExpressionDocument.empty());

      final root = doc.root.children.first as RootNode;
      expect(root.isSquareRoot, isTrue);
      expect(doc.cursor.sequenceId, root.radicand.id);
    });

    test('nth root 有 degree，cursor 先進 degree（先輸次方數）', () {
      var doc = editor.insertNthRoot(TreeExpressionDocument.empty());

      final root = doc.root.children.first as RootNode;
      expect(root.isSquareRoot, isFalse);
      expect(root.degree, isNotNull);
      expect(doc.cursor.sequenceId, root.degree!.id);
    });
  });

  group('power', () {
    test('5| 按 x^y：提升 5 為 base，空 exponent，cursor 進 exponent', () {
      final number = NumberNode.create('5');
      final rootSeq = SequenceNode(id: NodeId.generate(), children: [number]);
      final doc = TreeExpressionDocument(
        root: rootSeq,
        cursor: CursorPosition(
          sequenceId: rootSeq.id,
          nodeOffset: 0,
          textOffset: 1,
        ),
      );

      final result = editor.insertPower(doc);

      expect(result.root.children.length, 1);
      final power = result.root.children.first as PowerNode;
      expect((power.base.children.first as NumberNode).value, '5');
      expect(power.exponent.isEmpty, isTrue);
      expect(result.cursor.sequenceId, power.exponent.id);
    });

    test('5| 按 x^2：exponent 為 2，cursor 移到 PowerNode 後方', () {
      final number = NumberNode.create('5');
      final rootSeq = SequenceNode(id: NodeId.generate(), children: [number]);
      final doc = TreeExpressionDocument(
        root: rootSeq,
        cursor: CursorPosition(
          sequenceId: rootSeq.id,
          nodeOffset: 0,
          textOffset: 1,
        ),
      );

      final result = editor.insertSquare(doc);

      expect(result.root.children.length, 1);
      final power = result.root.children.first as PowerNode;
      expect((power.exponent.children.first as NumberNode).value, '2');
      expect(result.cursor.sequenceId, result.root.id);
      expect(result.cursor.nodeOffset, 1);
      expect(result.cursor.textOffset, isNull);
    });
  });

  group('constant and group', () {
    test('insertConstant 加入 ConstantNode，cursor 在後方', () {
      var doc = editor.insertConstant(
        TreeExpressionDocument.empty(),
        MathConstant.pi,
      );

      expect(
        (doc.root.children.first as ConstantNode).constant,
        MathConstant.pi,
      );
      expect(doc.cursor.nodeOffset, 1);
    });

    test('insertGroup 建立 GroupNode，cursor 進 content', () {
      var doc = editor.insertGroup(TreeExpressionDocument.empty());

      final group = doc.root.children.first as GroupNode;
      expect(group.content.isEmpty, isTrue);
      expect(doc.cursor.sequenceId, group.content.id);
    });
  });

  group('backspace', () {
    test('NumberNode 內刪一字元', () {
      final number = NumberNode.create('123');
      final root = SequenceNode(id: NodeId.generate(), children: [number]);
      final doc = TreeExpressionDocument(
        root: root,
        cursor: CursorPosition(
          sequenceId: root.id,
          nodeOffset: 0,
          textOffset: 3,
        ),
      );

      final result = editor.backspace(doc);
      expect((result.root.children.first as NumberNode).value, '12');
      expect(result.cursor.textOffset, 2);
    });

    test('NumberNode 變空後移除 NumberNode', () {
      final number = NumberNode.create('7');
      final root = SequenceNode(id: NodeId.generate(), children: [number]);
      final doc = TreeExpressionDocument(
        root: root,
        cursor: CursorPosition(
          sequenceId: root.id,
          nodeOffset: 0,
          textOffset: 1,
        ),
      );

      final result = editor.backspace(doc);
      expect(result.root.children.isEmpty, isTrue);
      expect(result.cursor.nodeOffset, 0);
    });

    test('gap 前方為簡單 node 移除該 node', () {
      final op = OperatorNode.create(ExpressionOperator.add);
      final root = SequenceNode(id: NodeId.generate(), children: [op]);
      final doc = TreeExpressionDocument(
        root: root,
        cursor: CursorPosition(sequenceId: root.id, nodeOffset: 1),
      );

      final result = editor.backspace(doc);
      expect(result.root.children.isEmpty, isTrue);
      expect(result.cursor.nodeOffset, 0);
    });

    test('空 FunctionNode argument 開頭按 DEL 移除 FunctionNode', () {
      final fn = FunctionNode.create(MathFunction.sin);
      final root = SequenceNode(id: NodeId.generate(), children: [fn]);
      final doc = TreeExpressionDocument(
        root: root,
        cursor: CursorPosition(sequenceId: fn.argument.id, nodeOffset: 0),
      );

      final result = editor.backspace(doc);
      expect(result.root.children.isEmpty, isTrue);
      expect(result.cursor.sequenceId, result.root.id);
    });

    test('空 RootNode radicand 開頭按 DEL 移除 RootNode', () {
      final root = RootNode.squareRoot();
      final seq = SequenceNode(id: NodeId.generate(), children: [root]);
      final doc = TreeExpressionDocument(
        root: seq,
        cursor: CursorPosition(sequenceId: root.radicand.id, nodeOffset: 0),
      );

      final result = editor.backspace(doc);
      expect(result.root.children.isEmpty, isTrue);
    });

    test('空 Fraction denominator 開頭按 DEL 回到 numerator 末端', () {
      final numerator = SequenceNode(
        id: NodeId.generate(),
        children: [NumberNode.create('3')],
      );
      final fraction = FractionNode(
        id: NodeId.generate(),
        numerator: numerator,
        denominator: SequenceNode.empty(),
      );
      final root = SequenceNode(id: NodeId.generate(), children: [fraction]);
      final doc = TreeExpressionDocument(
        root: root,
        cursor: CursorPosition(
          sequenceId: fraction.denominator.id,
          nodeOffset: 0,
        ),
      );

      final result = editor.backspace(doc);
      // 回到 numerator 末端，Tree 結構不變。
      expect(result.cursor.sequenceId, numerator.id);
      expect(result.cursor.nodeOffset, 1);
      expect(result.root, same(doc.root));
    });

    test('空 PowerNode exponent 開頭按 DEL 解除並保留 base', () {
      final number = NumberNode.create('5');
      final power = PowerNode(
        id: NodeId.generate(),
        base: SequenceNode(id: NodeId.generate(), children: [number]),
        exponent: SequenceNode.empty(),
      );
      final root = SequenceNode(id: NodeId.generate(), children: [power]);
      final doc = TreeExpressionDocument(
        root: root,
        cursor: CursorPosition(sequenceId: power.exponent.id, nodeOffset: 0),
      );

      final result = editor.backspace(doc);
      expect(result.root.children.length, 1);
      // PowerNode 降級為 base 內的 NumberNode。
      expect(result.root.children.first, isA<NumberNode>());
      expect((result.root.children.first as NumberNode).id, number.id);
    });
  });

  group('immutable / id stability', () {
    test('深層修改保持其他 node ID 不變', () {
      // root -> fraction -> denominator -> function -> argument
      final argument = SequenceNode.empty();
      final fn = FunctionNode(
        id: NodeId.generate(),
        function: MathFunction.sin,
        argument: argument,
      );
      final denominator = SequenceNode(id: NodeId.generate(), children: [fn]);
      final numerator = SequenceNode(
        id: NodeId.generate(),
        children: [NumberNode.create('1')],
      );
      final fraction = FractionNode(
        id: NodeId.generate(),
        numerator: numerator,
        denominator: denominator,
      );
      final root = SequenceNode(id: NodeId.generate(), children: [fraction]);
      final doc = TreeExpressionDocument(
        root: root,
        cursor: CursorPosition(sequenceId: argument.id, nodeOffset: 0),
      );

      // 在深層 argument 輸入數字。
      final result = editor.insertDigit(doc, '9');

      // numerator 的 NumberNode ID 不變。
      final resultRoot = result.root;
      final resultFrac = resultRoot.children.first as FractionNode;
      final resultNumeratorNumber = resultFrac.numerator.children.first;
      expect(resultNumeratorNumber.id, numerator.children.first.id);

      // argument 內新增了 NumberNode。
      final resultFn = resultFrac.denominator.children.first as FunctionNode;
      expect((resultFn.argument.children.first as NumberNode).value, '9');
      expect(result.cursor.sequenceId, argument.id);
    });
  });

  group('editor + navigator composition', () {
    test('輸入 sin 後向右離開 argument', () {
      const navigator = ExpressionNavigator();
      var doc = editor.insertFunction(
        TreeExpressionDocument.empty(),
        MathFunction.sin,
      );
      doc = editor.insertDigit(doc, '3');
      doc = editor.insertDigit(doc, '0');

      // cursor 在 NumberNode 30 文字末端；單次向右即合併隱形中間步、
      // 直接離開 function 至 root。
      doc = navigator.moveRight(doc);

      expect(doc.cursor.sequenceId, doc.root.id);
      expect(doc.cursor.nodeOffset, 1);
    });
  });

  group('clear', () {
    test('clear 回傳空 document', () {
      final number = NumberNode.create('123');
      final root = SequenceNode(id: NodeId.generate(), children: [number]);
      final doc = TreeExpressionDocument(
        root: root,
        cursor: CursorPosition(
          sequenceId: root.id,
          nodeOffset: 0,
          textOffset: 3,
        ),
      );

      final result = editor.clear(doc);
      expect(result.root.children.isEmpty, isTrue);
      expect(result.cursor.nodeOffset, 0);
    });
  });
}

// ignore_for_file: unused_local_variable
