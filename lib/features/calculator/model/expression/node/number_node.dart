import '../expression_node.dart';
import '../node_id.dart';

final class NumberNode extends ExpressionNode {
  const NumberNode({required super.id, required this.value});

  factory NumberNode.create(String value) {
    return NumberNode(id: NodeId.generate(), value: value);
  }

  final String value;

  bool get isComplete {
    return value.isNotEmpty && value != '.';
  }

  NumberNode copyWith({NodeId? id, String? value}) {
    return NumberNode(id: id ?? this.id, value: value ?? this.value);
  }
}
