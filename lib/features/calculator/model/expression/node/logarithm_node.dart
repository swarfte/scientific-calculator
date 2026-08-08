import '../expression_node.dart';
import '../node_id.dart';
import 'number_node.dart';
import 'sequence_node.dart';

/// 任意底數的對數 `log_base(argument)`。
///
/// 供 `log_xy` 與 `log₂` 鍵使用。`base` 與 `argument` 均為可編輯 sequence；
/// `log₂` 鍵透過 [withDefaultBase] 預填底數 2。
final class LogarithmNode extends ExpressionNode {
  const LogarithmNode({
    required super.id,
    required this.base,
    required this.argument,
  });

  factory LogarithmNode.empty() {
    return LogarithmNode(
      id: NodeId.generate(),
      base: SequenceNode.empty(),
      argument: SequenceNode.empty(),
    );
  }

  /// 以預填底數 [baseValue] 建立，argument 為空，供 `log₂` 等固定底數鍵。
  factory LogarithmNode.withDefaultBase(int baseValue) {
    return LogarithmNode(
      id: NodeId.generate(),
      base: SequenceNode(
        id: NodeId.generate(),
        children: [NumberNode.create('$baseValue')],
      ),
      argument: SequenceNode.empty(),
    );
  }

  final SequenceNode base;
  final SequenceNode argument;

  LogarithmNode copyWith({
    NodeId? id,
    SequenceNode? base,
    SequenceNode? argument,
  }) {
    return LogarithmNode(
      id: id ?? this.id,
      base: base ?? this.base,
      argument: argument ?? this.argument,
    );
  }
}
