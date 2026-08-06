import '../expression_node.dart';
import '../node_id.dart';
import 'sequence_node.dart';

final class RootNode extends ExpressionNode {
  const RootNode({required super.id, required this.radicand, this.degree});

  factory RootNode.squareRoot() {
    return RootNode(id: NodeId.generate(), radicand: SequenceNode.empty());
  }

  factory RootNode.nthRoot() {
    return RootNode(
      id: NodeId.generate(),
      radicand: SequenceNode.empty(),
      degree: SequenceNode.empty(),
    );
  }

  final SequenceNode radicand;
  final SequenceNode? degree;

  bool get isSquareRoot => degree == null;

  RootNode copyWith({
    NodeId? id,
    SequenceNode? radicand,
    SequenceNode? degree,
    bool removeDegree = false,
  }) {
    return RootNode(
      id: id ?? this.id,
      radicand: radicand ?? this.radicand,
      degree: removeDegree ? null : degree ?? this.degree,
    );
  }
}
