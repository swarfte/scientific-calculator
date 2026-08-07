import '../model/expression/cursor_position.dart';
import '../model/expression/expression_node.dart';
import '../model/expression/node/number_node.dart';
import '../model/expression/node/sequence_node.dart';
import '../model/expression/node_id.dart';
import '../model/expression/sequence_role.dart';
import '../model/expression/tree_expression_document.dart';
import '../model/expression/tree_index.dart';

/// Expression Tree 的結構化導航。
///
/// 只移動 [TreeExpressionDocument.cursor]，不修改 Tree 內容。
/// 每次呼叫會針對當前 root 建立一次 [TreeIndex] 作為唯讀查詢依據。
///
/// ## Cursor 慣例
///
/// [CursorPosition] 有兩種模式：
///
/// * **Gap mode**（`textOffset == null`）：`nodeOffset ∈ [0, len]` 表示游標位於
///   `sequence.children[nodeOffset]` 前方的間隙。`0` = sequence 開頭，
///   `len` = sequence 結尾。
/// * **Text mode**（`textOffset != null`）：游標位於 NumberNode
///   `sequence.children[nodeOffset]` 內，字元位置 `textOffset ∈ [0, value.length]`。
///
/// 遇到無效 cursor（例如 sequenceId 已不存在）時，會安全回復至 root 結尾。
class ExpressionNavigator {
  const ExpressionNavigator();

  TreeExpressionDocument moveLeft(TreeExpressionDocument document) {
    final index = TreeIndex(document.root);
    final cursor = index.clampCursor(document.cursor);
    return document.copyWith(cursor: _moveLeft(index, cursor));
  }

  TreeExpressionDocument moveRight(TreeExpressionDocument document) {
    final index = TreeIndex(document.root);
    final cursor = index.clampCursor(document.cursor);
    return document.copyWith(cursor: _moveRight(index, cursor));
  }

  TreeExpressionDocument moveUp(TreeExpressionDocument document) {
    final index = TreeIndex(document.root);
    final cursor = index.clampCursor(document.cursor);
    return document.copyWith(cursor: _moveVertical(index, cursor, up: true));
  }

  TreeExpressionDocument moveDown(TreeExpressionDocument document) {
    final index = TreeIndex(document.root);
    final cursor = index.clampCursor(document.cursor);
    return document.copyWith(cursor: _moveVertical(index, cursor, up: false));
  }

  // ---- Left ---------------------------------------------------------------

  CursorPosition _moveLeft(TreeIndex index, CursorPosition cursor) {
    final sequence = index.findSequence(cursor.sequenceId);
    if (sequence == null) {
      return _rootEnd(index);
    }

    // 1. NumberNode 內、仍有左方字元：向左一字元。
    final textOffset = cursor.textOffset;
    if (textOffset != null && textOffset > 0) {
      return cursor.copyWith(textOffset: textOffset - 1);
    }

    // 2. NumberNode 開頭（textOffset == 0）：離開至該 node 前方間隙。
    if (textOffset == 0) {
      // 對稱於 _moveRight 規則 1 的合併：若此 NumberNode 是所在 sequence 的
      // 第一個 child，且該 sequence 是其 owner 的第一個可編輯 child sequence，
      // 則此間隙與 text 開頭視覺完全相同（隱形中間步），直接 _leaveSequenceStart
      // 跳出 owner。
      if (cursor.nodeOffset == 0 &&
          _isFirstEditableSequence(index, cursor.sequenceId)) {
        return _leaveSequenceStart(index, cursor.sequenceId);
      }
      return cursor.copyWith(clearTextOffset: true);
    }

    // 3. 已在 sequence 開頭：離開 owner node 至 parent sequence 前方間隙。
    if (cursor.nodeOffset == 0) {
      return _leaveSequenceStart(index, cursor.sequenceId);
    }

    // 4. 左方有相鄰 node：視種類進入或停在後方間隙。
    final leftNode = sequence.children[cursor.nodeOffset - 1];
    return _enterNodeFromRight(sequence, leftNode, cursor.nodeOffset - 1);
  }

  // ---- Right --------------------------------------------------------------

  CursorPosition _moveRight(TreeIndex index, CursorPosition cursor) {
    final sequence = index.findSequence(cursor.sequenceId);
    if (sequence == null) {
      return _rootEnd(index);
    }

    // 1. NumberNode 內、仍有右方字元：向右一字元。
    if (cursor.textOffset case final textOffset when textOffset != null) {
      final number = sequence.children[cursor.nodeOffset] as NumberNode;
      if (textOffset < number.value.length) {
        return cursor.copyWith(textOffset: textOffset + 1);
      }
      // 末端：離開至 node 後方間隙。
      final gapAfterNumber = CursorPosition(
        sequenceId: cursor.sequenceId,
        nodeOffset: cursor.nodeOffset + 1,
      );
      // 若此間隙位於 sequence 末端，且該 sequence 是其 owner 的最後一個可編輯
      // child sequence（例如 function argument / group content / square root
      // radicand），則此間隙與前一個 text 末端視覺完全相同（TeX 相同），
      // 形成「按一下無變化」的隱形中間步。此時直接執行 _leaveSequenceEnd
      // 把兩步合併，讓單次方向鍵即有可見效果。
      if (gapAfterNumber.nodeOffset >= sequence.children.length &&
          _isLastEditableSequence(index, cursor.sequenceId)) {
        return _leaveSequenceEnd(index, cursor.sequenceId);
      }
      return gapAfterNumber;
    }

    // 2. 已在 sequence 結尾：離開 owner node 至 parent sequence 後方間隙。
    if (cursor.nodeOffset >= sequence.children.length) {
      return _leaveSequenceEnd(index, cursor.sequenceId);
    }

    // 3. 右方有相鄰 node：視種類進入或停在前方間隙。
    final rightNode = sequence.children[cursor.nodeOffset];
    return _enterNodeFromLeft(sequence, rightNode, cursor.nodeOffset);
  }

  // ---- Up / Down ----------------------------------------------------------

  CursorPosition _moveVertical(
    TreeIndex index,
    CursorPosition cursor, {
    required bool up,
  }) {
    final location = index.findParentOfSequence(cursor.sequenceId);
    if (location == null) {
      return cursor;
    }

    final SequenceRole? targetRole = switch ((location.role, up)) {
      (SequenceRole.fractionDenominator, true) =>
        SequenceRole.fractionNumerator,
      (SequenceRole.fractionNumerator, false) =>
        SequenceRole.fractionDenominator,
      (SequenceRole.powerBase, true) => SequenceRole.powerExponent,
      (SequenceRole.powerExponent, false) => SequenceRole.powerBase,
      (SequenceRole.rootRadicand, true) => SequenceRole.rootDegree,
      (SequenceRole.rootDegree, false) => SequenceRole.rootRadicand,
      _ => null,
    };

    if (targetRole == null) {
      // 其他位置上下鍵保持不動。
      return cursor;
    }

    final targetSequence = _siblingSequence(location.ownerNode, targetRole);
    if (targetSequence == null) {
      // 例如 square root 沒有 degree，向上無目標。
      return cursor;
    }

    return _transferTo(cursor, targetSequence);
  }

  /// 將 cursor 的水平位置（nodeOffset / textOffset）盡量保留地轉移到 target
  /// sequence，並 clamp 至合法範圍。
  CursorPosition _transferTo(CursorPosition cursor, SequenceNode target) {
    final clampedOffset = cursor.nodeOffset.clamp(0, target.children.length);

    // 若原為 text mode，只有當目標位置也是 NumberNode 時才保留。
    final textOffset = cursor.textOffset;
    if (textOffset == null || clampedOffset >= target.children.length) {
      return CursorPosition(sequenceId: target.id, nodeOffset: clampedOffset);
    }

    final child = target.children[clampedOffset];
    if (child is NumberNode) {
      return CursorPosition(
        sequenceId: target.id,
        nodeOffset: clampedOffset,
        textOffset: textOffset.clamp(0, child.value.length),
      );
    }

    return CursorPosition(sequenceId: target.id, nodeOffset: clampedOffset);
  }

  SequenceNode? _siblingSequence(
    ExpressionNode owner,
    SequenceRole targetRole,
  ) {
    for (final entry in TreeIndex.childSequencesOf(owner)) {
      if (entry.role == targetRole) {
        return entry.sequence;
      }
    }
    return null;
  }

  // ---- Node entry helpers -------------------------------------------------

  /// 游標由左側（從 node 後方）進入一個相鄰 node。
  /// 游標向右移動遇到相鄰 node 時的處理。
  ///
  /// - NumberNode：進入文字開頭（text mode，offset 0）。
  /// - 其他 composite node：進入「第一個」可編輯 child sequence 的開頭。
  /// - 其他 leaf node（Operator / Constant）：跨越至 node 後方間隙。
  CursorPosition _enterNodeFromLeft(
    SequenceNode current,
    ExpressionNode node,
    int nodeIndex,
  ) {
    if (node is NumberNode) {
      // NumberNode：進入文字開頭。
      return CursorPosition(
        sequenceId: current.id,
        nodeOffset: nodeIndex,
        textOffset: 0,
      );
    }

    final children = TreeIndex.childSequencesOf(node);
    if (children.isEmpty) {
      // 其他 leaf node：跨越至後方間隙。
      return CursorPosition(sequenceId: current.id, nodeOffset: nodeIndex + 1);
    }

    // 進入「第一個」可編輯 child sequence 的開頭。
    return CursorPosition(
      sequenceId: children.first.sequence.id,
      nodeOffset: 0,
    );
  }

  /// 游標向左移動遇到相鄰 node 時的處理。
  ///
  /// - NumberNode：進入文字末端（text mode）。
  /// - 其他 composite node：進入「最後一個」可編輯 child sequence 末端。
  /// - 其他 leaf node（Operator / Constant）：跨越至 node 前方間隙。
  CursorPosition _enterNodeFromRight(
    SequenceNode current,
    ExpressionNode node,
    int nodeIndex,
  ) {
    if (node is NumberNode) {
      // NumberNode：進入文字末端。
      return CursorPosition(
        sequenceId: current.id,
        nodeOffset: nodeIndex,
        textOffset: node.value.length,
      );
    }

    final children = TreeIndex.childSequencesOf(node);
    if (children.isEmpty) {
      // 其他 leaf node：跨越至前方間隙。
      return CursorPosition(sequenceId: current.id, nodeOffset: nodeIndex);
    }

    // 進入「最後一個」可編輯 child sequence 的末端。
    final last = children.last.sequence;
    return CursorPosition(
      sequenceId: last.id,
      nodeOffset: last.children.length,
    );
  }

  // ---- Sequence leave helpers ---------------------------------------------

  /// 在 child sequence 開頭繼續向左。
  ///
  /// 先嘗試進入 owner 的「前一個」可編輯 child sequence 末端（例如
  /// denominator -> numerator），沒有前一個時才離開 owner 至 parent
  /// sequence 前方間隙。
  CursorPosition _leaveSequenceStart(TreeIndex index, NodeId sequenceId) {
    final location = index.findParentOfSequence(sequenceId);
    if (location == null) {
      // root sequence 開頭無路可走。
      return CursorPosition(sequenceId: sequenceId, nodeOffset: 0);
    }

    final previous = _previousSiblingSequence(location);
    if (previous != null) {
      return CursorPosition(
        sequenceId: previous.id,
        nodeOffset: previous.children.length,
      );
    }

    return CursorPosition(
      sequenceId: location.parentSequence!.id,
      nodeOffset: location.ownerIndex,
    );
  }

  /// 在 child sequence 末端繼續向右。
  ///
  /// 先嘗試進入 owner 的「下一個」可編輯 child sequence 開頭（例如
  /// numerator -> denominator），沒有下一個時才離開 owner 至 parent
  /// sequence 後方間隙。
  CursorPosition _leaveSequenceEnd(TreeIndex index, NodeId sequenceId) {
    final location = index.findParentOfSequence(sequenceId);
    if (location == null) {
      // root sequence 末端無路可走。
      return CursorPosition(
        sequenceId: sequenceId,
        nodeOffset: index.findSequence(sequenceId)!.children.length,
      );
    }

    final next = _nextSiblingSequence(location);
    if (next != null) {
      return CursorPosition(sequenceId: next.id, nodeOffset: 0);
    }

    return CursorPosition(
      sequenceId: location.parentSequence!.id,
      nodeOffset: location.ownerIndex + 1,
    );
  }

  /// 回傳同一 owner 中，role 順序在 [location] 之前的可編輯 sequence。
  SequenceNode? _previousSiblingSequence(SequenceLocation location) {
    final siblings = TreeIndex.childSequencesOf(location.ownerNode);
    final currentIndex = siblings.indexWhere((e) => e.role == location.role);
    if (currentIndex <= 0) {
      return null;
    }
    return siblings[currentIndex - 1].sequence;
  }

  /// 判斷 [sequenceId] 所指 sequence 是否為其 owner 的「最後一個」可編輯 child
  /// sequence。root sequence（無 owner）回傳 true。
  ///
  /// 用於偵測視覺不可見的導航中間步：當游標位於 sequence 末端時，若沒有下一個
  /// sibling sequence，下一步即離開 owner；此時間隙步與前一步視覺相同，應合併。
  bool _isLastEditableSequence(TreeIndex index, NodeId sequenceId) {
    final location = index.findParentOfSequence(sequenceId);
    if (location == null) {
      return true;
    }
    return _nextSiblingSequence(location) == null;
  }

  /// 判斷 [sequenceId] 所指 sequence 是否為其 owner 的「第一個」可編輯 child
  /// sequence。root sequence（無 owner）回傳 true。
  ///
  /// `_isLastEditableSequence` 的對稱版本，用於向左方向的隱形中間步偵測。
  bool _isFirstEditableSequence(TreeIndex index, NodeId sequenceId) {
    final location = index.findParentOfSequence(sequenceId);
    if (location == null) {
      return true;
    }
    return _previousSiblingSequence(location) == null;
  }

  /// 回傳同一 owner 中，role 順序在 [location] 之後的可編輯 sequence。
  SequenceNode? _nextSiblingSequence(SequenceLocation location) {
    final siblings = TreeIndex.childSequencesOf(location.ownerNode);
    final currentIndex = siblings.indexWhere((e) => e.role == location.role);
    if (currentIndex < 0 || currentIndex == siblings.length - 1) {
      return null;
    }
    return siblings[currentIndex + 1].sequence;
  }

  CursorPosition _rootEnd(TreeIndex index) {
    return CursorPosition(
      sequenceId: index.rootId,
      nodeOffset: index.root.children.length,
    );
  }
}
