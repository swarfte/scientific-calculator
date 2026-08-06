import '../../../../core/errors/calculator_exception.dart';
import 'node_id.dart';

/// Expression Tree 驗證失敗的 domain-level 描述。
///
/// Validator 回傳此型別（而非直接 throw），讓 Engine 與未來 UI 能取得
/// 錯誤的型別、訊息與位置（[nodeId] 或 [sequenceId]），以便標示錯誤位置。
class ValidationFailure {
  const ValidationFailure({
    required this.type,
    required this.message,
    this.nodeId,
    this.sequenceId,
  });

  /// 對應的 [CalculatorErrorType]，方便 Engine 統一映射。
  final CalculatorErrorType type;

  /// 使用者可讀的錯誤訊息。
  final String message;

  /// 出錯的 node（例如某個 NumberNode、OperatorNode）。
  final NodeId? nodeId;

  /// 出錯的 sequence（例如空 function argument、空 fraction denominator）。
  final NodeId? sequenceId;

  @override
  String toString() => 'ValidationFailure($type: $message)';
}
