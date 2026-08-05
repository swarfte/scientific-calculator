import '../expression_node.dart';
import '../node_id.dart';

enum MathConstant { pi, e, answer }

final class ConstantNode extends ExpressionNode {
  const ConstantNode({required super.id, required this.constant});

  factory ConstantNode.create(MathConstant constant) {
    return ConstantNode(id: NodeId.generate(), constant: constant);
  }

  final MathConstant constant;

  ConstantNode copyWith({NodeId? id, MathConstant? constant}) {
    return ConstantNode(id: id ?? this.id, constant: constant ?? this.constant);
  }
}
