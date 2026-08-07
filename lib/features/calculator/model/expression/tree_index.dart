import 'expression_node.dart';
import 'cursor_position.dart';
import 'node/constant_node.dart';
import 'node/fraction_node.dart';
import 'node/function_node.dart';
import 'node/group_node.dart';
import 'node/logarithm_node.dart';
import 'node/mixed_fraction_node.dart';
import 'node/number_node.dart';
import 'node/operator_node.dart';
import 'node/power_node.dart';
import 'node/root_node.dart';
import 'node/scientific_node.dart';
import 'node/sequence_node.dart';
import 'node_id.dart';
import 'sequence_role.dart';

/// 一個 [SequenceNode] 在其 owner node 內的位置資訊。
final class SequenceLocation {
  const SequenceLocation({
    required this.ownerNode,
    required this.ownerIndex,
    required this.parentSequence,
    required this.role,
  });

  /// 擁有此 sequence 的 composite node（例如 [FractionNode]）。
  final ExpressionNode ownerNode;

  /// [ownerNode] 在 [parentSequence] 內的 child index。
  final int ownerIndex;

  /// 包含 [ownerNode] 的父 sequence（root sequence 時為 null）。
  final SequenceNode? parentSequence;

  /// 此 sequence 的語義角色。
  final SequenceRole role;
}

/// 一個 [ExpressionNode] 在其父 [SequenceNode] 內的位置資訊。
final class NodeLocation {
  const NodeLocation({required this.parentSequence, required this.index});

  final SequenceNode parentSequence;

  /// 此 node 在 [parentSequence.children] 內的 index。
  final int index;
}

/// 由 root 單次 DFS 建立的查找索引。
///
/// Navigator、Editor 與 Serializer 共用此 index，避免各自反覆遞迴找節點。
/// Index 是唯讀快照，Tree 一旦改變必須重新建立。
class TreeIndex {
  TreeIndex(SequenceNode root) : _rootId = root.id {
    _indexSequence(root, parent: null, ownerIndex: 0, role: null);
  }

  final NodeId _rootId;

  final Map<NodeId, SequenceNode> _sequences = {};
  final Map<NodeId, ExpressionNode> _nodes = {};
  final Map<NodeId, SequenceLocation> _sequenceParents = {};
  final Map<NodeId, NodeLocation> _nodeParents = {};

  NodeId get rootId => _rootId;

  SequenceNode get root => _sequences[_rootId]!;

  /// 回傳此 composite node 的所有可編輯 child sequence，依邏輯順序排列。
  ///
  /// 純 leaf node（Number / Operator / Constant）回傳空 list。
  static List<({SequenceNode sequence, SequenceRole role})> childSequencesOf(
    ExpressionNode node,
  ) {
    switch (node) {
      case FunctionNode():
        return [(sequence: node.argument, role: SequenceRole.functionArgument)];
      case GroupNode():
        return [(sequence: node.content, role: SequenceRole.groupContent)];
      case FractionNode():
        return [
          (sequence: node.numerator, role: SequenceRole.fractionNumerator),
          (sequence: node.denominator, role: SequenceRole.fractionDenominator),
        ];
      case RootNode():
        final children = <(SequenceNode, SequenceRole)>[
          (node.radicand, SequenceRole.rootRadicand),
        ];
        final degree = node.degree;
        if (degree != null) {
          children.insert(0, (degree, SequenceRole.rootDegree));
        }
        return children
            .map((e) => (sequence: e.$1, role: e.$2))
            .toList(growable: false);
      case PowerNode():
        return [
          (sequence: node.base, role: SequenceRole.powerBase),
          (sequence: node.exponent, role: SequenceRole.powerExponent),
        ];
      case LogarithmNode():
        return [
          (sequence: node.base, role: SequenceRole.logBase),
          (sequence: node.argument, role: SequenceRole.logArgument),
        ];
      case MixedFractionNode():
        return [
          (sequence: node.whole, role: SequenceRole.mixedWhole),
          (sequence: node.numerator, role: SequenceRole.mixedNumerator),
          (
            sequence: node.denominator,
            role: SequenceRole.mixedDenominator,
          ),
        ];
      case ScientificNode():
        return [
          (
            sequence: node.mantissa,
            role: SequenceRole.scientificMantissa,
          ),
          (
            sequence: node.exponent,
            role: SequenceRole.scientificExponent,
          ),
        ];
      case NumberNode():
      case OperatorNode():
      case ConstantNode():
      case SequenceNode():
        return const [];
      default:
        return const [];
    }
  }

  SequenceNode? findSequence(NodeId id) => _sequences[id];

  ExpressionNode? findNode(NodeId id) => _nodes[id];

  /// root sequence 沒有 parent，回傳 null。
  SequenceLocation? findParentOfSequence(NodeId sequenceId) =>
      _sequenceParents[sequenceId];

  /// root node（即 root sequence 本身被當作 node 時）沒有 parent。
  NodeLocation? findParentOfNode(NodeId nodeId) => _nodeParents[nodeId];

  /// 判斷 cursor 指向的 position 是否完全合法。
  bool isValidCursor(CursorPosition cursor) {
    final sequence = _sequences[cursor.sequenceId];
    if (sequence == null) {
      return false;
    }

    final len = sequence.children.length;
    if (cursor.nodeOffset < 0 || cursor.nodeOffset > len) {
      return false;
    }

    final textOffset = cursor.textOffset;
    if (textOffset == null) {
      return true;
    }

    // text mode 必須落在 NumberNode 內。
    if (cursor.nodeOffset >= len) {
      return false;
    }
    final child = sequence.children[cursor.nodeOffset];
    if (child is! NumberNode) {
      return false;
    }
    return textOffset >= 0 && textOffset <= child.value.length;
  }

  /// 將 cursor 修正為合法位置。
  ///
  /// - 無效 sequenceId → root 結尾。
  /// - 越界 nodeOffset → clamp 至 [0, len]。
  /// - text mode 指向非 NumberNode 或越界 → 降級為 gap mode。
  CursorPosition clampCursor(CursorPosition cursor) {
    final sequence = _sequences[cursor.sequenceId];
    if (sequence == null) {
      return CursorPosition(
        sequenceId: _rootId,
        nodeOffset: root.children.length,
      );
    }

    final len = sequence.children.length;
    final clampedOffset = cursor.nodeOffset.clamp(0, len);

    final textOffset = cursor.textOffset;
    if (textOffset == null) {
      return cursor.copyWith(nodeOffset: clampedOffset);
    }

    if (clampedOffset >= len) {
      return cursor.copyWith(nodeOffset: clampedOffset, clearTextOffset: true);
    }

    final child = sequence.children[clampedOffset];
    if (child is NumberNode) {
      return cursor.copyWith(
        nodeOffset: clampedOffset,
        textOffset: textOffset.clamp(0, child.value.length),
      );
    }

    return cursor.copyWith(nodeOffset: clampedOffset, clearTextOffset: true);
  }

  void _indexSequence(
    SequenceNode sequence, {
    required SequenceLocation? parent,
    required int ownerIndex,
    required SequenceRole? role,
  }) {
    _sequences[sequence.id] = sequence;
    _nodes[sequence.id] = sequence;
    if (parent != null) {
      _sequenceParents[sequence.id] = parent;
      _nodeParents[sequence.id] = NodeLocation(
        parentSequence: parent.parentSequence!,
        index: ownerIndex,
      );
    }

    for (var i = 0; i < sequence.children.length; i++) {
      final child = sequence.children[i];
      _nodes[child.id] = child;
      _nodeParents[child.id] = NodeLocation(parentSequence: sequence, index: i);

      for (final entry in childSequencesOf(child)) {
        _indexSequence(
          entry.sequence,
          parent: SequenceLocation(
            ownerNode: child,
            ownerIndex: i,
            parentSequence: sequence,
            role: entry.role,
          ),
          ownerIndex: i,
          role: entry.role,
        );
      }
    }
  }
}
