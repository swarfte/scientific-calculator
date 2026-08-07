import '../model/expression/cursor_position.dart';
import '../model/expression/expression_node.dart';
import '../model/expression/node/constant_node.dart';
import '../model/expression/node/fraction_node.dart';
import '../model/expression/node/function_node.dart';
import '../model/expression/node/group_node.dart';
import '../model/expression/node/logarithm_node.dart';
import '../model/expression/node/mixed_fraction_node.dart';
import '../model/expression/node/number_node.dart';
import '../model/expression/node/operator_node.dart';
import '../model/expression/node/power_node.dart';
import '../model/expression/node/root_node.dart';
import '../model/expression/node/scientific_node.dart';
import '../model/expression/node/sequence_node.dart';
import '../model/expression/node_id.dart';
import '../model/expression/sequence_role.dart';
import '../model/expression/tree_expression_document.dart';
import '../model/expression/tree_index.dart';
import 'tree_rewriter.dart';

/// Expression Tree 的輸入編輯器。
///
/// 所有按鍵操作直接修改 immutable Expression Tree，並回傳新的
/// [TreeExpressionDocument]。不修改任何 expression string，也不依賴 TeX。
///
/// 行為規格見 `EXPRESSION_TREE_REFACTOR_PLAN.md` Phase 4。
class TreeExpressionEditor {
  const TreeExpressionEditor();

  // ---- 數字 ---------------------------------------------------------------

  /// 輸入一個數字字元（`0`-`9`）。
  TreeExpressionDocument insertDigit(
    TreeExpressionDocument document,
    String digit,
  ) {
    if (!RegExp(r'^[0-9]$').hasMatch(digit)) {
      return document;
    }

    final index = TreeIndex(document.root);
    final cursor = index.clampCursor(document.cursor);
    final sequence = index.findSequence(cursor.sequenceId);
    if (sequence == null) {
      return document;
    }

    final textOffset = cursor.textOffset;
    if (textOffset != null) {
      // text mode：在 textOffset 插入，保留 NumberNode ID。
      return _editCurrentNumber(
        index,
        document,
        sequence,
        cursor,
        (value) =>
            '${value.substring(0, textOffset)}$digit${value.substring(textOffset)}',
        textOffset + 1,
      );
    }

    // gap mode：先看左方是否為 NumberNode（可末端追加）。
    if (cursor.nodeOffset > 0) {
      final left = sequence.children[cursor.nodeOffset - 1];
      if (left is NumberNode) {
        final newValue = '${left.value}$digit';
        return _replaceAndMove(
          index: index,
          document: document,
          sequence: sequence,
          nodeIndex: cursor.nodeOffset - 1,
          newNode: left.copyWith(value: newValue),
          newCursor: CursorPosition(
            sequenceId: sequence.id,
            nodeOffset: cursor.nodeOffset - 1,
            textOffset: newValue.length,
          ),
        );
      }
    }

    // 右方是否為 NumberNode（可在開頭插入）。
    if (cursor.nodeOffset < sequence.children.length) {
      final right = sequence.children[cursor.nodeOffset];
      if (right is NumberNode) {
        final newValue = '$digit${right.value}';
        return _replaceAndMove(
          index: index,
          document: document,
          sequence: sequence,
          nodeIndex: cursor.nodeOffset,
          newNode: right.copyWith(value: newValue),
          newCursor: CursorPosition(
            sequenceId: sequence.id,
            nodeOffset: cursor.nodeOffset,
            textOffset: 1,
          ),
        );
      }
    }

    // 否則建立新 NumberNode。
    final number = NumberNode.create(digit);
    final newSequence = sequence.insert(cursor.nodeOffset, number);
    return _commit(
      index,
      document,
      newSequence,
      CursorPosition(
        sequenceId: sequence.id,
        nodeOffset: cursor.nodeOffset,
        textOffset: 1,
      ),
    );
  }

  /// 輸入小數點。
  TreeExpressionDocument insertDecimalPoint(TreeExpressionDocument document) {
    final index = TreeIndex(document.root);
    final cursor = index.clampCursor(document.cursor);
    final sequence = index.findSequence(cursor.sequenceId);
    if (sequence == null) {
      return document;
    }

    final textOffset = cursor.textOffset;
    if (textOffset != null) {
      final number = sequence.children[cursor.nodeOffset] as NumberNode;
      if (number.value.contains('.')) {
        // 同一 NumberNode 最多一個小數點。
        return document;
      }
      return _editCurrentNumber(
        index,
        document,
        sequence,
        cursor,
        (value) =>
            '${value.substring(0, textOffset)}.${value.substring(textOffset)}',
        textOffset + 1,
      );
    }

    // gap：左方 NumberNode 且無小數點 -> 末端追加。
    if (cursor.nodeOffset > 0) {
      final left = sequence.children[cursor.nodeOffset - 1];
      if (left is NumberNode && !left.value.contains('.')) {
        final newValue = '${left.value}.';
        return _replaceAndMove(
          index: index,
          document: document,
          sequence: sequence,
          nodeIndex: cursor.nodeOffset - 1,
          newNode: left.copyWith(value: newValue),
          newCursor: CursorPosition(
            sequenceId: sequence.id,
            nodeOffset: cursor.nodeOffset - 1,
            textOffset: newValue.length,
          ),
        );
      }
    }

    // 空位置建立 `0.`。
    final number = NumberNode.create('0.');
    final newSequence = sequence.insert(cursor.nodeOffset, number);
    return _commit(
      index,
      document,
      newSequence,
      CursorPosition(
        sequenceId: sequence.id,
        nodeOffset: cursor.nodeOffset,
        textOffset: 2,
      ),
    );
  }

  // ---- 運算符 -------------------------------------------------------------

  /// 輸入運算符（add / subtract / multiply / divide）。
  ///
  /// MVP 規則：
  /// - 空 sequence 只允許 unary subtract。
  /// - 連續 operator 替換前一個，但 `*` / `/` 後接 `-` 例外保留。
  /// - operator 後 cursor 位於其後方。
  TreeExpressionDocument insertOperator(
    TreeExpressionDocument document,
    ExpressionOperator operator,
  ) {
    final index = TreeIndex(document.root);
    final cursor = index.clampCursor(document.cursor);
    final sequence = index.findSequence(cursor.sequenceId);
    if (sequence == null) {
      return document;
    }

    // text mode：先離開 NumberNode 至後方間隙。
    final gapCursor = cursor.textOffset == null
        ? cursor
        : CursorPosition(
            sequenceId: cursor.sequenceId,
            nodeOffset: cursor.nodeOffset + 1,
          );
    final offset = gapCursor.nodeOffset;

    // 空 sequence：只允許 unary subtract。
    if (sequence.isEmpty) {
      if (operator != ExpressionOperator.subtract) {
        return document;
      }
      final op = OperatorNode.create(operator);
      final newSequence = sequence.insert(0, op);
      return _commit(
        index,
        document,
        newSequence,
        CursorPosition(sequenceId: sequence.id, nodeOffset: 1),
      );
    }

    // 連續 operator：替換前一個，但 */ 後接 - 例外保留。
    if (offset > 0) {
      final left = sequence.children[offset - 1];
      if (left is OperatorNode) {
        final allowsConsecutiveMinus =
            (left.operator == ExpressionOperator.multiply ||
                left.operator == ExpressionOperator.divide) &&
            operator == ExpressionOperator.subtract;
        if (!allowsConsecutiveMinus) {
          final newOp = OperatorNode.create(operator);
          final newSequence = sequence.replaceAt(offset - 1, newOp);
          return _commit(
            index,
            document,
            newSequence,
            CursorPosition(sequenceId: sequence.id, nodeOffset: offset),
          );
        }
      }
    }

    final op = OperatorNode.create(operator);
    final newSequence = sequence.insert(offset, op);
    return _commit(
      index,
      document,
      newSequence,
      CursorPosition(sequenceId: sequence.id, nodeOffset: offset + 1),
    );
  }

  // ---- 常數 / 函數 / 群組 --------------------------------------------------

  /// 輸入常數（pi / e / answer）。
  TreeExpressionDocument insertConstant(
    TreeExpressionDocument document,
    MathConstant constant,
  ) {
    final index = TreeIndex(document.root);
    final cursor = index.clampCursor(document.cursor);
    final sequence = index.findSequence(cursor.sequenceId);
    if (sequence == null) {
      return document;
    }

    final offset = _gapOffset(cursor, sequence);
    final node = ConstantNode.create(constant);
    final newSequence = sequence.insert(offset, node);
    return _commit(
      index,
      document,
      newSequence,
      CursorPosition(sequenceId: sequence.id, nodeOffset: offset + 1),
    );
  }

  /// 輸入函數（sin / cos / ... / abs）。游標進入 argument 開頭。
  TreeExpressionDocument insertFunction(
    TreeExpressionDocument document,
    MathFunction function,
  ) {
    final index = TreeIndex(document.root);
    final cursor = index.clampCursor(document.cursor);
    final sequence = index.findSequence(cursor.sequenceId);
    if (sequence == null) {
      return document;
    }

    final offset = _gapOffset(cursor, sequence);
    final node = FunctionNode.create(function);
    final newSequence = sequence.insert(offset, node);
    return _commit(
      index,
      document,
      newSequence,
      CursorPosition(sequenceId: node.argument.id, nodeOffset: 0),
    );
  }

  /// 輸入群組（明確括號）。游標進入 content 開頭。
  TreeExpressionDocument insertGroup(TreeExpressionDocument document) {
    final index = TreeIndex(document.root);
    final cursor = index.clampCursor(document.cursor);
    final sequence = index.findSequence(cursor.sequenceId);
    if (sequence == null) {
      return document;
    }

    final offset = _gapOffset(cursor, sequence);
    final node = GroupNode.empty();
    final newSequence = sequence.insert(offset, node);
    return _commit(
      index,
      document,
      newSequence,
      CursorPosition(sequenceId: node.content.id, nodeOffset: 0),
    );
  }

  // ---- 分數 ---------------------------------------------------------------

  /// 輸入分數。
  ///
  /// - 空位置：建立空 FractionNode，游標進入 numerator。
  /// - 左方為 NumberNode：提升為 numerator，游標進入 denominator。
  TreeExpressionDocument insertFraction(TreeExpressionDocument document) {
    final index = TreeIndex(document.root);
    final cursor = index.clampCursor(document.cursor);
    final sequence = index.findSequence(cursor.sequenceId);
    if (sequence == null) {
      return document;
    }

    final offset = _gapOffset(cursor, sequence);

    // 左方 NumberNode 提升為 numerator。
    if (offset > 0 && sequence.children[offset - 1] is NumberNode) {
      final left = sequence.children[offset - 1] as NumberNode;
      final fraction = FractionNode(
        id: NodeId.generate(),
        numerator: SequenceNode(id: NodeId.generate(), children: [left]),
        denominator: SequenceNode.empty(),
      );
      final newSequence = sequence
          .removeAt(offset - 1)
          .insert(offset - 1, fraction);
      return _commit(
        index,
        document,
        newSequence,
        CursorPosition(sequenceId: fraction.denominator.id, nodeOffset: 0),
      );
    }

    final fraction = FractionNode.empty();
    final newSequence = sequence.insert(offset, fraction);
    return _commit(
      index,
      document,
      newSequence,
      CursorPosition(sequenceId: fraction.numerator.id, nodeOffset: 0),
    );
  }

  // ---- 根號 / 指數 ---------------------------------------------------------

  /// 輸入平方根。游標進入 radicand。
  TreeExpressionDocument insertSquareRoot(TreeExpressionDocument document) {
    final index = TreeIndex(document.root);
    final cursor = index.clampCursor(document.cursor);
    final sequence = index.findSequence(cursor.sequenceId);
    if (sequence == null) {
      return document;
    }

    final offset = _gapOffset(cursor, sequence);
    final node = RootNode.squareRoot();
    final newSequence = sequence.insert(offset, node);
    return _commit(
      index,
      document,
      newSequence,
      CursorPosition(sequenceId: node.radicand.id, nodeOffset: 0),
    );
  }

  /// 輸入 n 次根。游標進入 radicand。
  TreeExpressionDocument insertNthRoot(TreeExpressionDocument document) {
    final index = TreeIndex(document.root);
    final cursor = index.clampCursor(document.cursor);
    final sequence = index.findSequence(cursor.sequenceId);
    if (sequence == null) {
      return document;
    }

    final offset = _gapOffset(cursor, sequence);
    final node = RootNode.nthRoot();
    final newSequence = sequence.insert(offset, node);
    return _commit(
      index,
      document,
      newSequence,
      CursorPosition(sequenceId: node.radicand.id, nodeOffset: 0),
    );
  }

  /// 輸入指數 `x^y`。左方 NumberNode 提升為 base，建立空 exponent，游標進入
  /// exponent。
  TreeExpressionDocument insertPower(TreeExpressionDocument document) {
    final index = TreeIndex(document.root);
    final cursor = index.clampCursor(document.cursor);
    final sequence = index.findSequence(cursor.sequenceId);
    if (sequence == null) {
      return document;
    }

    final offset = _gapOffset(cursor, sequence);

    if (offset > 0 && sequence.children[offset - 1] is NumberNode) {
      final left = sequence.children[offset - 1] as NumberNode;
      final power = PowerNode(
        id: NodeId.generate(),
        base: SequenceNode(id: NodeId.generate(), children: [left]),
        exponent: SequenceNode.empty(),
      );
      final newSequence = sequence
          .removeAt(offset - 1)
          .insert(offset - 1, power);
      return _commit(
        index,
        document,
        newSequence,
        CursorPosition(sequenceId: power.exponent.id, nodeOffset: 0),
      );
    }

    // 無左方 base：建立空 base 的 PowerNode，游標仍進 exponent。
    final power = PowerNode.empty();
    final newSequence = sequence.insert(offset, power);
    return _commit(
      index,
      document,
      newSequence,
      CursorPosition(sequenceId: power.exponent.id, nodeOffset: 0),
    );
  }

  /// 輸入平方 `x^2`。左方 NumberNode 提升為 base，exponent 為 `2`，游標移到
  /// PowerNode 後方。
  TreeExpressionDocument insertSquare(TreeExpressionDocument document) {
    final index = TreeIndex(document.root);
    final cursor = index.clampCursor(document.cursor);
    final sequence = index.findSequence(cursor.sequenceId);
    if (sequence == null) {
      return document;
    }

    final offset = _gapOffset(cursor, sequence);

    NumberNode? base;
    if (offset > 0 && sequence.children[offset - 1] is NumberNode) {
      base = sequence.children[offset - 1] as NumberNode;
    }

    final power = PowerNode(
      id: NodeId.generate(),
      base: base != null
          ? SequenceNode(id: NodeId.generate(), children: [base])
          : SequenceNode.empty(),
      exponent: SequenceNode(
        id: NodeId.generate(),
        children: [NumberNode.create('2')],
      ),
    );

    SequenceNode newSequence;
    int cursorOffset;
    if (base != null) {
      newSequence = sequence.removeAt(offset - 1).insert(offset - 1, power);
      cursorOffset = offset;
    } else {
      newSequence = sequence.insert(offset, power);
      cursorOffset = offset + 1;
    }

    return _commit(
      index,
      document,
      newSequence,
      CursorPosition(sequenceId: sequence.id, nodeOffset: cursorOffset),
    );
  }

  // ---- 對數 / 帶分數 / 科學記號 ---------------------------------------------

  /// 輸入任意底數對數 `log_xy`。
  ///
  /// - 左方為 NumberNode：提升為 argument，游標進入（空的）base。
  /// - 空位置：建立空 LogarithmNode，游標進入 argument。
  TreeExpressionDocument insertLogarithm(TreeExpressionDocument document) {
    final index = TreeIndex(document.root);
    final cursor = index.clampCursor(document.cursor);
    final sequence = index.findSequence(cursor.sequenceId);
    if (sequence == null) {
      return document;
    }

    final offset = _gapOffset(cursor, sequence);

    if (offset > 0 && sequence.children[offset - 1] is NumberNode) {
      final left = sequence.children[offset - 1] as NumberNode;
      final node = LogarithmNode(
        id: NodeId.generate(),
        base: SequenceNode.empty(),
        argument: SequenceNode(id: NodeId.generate(), children: [left]),
      );
      final newSequence = sequence
          .removeAt(offset - 1)
          .insert(offset - 1, node);
      return _commit(
        index,
        document,
        newSequence,
        CursorPosition(sequenceId: node.base.id, nodeOffset: 0),
      );
    }

    final node = LogarithmNode.empty();
    final newSequence = sequence.insert(offset, node);
    return _commit(
      index,
      document,
      newSequence,
      CursorPosition(sequenceId: node.argument.id, nodeOffset: 0),
    );
  }

  /// 輸入底數預設為 2 的對數（`log₂`），游標進入 argument。
  TreeExpressionDocument insertLogarithmBase2(
    TreeExpressionDocument document,
  ) {
    final index = TreeIndex(document.root);
    final cursor = index.clampCursor(document.cursor);
    final sequence = index.findSequence(cursor.sequenceId);
    if (sequence == null) {
      return document;
    }

    final offset = _gapOffset(cursor, sequence);
    final node = LogarithmNode.withDefaultBase(2);
    final newSequence = sequence.insert(offset, node);
    return _commit(
      index,
      document,
      newSequence,
      CursorPosition(sequenceId: node.argument.id, nodeOffset: 0),
    );
  }

  /// 輸入帶分數 `a b/c`。
  ///
  /// - 左方為 NumberNode：提升為 whole，游標進入 numerator。
  /// - 空位置：建立空 MixedFractionNode，游標進入 whole。
  TreeExpressionDocument insertMixedFraction(
    TreeExpressionDocument document,
  ) {
    final index = TreeIndex(document.root);
    final cursor = index.clampCursor(document.cursor);
    final sequence = index.findSequence(cursor.sequenceId);
    if (sequence == null) {
      return document;
    }

    final offset = _gapOffset(cursor, sequence);

    if (offset > 0 && sequence.children[offset - 1] is NumberNode) {
      final left = sequence.children[offset - 1] as NumberNode;
      final node = MixedFractionNode(
        id: NodeId.generate(),
        whole: SequenceNode(id: NodeId.generate(), children: [left]),
        numerator: SequenceNode.empty(),
        denominator: SequenceNode.empty(),
      );
      final newSequence = sequence
          .removeAt(offset - 1)
          .insert(offset - 1, node);
      return _commit(
        index,
        document,
        newSequence,
        CursorPosition(sequenceId: node.numerator.id, nodeOffset: 0),
      );
    }

    final node = MixedFractionNode.empty();
    final newSequence = sequence.insert(offset, node);
    return _commit(
      index,
      document,
      newSequence,
      CursorPosition(sequenceId: node.whole.id, nodeOffset: 0),
    );
  }

  /// 輸入科學記號 `Exp`（mantissa × 10^exponent）。
  ///
  /// - 左方為 NumberNode：提升為 mantissa，建立空 exponent，游標進 exponent。
  /// - 空位置：建立空 mantissa 與 exponent，游標進 mantissa。
  TreeExpressionDocument insertScientific(TreeExpressionDocument document) {
    final index = TreeIndex(document.root);
    final cursor = index.clampCursor(document.cursor);
    final sequence = index.findSequence(cursor.sequenceId);
    if (sequence == null) {
      return document;
    }

    final offset = _gapOffset(cursor, sequence);

    if (offset > 0 && sequence.children[offset - 1] is NumberNode) {
      final left = sequence.children[offset - 1] as NumberNode;
      final node = ScientificNode(
        id: NodeId.generate(),
        mantissa: SequenceNode(id: NodeId.generate(), children: [left]),
        exponent: SequenceNode.empty(),
      );
      final newSequence = sequence
          .removeAt(offset - 1)
          .insert(offset - 1, node);
      return _commit(
        index,
        document,
        newSequence,
        CursorPosition(sequenceId: node.exponent.id, nodeOffset: 0),
      );
    }

    final node = ScientificNode.empty();
    final newSequence = sequence.insert(offset, node);
    return _commit(
      index,
      document,
      newSequence,
      CursorPosition(sequenceId: node.mantissa.id, nodeOffset: 0),
    );
  }

  // ---- Backspace ----------------------------------------------------------

  /// 退格。
  ///
  /// 8 條優先規則見計劃。簡述：
  /// 1. NumberNode 內有左方字元 -> 刪一字元。
  /// 2. NumberNode 變空 -> 移除 NumberNode。
  /// 3. gap 前方為簡單 node -> 移除該 node。
  /// 4-8. 空 child sequence 開頭 -> 依 owner 種類降級 / 移除。
  TreeExpressionDocument backspace(TreeExpressionDocument document) {
    final index = TreeIndex(document.root);
    final cursor = index.clampCursor(document.cursor);
    final sequence = index.findSequence(cursor.sequenceId);
    if (sequence == null) {
      return document;
    }

    final textOffset = cursor.textOffset;

    // 規則 1 & 2：NumberNode 內。
    if (textOffset != null) {
      final number = sequence.children[cursor.nodeOffset] as NumberNode;
      if (textOffset > 0) {
        final newValue =
            number.value.substring(0, textOffset - 1) +
            number.value.substring(textOffset);
        if (newValue.isEmpty) {
          // 規則 2：變空，移除 NumberNode。
          return _removeChildAndCommit(
            index,
            document,
            sequence,
            cursor.nodeOffset,
            CursorPosition(
              sequenceId: sequence.id,
              nodeOffset: cursor.nodeOffset,
            ),
          );
        }
        return _replaceAndMove(
          index: index,
          document: document,
          sequence: sequence,
          nodeIndex: cursor.nodeOffset,
          newNode: number.copyWith(value: newValue),
          newCursor: CursorPosition(
            sequenceId: sequence.id,
            nodeOffset: cursor.nodeOffset,
            textOffset: textOffset - 1,
          ),
        );
      }
      // textOffset == 0：降到下方 gap 邏輯（前方無字元可刪）。
    }

    // gap mode：cursor 位於 nodeOffset 前方間隙。
    final offset = textOffset == null
        ? cursor.nodeOffset
        : cursor.nodeOffset; // textOffset==0 時也是 nodeOffset 前方

    // 規則 3：gap 前方為簡單 node -> 移除。
    if (offset > 0) {
      final left = sequence.children[offset - 1];
      if (_isSimpleNode(left)) {
        return _removeChildAndCommit(
          index,
          document,
          sequence,
          offset - 1,
          CursorPosition(sequenceId: sequence.id, nodeOffset: offset - 1),
        );
      }
    }

    // 規則 4-8：在 sequence 開頭（offset == 0）且為空或僅游標 -> 處理 owner。
    if (offset == 0) {
      return _backspaceAtSequenceStart(index, document, cursor, sequence);
    }

    // 例如左方是 composite node 但 cursor 在其後方間隙：視為「移除整個 composite」
    // 較不符合直覺，這裡選擇不動，交由使用者先進入 composite 內刪除。
    return document;
  }

  /// 清空 document，保留為空 root。
  TreeExpressionDocument clear(TreeExpressionDocument document) {
    return TreeExpressionDocument.empty();
  }

  // ---- helpers ------------------------------------------------------------

  /// 將 text-mode cursor 視為 gap offset：text mode 視為在其 NumberNode 前方。
  int _gapOffset(CursorPosition cursor, SequenceNode sequence) {
    return cursor.textOffset == null
        ? cursor.nodeOffset
        : cursor.nodeOffset + 1;
  }

  bool _isSimpleNode(ExpressionNode node) {
    return node is NumberNode || node is OperatorNode || node is ConstantNode;
  }

  /// 編輯當前 text-mode NumberNode：用 [transform] 產生新 value，游標移至
  /// [newTextOffset]。
  TreeExpressionDocument _editCurrentNumber(
    TreeIndex index,
    TreeExpressionDocument document,
    SequenceNode sequence,
    CursorPosition cursor,
    String Function(String value) transform,
    int newTextOffset,
  ) {
    final number = sequence.children[cursor.nodeOffset] as NumberNode;
    final newValue = transform(number.value);
    return _replaceAndMove(
      index: index,
      document: document,
      sequence: sequence,
      nodeIndex: cursor.nodeOffset,
      newNode: number.copyWith(value: newValue),
      newCursor: CursorPosition(
        sequenceId: sequence.id,
        nodeOffset: cursor.nodeOffset,
        textOffset: newTextOffset,
      ),
    );
  }

  /// 取代 sequence 中 [nodeIndex] 的 child 為 [newNode]，並將游標設為
  /// [newCursor]。
  TreeExpressionDocument _replaceAndMove({
    required TreeIndex index,
    required TreeExpressionDocument document,
    required SequenceNode sequence,
    required int nodeIndex,
    required ExpressionNode newNode,
    required CursorPosition newCursor,
  }) {
    final newSequence = sequence.replaceAt(nodeIndex, newNode);
    return _commit(index, document, newSequence, newCursor);
  }

  /// 將 [newSequence] 寫回 Tree（沿 parent path 重建）並回傳新 document。
  TreeExpressionDocument _commit(
    TreeIndex index,
    TreeExpressionDocument document,
    SequenceNode newSequence,
    CursorPosition newCursor,
  ) {
    const rewriter = TreeRewriter();
    final newRoot = rewriter.replaceSequence(
      index,
      document.cursor.sequenceId,
      newSequence,
    );
    // 注意：以 document.cursor.sequenceId 為目標，因為 clampCursor 不改
    // sequenceId，而 newSequence 即是該 sequence 的取代。
    return document.copyWith(root: newRoot, cursor: newCursor);
  }

  /// 移除 sequence 中 [childIndex] 的 child 並 commit。
  TreeExpressionDocument _removeChildAndCommit(
    TreeIndex index,
    TreeExpressionDocument document,
    SequenceNode sequence,
    int childIndex,
    CursorPosition newCursor,
  ) {
    final newSequence = sequence.removeAt(childIndex);
    return _commit(index, document, newSequence, newCursor);
  }

  /// 規則 4-8：在 child sequence 開頭按 backspace，處理 owner node。
  TreeExpressionDocument _backspaceAtSequenceStart(
    TreeIndex index,
    TreeExpressionDocument document,
    CursorPosition cursor,
    SequenceNode sequence,
  ) {
    final location = index.findParentOfSequence(sequence.id);
    if (location == null) {
      // root sequence 開頭無法 backspace。
      return document;
    }

    final owner = location.ownerNode;
    final ownerIndex = location.ownerIndex;
    final parentSequence = location.parentSequence!;
    final role = location.role;

    // 規則 8：exponent 空白開頭 -> 解除 PowerNode，保留 base。
    if (owner is PowerNode && role == SequenceRole.powerExponent) {
      final unwrapped = _unwrapPowerKeepBase(
        index,
        document,
        owner,
        ownerIndex,
        parentSequence,
      );
      if (unwrapped != null) {
        return unwrapped;
      }
    }

    // 規則：ScientificNode exponent 空白開頭 -> 解除保留 mantissa。
    if (owner is ScientificNode &&
        role == SequenceRole.scientificExponent) {
      final unwrapped = _unwrapScientificKeepMantissa(
        index,
        document,
        owner,
        ownerIndex,
        parentSequence,
      );
      if (unwrapped != null) {
        return unwrapped;
      }
    }

    // 規則：MixedFractionNode 空白開頭依角色降級。
    if (owner is MixedFractionNode) {
      final downgraded = _downgradeMixedFraction(
        index,
        document,
        owner,
        ownerIndex,
        parentSequence,
        role,
      );
      if (downgraded != null) {
        return downgraded;
      }
    }

    // 規則：LogarithmNode argument 空 -> 移除整個 node；base 空 -> 退到 argument。
    if (owner is LogarithmNode) {
      if (role == SequenceRole.logArgument) {
        return _removeOwnerAndCommit(
          index,
          document,
          parentSequence,
          ownerIndex,
          CursorPosition(
            sequenceId: parentSequence.id,
            nodeOffset: ownerIndex,
          ),
        );
      }
      if (role == SequenceRole.logBase) {
        return document.copyWith(
          cursor: CursorPosition(
            sequenceId: owner.argument.id,
            nodeOffset: 0,
          ),
        );
      }
    }

    // 規則 6：function argument 空 -> 移除 FunctionNode，回到 parent 前方。
    if (owner is FunctionNode) {
      return _removeOwnerAndCommit(
        index,
        document,
        parentSequence,
        ownerIndex,
        CursorPosition(sequenceId: parentSequence.id, nodeOffset: ownerIndex),
      );
    }

    // 規則 7：root radicand 空 -> 移除 RootNode，回到 parent 前方。
    if (owner is RootNode) {
      // 若是 nth root 且 cursor 在 degree，先不特殊處理（degree 視為一般）；
      // radicand 空才移除整個 RootNode。
      if (role == SequenceRole.rootRadicand) {
        return _removeOwnerAndCommit(
          index,
          document,
          parentSequence,
          ownerIndex,
          CursorPosition(sequenceId: parentSequence.id, nodeOffset: ownerIndex),
        );
      }
    }

    // 規則 5：fraction denominator 空 -> 回到 numerator 末端。
    if (owner is FractionNode && role == SequenceRole.fractionDenominator) {
      return document.copyWith(
        cursor: CursorPosition(
          sequenceId: owner.numerator.id,
          nodeOffset: owner.numerator.children.length,
        ),
      );
    }

    // 規則 4：其他空 child sequence -> unwrap owner（若 owner 僅一個 child
    // sequence 且為空，直接移除 owner）。
    return _removeOwnerAndCommit(
      index,
      document,
      parentSequence,
      ownerIndex,
      CursorPosition(sequenceId: parentSequence.id, nodeOffset: ownerIndex),
    );
  }

  /// 解除 PowerNode：若 base 非空且只有單一 NumberNode，將該 NumberNode 放回
  /// parent sequence 原 owner 位置；否則回傳 null 由呼叫端走 fallback。
  TreeExpressionDocument? _unwrapPowerKeepBase(
    TreeIndex index,
    TreeExpressionDocument document,
    PowerNode owner,
    int ownerIndex,
    SequenceNode parentSequence,
  ) {
    if (owner.base.children.length == 1 &&
        owner.base.children.first is NumberNode) {
      final base = owner.base.children.first as NumberNode;
      final newSequence = parentSequence.replaceAt(ownerIndex, base);
      // 注意：此處操作 parent sequence（不是 cursor 所在的 exponent），
      // 不能用 _commit（它以 cursor.sequenceId 為目標），需直接呼叫 rewriter。
      const rewriter = TreeRewriter();
      final newRoot = rewriter.replaceSequence(
        index,
        parentSequence.id,
        newSequence,
      );
      return document.copyWith(
        root: newRoot,
        cursor: CursorPosition(
          sequenceId: parentSequence.id,
          nodeOffset: ownerIndex + 1,
        ),
      );
    }
    return null;
  }

  /// 解除 ScientificNode：若 mantissa 非空且只有單一 NumberNode，將該
  /// NumberNode 放回 parent sequence 原 owner 位置；否則回傳 null 走 fallback。
  TreeExpressionDocument? _unwrapScientificKeepMantissa(
    TreeIndex index,
    TreeExpressionDocument document,
    ScientificNode owner,
    int ownerIndex,
    SequenceNode parentSequence,
  ) {
    if (owner.mantissa.children.length == 1 &&
        owner.mantissa.children.first is NumberNode) {
      final mantissa = owner.mantissa.children.first as NumberNode;
      final newSequence = parentSequence.replaceAt(ownerIndex, mantissa);
      const rewriter = TreeRewriter();
      final newRoot = rewriter.replaceSequence(
        index,
        parentSequence.id,
        newSequence,
      );
      return document.copyWith(
        root: newRoot,
        cursor: CursorPosition(
          sequenceId: parentSequence.id,
          nodeOffset: ownerIndex + 1,
        ),
      );
    }
    return null;
  }

  /// 帶分數降級：denominator 空 -> 退到 numerator 末端；numerator 空 -> 退到
  /// whole 末端；whole 空 -> 移除整個 node。回傳 `null` 表示不適用（例如
  /// 各 sequence 非空），由呼叫端走 fallback。
  TreeExpressionDocument? _downgradeMixedFraction(
    TreeIndex index,
    TreeExpressionDocument document,
    MixedFractionNode owner,
    int ownerIndex,
    SequenceNode parentSequence,
    SequenceRole role,
  ) {
    if (role == SequenceRole.mixedDenominator) {
      return document.copyWith(
        cursor: CursorPosition(
          sequenceId: owner.numerator.id,
          nodeOffset: owner.numerator.children.length,
        ),
      );
    }
    if (role == SequenceRole.mixedNumerator) {
      return document.copyWith(
        cursor: CursorPosition(
          sequenceId: owner.whole.id,
          nodeOffset: owner.whole.children.length,
        ),
      );
    }
    // whole 空白開頭 -> 移除整個 node。
    if (role == SequenceRole.mixedWhole) {
      return _removeOwnerAndCommit(
        index,
        document,
        parentSequence,
        ownerIndex,
        CursorPosition(
          sequenceId: parentSequence.id,
          nodeOffset: ownerIndex,
        ),
      );
    }
    return null;
  }
  TreeExpressionDocument _removeOwnerAndCommit(
    TreeIndex index,
    TreeExpressionDocument document,
    SequenceNode parentSequence,
    int ownerIndex,
    CursorPosition newCursor,
  ) {
    final newSequence = parentSequence.removeAt(ownerIndex);
    const rewriter = TreeRewriter();
    final newRoot = rewriter.replaceSequence(
      index,
      parentSequence.id,
      newSequence,
    );
    return document.copyWith(root: newRoot, cursor: newCursor);
  }
}
