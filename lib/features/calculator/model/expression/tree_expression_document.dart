import 'cursor_position.dart';
import 'node/sequence_node.dart';

/// 重構過渡期的 Expression Tree document。
///
/// 唯一算式資料來源：一份結構化的 [SequenceNode]（root）以及一個
/// [CursorPosition]。Phase 2 階段刻意不保存 evaluation/TeX string，
/// 顯示、驗證與計算均由 Tree 推導。
///
/// 待 Phase 6 正式切換後，此型別會取代舊的 [ExpressionDocument]
/// 並改名為正式的 `ExpressionDocument`。
class TreeExpressionDocument {
  const TreeExpressionDocument({required this.root, required this.cursor});

  /// 算式的水平輸入根節點。
  final SequenceNode root;

  /// 游標目前在 Tree 中的位置。請參考 [CursorPosition] 的 cursor 慣例。
  final CursorPosition cursor;

  /// 建立一份空的 document：root 為空 [SequenceNode]，cursor 位於 root 結尾。
  factory TreeExpressionDocument.empty() {
    final root = SequenceNode.empty();
    return TreeExpressionDocument(
      root: root,
      cursor: CursorPosition(sequenceId: root.id, nodeOffset: 0),
    );
  }

  TreeExpressionDocument copyWith({
    SequenceNode? root,
    CursorPosition? cursor,
  }) {
    return TreeExpressionDocument(
      root: root ?? this.root,
      cursor: cursor ?? this.cursor,
    );
  }
}
