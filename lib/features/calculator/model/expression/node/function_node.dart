import '../expression_node.dart';
import '../node_id.dart';
import 'sequence_node.dart';

enum MathFunction { sin, cos, tan, asin, acos, atan, log10, ln, absolute }

final class FunctionNode extends ExpressionNode {
  const FunctionNode({
    required super.id,
    required this.function,
    required this.argument,
  });

  factory FunctionNode.create(MathFunction function) {
    return FunctionNode(
      id: NodeId.generate(),
      function: function,
      argument: SequenceNode.empty(),
    );
  }

  final MathFunction function;
  final SequenceNode argument;

  FunctionNode copyWith({
    NodeId? id,
    MathFunction? function,
    SequenceNode? argument,
  }) {
    return FunctionNode(
      id: id ?? this.id,
      function: function ?? this.function,
      argument: argument ?? this.argument,
    );
  }
}
