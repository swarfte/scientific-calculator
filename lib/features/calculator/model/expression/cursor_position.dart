import 'node_id.dart';

final class CursorPosition {
  const CursorPosition({
    required this.sequenceId,
    required this.nodeOffset,
    this.textOffset,
  });

  final NodeId sequenceId;

  /// 游標位於 child index 前。
  ///
  /// 0 表示第一個 child 前面。
  /// children.length 表示最後一個 child 後面。
  final int nodeOffset;

  /// 當游標進入 NumberNode 時使用。
  ///
  /// null 表示游標位於 nodes 之間。
  final int? textOffset;

  bool get isInsideText => textOffset != null;

  @override
  bool operator ==(Object other) {
    return other is CursorPosition &&
        other.sequenceId == sequenceId &&
        other.nodeOffset == nodeOffset &&
        other.textOffset == textOffset;
  }

  @override
  int get hashCode => Object.hash(sequenceId, nodeOffset, textOffset);

  CursorPosition copyWith({
    NodeId? sequenceId,
    int? nodeOffset,
    int? textOffset,
    bool clearTextOffset = false,
  }) {
    return CursorPosition(
      sequenceId: sequenceId ?? this.sequenceId,
      nodeOffset: nodeOffset ?? this.nodeOffset,
      textOffset: clearTextOffset ? null : textOffset ?? this.textOffset,
    );
  }
}
