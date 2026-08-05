/// 標記一個 [SequenceNode] 在其 owner node 內的語義角色。
///
/// Navigator 與 Serializer 透過 role 判斷 child sequence 的數學意義，
/// 例如上下鍵應在 [fractionNumerator] 與 [fractionDenominator] 之間移動。
enum SequenceRole {
  /// [FunctionNode.argument]。
  functionArgument,

  /// [GroupNode.content]。
  groupContent,

  /// [FractionNode.numerator]。
  fractionNumerator,

  /// [FractionNode.denominator]。
  fractionDenominator,

  /// [RootNode.radicand]。
  rootRadicand,

  /// [RootNode.degree]（n 次根才會出現）。
  rootDegree,

  /// [PowerNode.base]。
  powerBase,

  /// [PowerNode.exponent]。
  powerExponent,
}
