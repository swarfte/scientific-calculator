import '../expression_node.dart';
import '../node_id.dart';

enum ExpressionOperator { add, subtract, multiply, divide }

final class OperatorNode extends ExpressionNode {
  const OperatorNode({required super.id, required this.operator});

  factory OperatorNode.create(ExpressionOperator operator) {
    return OperatorNode(id: NodeId.generate(), operator: operator);
  }

  final ExpressionOperator operator;

  OperatorNode copyWith({NodeId? id, ExpressionOperator? operator}) {
    return OperatorNode(id: id ?? this.id, operator: operator ?? this.operator);
  }
}
