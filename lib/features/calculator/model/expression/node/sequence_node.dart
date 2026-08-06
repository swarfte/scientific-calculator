import '../expression_node.dart';
import '../node_id.dart';

final class SequenceNode extends ExpressionNode {
  SequenceNode({required super.id, required List<ExpressionNode> children})
    : children = List.unmodifiable(children);

  factory SequenceNode.empty({NodeId? id}) {
    return SequenceNode(id: id ?? NodeId.generate(), children: const []);
  }

  final List<ExpressionNode> children;

  bool get isEmpty => children.isEmpty;

  SequenceNode copyWith({NodeId? id, List<ExpressionNode>? children}) {
    return SequenceNode(id: id ?? this.id, children: children ?? this.children);
  }

  SequenceNode insert(int index, ExpressionNode node) {
    final updatedChildren = [
      ...children.take(index),
      node,
      ...children.skip(index),
    ];

    return copyWith(children: updatedChildren);
  }

  SequenceNode replaceAt(int index, ExpressionNode node) {
    final updatedChildren = [...children];
    updatedChildren[index] = node;

    return copyWith(children: updatedChildren);
  }

  SequenceNode removeAt(int index) {
    final updatedChildren = [...children]..removeAt(index);

    return copyWith(children: updatedChildren);
  }
}
