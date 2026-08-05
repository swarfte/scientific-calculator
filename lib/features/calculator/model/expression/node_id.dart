final class NodeId {
  const NodeId(this.value);

  final String value;

  static int _nextValue = 0;

  factory NodeId.generate() {
    final value = _nextValue++;
    return NodeId('node_$value');
  }

  @override
  bool operator ==(Object other) {
    return other is NodeId && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
