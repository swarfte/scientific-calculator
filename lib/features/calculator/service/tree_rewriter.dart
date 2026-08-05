import '../model/expression/expression_node.dart';
import '../model/expression/node/constant_node.dart';
import '../model/expression/node/fraction_node.dart';
import '../model/expression/node/function_node.dart';
import '../model/expression/node/group_node.dart';
import '../model/expression/node/number_node.dart';
import '../model/expression/node/operator_node.dart';
import '../model/expression/node/power_node.dart';
import '../model/expression/node/root_node.dart';
import '../model/expression/node/sequence_node.dart';
import '../model/expression/node_id.dart';
import '../model/expression/sequence_role.dart';
import '../model/expression/tree_index.dart';

/// Immutable Expression Tree 更新工具。
///
/// Editor 不直接手工重建深層 Tree，而是透過 [TreeRewriter] 的三個基本操作
/// 完成不可變更新。所有操作都會沿 parent path 向上重建，並保留未動 node 的
/// [NodeId]（Phase 1 的 copyWith invariant）。
///
/// 呼叫端需提供對應的 [TreeIndex]（已對 root 建好查詢）。
class TreeRewriter {
  const TreeRewriter();

  /// 以 [replacement] 取代 root 樹中 ID 為 [sequenceId] 的 sequence，並沿
  /// parent path 向上重建。
  ///
  /// 回傳新的 root [SequenceNode]；若找不到目標 sequence 則回傳原 root。
  SequenceNode replaceSequence(
    TreeIndex index,
    NodeId sequenceId,
    SequenceNode replacement,
  ) {
    // 目標就是 root：直接回傳 replacement。
    if (sequenceId == index.rootId) {
      return replacement;
    }

    final location = index.findParentOfSequence(sequenceId);
    if (location == null) {
      return index.root;
    }

    // 由 owner node 往上重建：先把 owner 的對應 child sequence 換成
    // replacement，得到新的 owner，再將新的 owner 放回 parent sequence，
    // 如此一直到 root。
    var currentOwner = _withSequence(
      location.ownerNode,
      location.role,
      replacement,
    );
    var currentParent = location.parentSequence;
    var currentOwnerIndex = location.ownerIndex;

    while (currentParent != null) {
      final updatedParent = currentParent.replaceAt(
        currentOwnerIndex,
        currentOwner,
      );

      final parentLocation = index.findParentOfSequence(currentParent.id);
      if (parentLocation == null) {
        // currentParent 是 root。
        return updatedParent;
      }

      currentOwner = _withSequence(
        parentLocation.ownerNode,
        parentLocation.role,
        updatedParent,
      );
      currentParent = parentLocation.parentSequence;
      currentOwnerIndex = parentLocation.ownerIndex;
    }

    // currentOwner 此時已是重建後的 root。
    return currentOwner is SequenceNode ? currentOwner : index.root;
  }

  /// 以 [replacement] 取代 root 樹中 ID 為 [nodeId] 的 node。
  ///
  /// 若該 node 是某個 sequence 的 child，會在 parent sequence 中取代並向上
  /// 重建。回傳新的 root；找不到時回傳原 root。
  SequenceNode replaceNode(
    TreeIndex index,
    NodeId nodeId,
    ExpressionNode replacement,
  ) {
    // node 本身是 sequence：走 sequence 路徑。
    if (index.findSequence(nodeId) != null && replacement is SequenceNode) {
      return replaceSequence(index, nodeId, replacement);
    }

    final location = index.findParentOfNode(nodeId);
    if (location == null) {
      return index.root;
    }

    final updatedParent = location.parentSequence.replaceAt(
      location.index,
      replacement,
    );
    return replaceSequence(index, location.parentSequence.id, updatedParent);
  }

  /// 從 root 樹中移除 ID 為 [nodeId] 的 node。
  ///
  /// 回傳新的 root；找不到或該 node 為 root 時回傳原 root。
  SequenceNode removeNode(TreeIndex index, NodeId nodeId) {
    final location = index.findParentOfNode(nodeId);
    if (location == null) {
      return index.root;
    }

    final updatedParent = location.parentSequence.removeAt(location.index);
    return replaceSequence(index, location.parentSequence.id, updatedParent);
  }

  /// 回傳某個 composite node 將其 [role] 對應的 child sequence 換成
  /// [replacement] 後的新 node（保留原 ID）。
  ExpressionNode _withSequence(
    ExpressionNode owner,
    SequenceRole role,
    SequenceNode replacement,
  ) {
    switch (owner) {
      case FunctionNode():
        return owner.copyWith(argument: replacement);
      case GroupNode():
        return owner.copyWith(content: replacement);
      case FractionNode():
        return switch (role) {
          SequenceRole.fractionNumerator => owner.copyWith(
            numerator: replacement,
          ),
          SequenceRole.fractionDenominator => owner.copyWith(
            denominator: replacement,
          ),
          _ => owner,
        };
      case RootNode():
        return switch (role) {
          SequenceRole.rootRadicand => owner.copyWith(radicand: replacement),
          SequenceRole.rootDegree => owner.copyWith(degree: replacement),
          _ => owner,
        };
      case PowerNode():
        return switch (role) {
          SequenceRole.powerBase => owner.copyWith(base: replacement),
          SequenceRole.powerExponent => owner.copyWith(exponent: replacement),
          _ => owner,
        };
      case NumberNode():
      case OperatorNode():
      case ConstantNode():
      case SequenceNode():
        // leaf node / sequence 沒有 child sequence，不應抵達此處。
        return owner;
      default:
        return owner;
    }
  }
}
