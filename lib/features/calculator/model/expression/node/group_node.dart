import '../expression_node.dart';
import '../node_id.dart';
import 'sequence_node.dart';

final class GroupNode extends ExpressionNode {
  const GroupNode({required super.id, required this.content});

  factory GroupNode.empty() {
    return GroupNode(id: NodeId.generate(), content: SequenceNode.empty());
  }

  final SequenceNode content;

  GroupNode copyWith({NodeId? id, SequenceNode? content}) {
    return GroupNode(id: id ?? this.id, content: content ?? this.content);
  }
}
