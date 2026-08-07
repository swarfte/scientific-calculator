import '../expression_node.dart';
import '../node_id.dart';
import 'sequence_node.dart';

/// 科學記號 `mantissa × 10^exponent`，供 `Exp` 鍵使用。
///
/// 輸入顯示為 `mantissa E exponent`（例如 `1E4` 代表 10000）；計算時等同
/// `mantissa × 10^exponent`。
final class ScientificNode extends ExpressionNode {
  const ScientificNode({
    required super.id,
    required this.mantissa,
    required this.exponent,
  });

  factory ScientificNode.empty() {
    return ScientificNode(
      id: NodeId.generate(),
      mantissa: SequenceNode.empty(),
      exponent: SequenceNode.empty(),
    );
  }

  final SequenceNode mantissa;
  final SequenceNode exponent;

  ScientificNode copyWith({
    NodeId? id,
    SequenceNode? mantissa,
    SequenceNode? exponent,
  }) {
    return ScientificNode(
      id: id ?? this.id,
      mantissa: mantissa ?? this.mantissa,
      exponent: exponent ?? this.exponent,
    );
  }
}
