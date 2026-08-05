import 'node_id.dart';

abstract class ExpressionNode {
  const ExpressionNode({required this.id});

  final NodeId id;
}
