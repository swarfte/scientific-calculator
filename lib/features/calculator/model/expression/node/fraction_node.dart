import '../expression_node.dart';
import '../node_id.dart';
import 'sequence_node.dart';

final class FractionNode extends ExpressionNode {
  const FractionNode({
    required super.id,
    required this.numerator,
    required this.denominator,
  });

  factory FractionNode.empty() {
    return FractionNode(
      id: NodeId.generate(),
      numerator: SequenceNode.empty(),
      denominator: SequenceNode.empty(),
    );
  }

  final SequenceNode numerator;
  final SequenceNode denominator;

  FractionNode copyWith({
    NodeId? id,
    SequenceNode? numerator,
    SequenceNode? denominator,
  }) {
    return FractionNode(
      id: id ?? this.id,
      numerator: numerator ?? this.numerator,
      denominator: denominator ?? this.denominator,
    );
  }
}
