import '../expression_node.dart';
import '../node_id.dart';
import 'sequence_node.dart';

/// 帶分數 `whole + numerator/denominator`，供 `a b/c` 鍵使用。
///
/// 三個欄位皆為可編輯 sequence。`whole`、`numerator`、`denominator` 各自獨立
/// 輸入，計算時等同 `whole + numerator/denominator`。
final class MixedFractionNode extends ExpressionNode {
  const MixedFractionNode({
    required super.id,
    required this.whole,
    required this.numerator,
    required this.denominator,
  });

  factory MixedFractionNode.empty() {
    return MixedFractionNode(
      id: NodeId.generate(),
      whole: SequenceNode.empty(),
      numerator: SequenceNode.empty(),
      denominator: SequenceNode.empty(),
    );
  }

  final SequenceNode whole;
  final SequenceNode numerator;
  final SequenceNode denominator;

  MixedFractionNode copyWith({
    NodeId? id,
    SequenceNode? whole,
    SequenceNode? numerator,
    SequenceNode? denominator,
  }) {
    return MixedFractionNode(
      id: id ?? this.id,
      whole: whole ?? this.whole,
      numerator: numerator ?? this.numerator,
      denominator: denominator ?? this.denominator,
    );
  }
}
