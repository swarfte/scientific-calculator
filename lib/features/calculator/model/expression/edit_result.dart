import 'tree_expression_document.dart';

/// 編輯操作的結果。
///
/// Phase 4 的 [TreeExpressionEditor] 方法為了簡化 API 直接回傳
/// [TreeExpressionDocument]，但此型別保留作為 Phase 6 ViewModel 的提示
/// 通道（例如「此處不能輸入運算子」），避免日後改動 editor 的回傳簽名。
class EditResult {
  const EditResult({required this.document, this.message});

  /// 編輯後的新 document（immutable）。
  final TreeExpressionDocument document;

  /// 選擇性的提示訊息；`null` 表示無訊息。
  final String? message;

  bool get hasMessage => message != null;
}
