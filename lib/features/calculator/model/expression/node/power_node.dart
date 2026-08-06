import '../expression_node.dart';
import '../node_id.dart';
import 'sequence_node.dart';

final class PowerNode extends ExpressionNode {
  const PowerNode({
    required super.id,
    required this.base,
    required this.exponent,
  });

  factory PowerNode.empty() {
    return PowerNode(
      id: NodeId.generate(),
      base: SequenceNode.empty(),
      exponent: SequenceNode.empty(),
    );
  }

  final SequenceNode base;
  final SequenceNode exponent;

  PowerNode copyWith({NodeId? id, SequenceNode? base, SequenceNode? exponent}) {
    return PowerNode(
      id: id ?? this.id,
      base: base ?? this.base,
      exponent: exponent ?? this.exponent,
    );
  }
}
